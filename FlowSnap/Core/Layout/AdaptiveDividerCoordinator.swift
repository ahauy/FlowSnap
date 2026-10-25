import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation
import OSLog

let dividerLogger = Logger(subsystem: "com.flowsnap.app", category: "AdaptiveDividerCoordinator")

/// Coordinates hover detection, cursor changes, and live multi-window resizing
/// along shared collinear edges in the active layout. Conforms to @MainActor.
@MainActor
public final class AdaptiveDividerCoordinator: AdaptiveDividerCoordinating {

    let detector: CollinearEdgeDetecting
    let windowManager: WindowManaging
    let displayManager: DisplayManaging
    let throttler: LiveResizeThrottling
    let preferencesStore: PreferencesStore?
    let accessibilityService: AccessibilityService?
    let windowRegistry: WindowRegistry?
    let overlayManager: AdaptiveDividerOverlayManaging?
    weak var workspaceManager: WorkspaceManager?
    public var activeWorkspaceProvider: (() -> Workspace?)?

    /// Debounce duration for auto-saving custom ratio after mouseUp (defaults to 300 seconds / 5 minutes).
    public var autoSaveDelay: TimeInterval = 300.0
    var ratioAutoSaveTask: Task<Void, Never>?

    var isWorkspaceRestrictionEnabled: Bool {
        workspaceManager != nil || activeWorkspaceProvider != nil
    }

    var currentActiveWorkspace: Workspace? {
        activeWorkspaceProvider?() ?? workspaceManager?.activeWorkspace
    }

    var moveMonitor: Any?
    var downMonitor: Any?
    var dragMonitor: Any?
    var upMonitor: Any?
    var keyMonitor: Any?
    var appActivationObserver: NSObjectProtocol?
    var appTerminationObserver: NSObjectProtocol?
    var workspaceCancellable: AnyCancellable?

    public var frontmostApplicationProvider: (() -> String?)?

    var currentFrontmostBundleID: String? {
        frontmostApplicationProvider?() ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    var isNonWorkspaceAppFrontmost: Bool {
        if NSClassFromString("XCTestCase") != nil && frontmostApplicationProvider == nil {
            return false
        }
        guard let frontmostID = currentFrontmostBundleID?.lowercased() else { return false }
        if frontmostID == Bundle.main.bundleIdentifier?.lowercased() { return false }

        if let activeWorkspace = currentActiveWorkspace {
            let workspaceBundleIDs = Set(activeWorkspace.placements.map { $0.bundleIdentifier.lowercased() })
            return !workspaceBundleIDs.contains(frontmostID)
        }

        if !managedWindows.isEmpty {
            let managedIDs = Set(managedWindows.compactMap { $0.bundleIdentifier?.lowercased() })
            return !managedIDs.contains(frontmostID)
        }

        return false
    }

    /// Cached AXUIElement references captured at mouseDown to eliminate redundant IPC lookups during drag.
    var cachedAXElements: [CGWindowID: AXUIElement] = [:]

    /// Last committed window frames used to skip redundant sub-pixel AX updates during live drag.
    var lastCommittedFrames: [CGWindowID: CGRect] = [:]

    /// Dynamic minimum size limits discovered at runtime when an application
    /// refuses to shrink below its OS minimum size.
    public internal(set) var activeMinSizes: [CGWindowID: CGSize] = [:]

    /// Coalesced high-frequency mouse drag state.
    var pendingDragPoint: CGPoint?
    var isDragScheduled = false

    /// Divider set memoised across hover events when layout is static.
    struct DividerCache {
        let fingerprint: Int
        let container: CGRect
        let gap: CGFloat
        let dividers: [CollinearEdge]
    }

    var dividerCache: DividerCache?

    /// Container display frame locked at mouseDown to prevent display-crossing mid-drag.
    /// Cleared in stop(), endSession(), and cancelResize().
    var dragContainer: CGRect?

    /// Window gap snapshotted at mouseDown — gap is constant for the duration of a drag session.
    /// Avoids a per-event async hop into PreferencesStore on the 120Hz hot-path.
    var dragGap: CGFloat = 0

    /// Primary screen height snapshotted at mouseDown — eliminates per-event DisplayManager queries
    /// inside the AX write loop of applyResizedFrames.
    var dragPrimaryHeight: CGFloat = 0

    public internal(set) var isTracking: Bool = false
    public internal(set) var managedWindows: [ManagedWindow] = []
    public internal(set) var allVisibleWindows: [ManagedWindow] = []
    public internal(set) var activeDivider: CollinearEdge?
    public internal(set) var hoveredDivider: CollinearEdge?
    public internal(set) var activeJunction: CrossJunction?
    public internal(set) var hoveredJunction: CrossJunction?
    public internal(set) var isResizing: Bool = false
    public internal(set) var currentCursor: NSCursor = .arrow
    public internal(set) var initialWindows: [CGWindowID: ManagedWindow] = [:]

    /// Divider set the active drag started from, reused between throttled
    /// re-detections so the overlay still has something honest to draw.
    var dragDividers: [CollinearEdge] = []

    /// Divider set currently drawn by the resting/hover overlay, used to detect
    /// whether a hover event needs a refresh at all.
    var lastPresentedDividers: [CollinearEdge] = []

    /// Container and windows the resting overlay was last drawn for. Divider
    /// geometry alone is not enough: two displays can host identical layouts,
    /// and the overlay must still move to the display under the pointer.
    var lastPresentedContainer: CGRect?
    var lastPresentedWindows: [ManagedWindow] = []

    public init(
        detector: CollinearEdgeDetecting = CollinearEdgeDetector(),
        windowManager: WindowManaging,
        displayManager: DisplayManaging,
        throttler: LiveResizeThrottling = LiveResizeThrottler(fps: 60.0),
        preferencesStore: PreferencesStore? = nil,
        accessibilityService: AccessibilityService? = nil,
        windowRegistry: WindowRegistry? = nil,
        overlayManager: AdaptiveDividerOverlayManaging? = nil,
        workspaceManager: WorkspaceManager? = nil,
        autoSaveDelay: TimeInterval = 300.0
    ) {
        self.detector = detector
        self.windowManager = windowManager
        self.displayManager = displayManager
        self.throttler = throttler
        self.preferencesStore = preferencesStore
        self.accessibilityService = accessibilityService
        self.windowRegistry = windowRegistry
        self.overlayManager = overlayManager
        self.workspaceManager = workspaceManager
        self.autoSaveDelay = autoSaveDelay
    }

    /// Identity of a layout: which windows exist and where they sit.
    static func fingerprint(of windows: [ManagedWindow]) -> Int {
        var hasher = Hasher()
        // Sort so a re-ordering of the registry is not mistaken for a move.
        for window in windows.sorted(by: { $0.id < $1.id }) {
            hasher.combine(window.id)
            hasher.combine(Double(window.frame.minX).bitPattern)
            hasher.combine(Double(window.frame.minY).bitPattern)
            hasher.combine(Double(window.frame.width).bitPattern)
            hasher.combine(Double(window.frame.height).bitPattern)
        }
        return hasher.finalize()
    }

    func cachedDividers(
        for windows: [ManagedWindow],
        container: CGRect,
        gap: CGFloat
    ) -> [CollinearEdge] {
        let fingerprint = Self.fingerprint(of: windows)
        if let cache = dividerCache,
           cache.fingerprint == fingerprint,
           cache.container == container,
           cache.gap == gap {
            return cache.dividers
        }
        let dividers = detector.detectDividers(
            in: windows, containerFrame: container, gap: gap, tolerance: max(gap + 12.0, 16.0)
        )
        dividerCache = DividerCache(
            fingerprint: fingerprint, container: container, gap: gap, dividers: dividers
        )
        return dividers
    }

    // MARK: - Cursor

    func setCursor(_ cursor: NSCursor) {
        currentCursor = cursor
        cursor.set()
    }

    // MARK: - External State Reset

    /// Resets all active divider state and hides resting/drag overlays.
    /// Used when workspaces are switched or migrated across displays.
    public func resetState() {
        dividerCache = nil
        lastPresentedDividers = []
        lastPresentedWindows = []
        lastPresentedContainer = nil
        hoveredDivider = nil
        activeDivider = nil
        hoveredJunction = nil
        activeJunction = nil
        setCursor(.arrow)
        if let panel = overlayManager as? AdaptiveDividerOverlayPanel {
            panel.overlayView.updateState(
                containerFrame: .zero,
                windows: [],
                dividers: [],
                activeDivider: nil,
                activeJunction: nil,
                isDragging: false
            )
        }
        overlayManager?.hide(animated: false)
    }
}
