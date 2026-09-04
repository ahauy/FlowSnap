import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation
import OSLog

private let dividerLogger = Logger(subsystem: "com.flowsnap.app", category: "AdaptiveDividerCoordinator")

/// Coordinates hover detection, cursor changes, and live multi-window resizing
/// along shared collinear edges in the active layout. Conforms to @MainActor.
@MainActor
public final class AdaptiveDividerCoordinator: AdaptiveDividerCoordinating {

    private let detector: CollinearEdgeDetecting
    private let windowManager: WindowManaging
    private let displayManager: DisplayManaging
    private let throttler: LiveResizeThrottling
    private let preferencesStore: PreferencesStore?
    private let accessibilityService: AccessibilityService?
    private let windowRegistry: WindowRegistry?
    private let overlayManager: AdaptiveDividerOverlayManaging?
    private weak var workspaceManager: WorkspaceManager?
    public var activeWorkspaceProvider: (() -> Workspace?)?

    /// Debounce duration for auto-saving custom ratio after mouseUp (defaults to 300 seconds / 5 minutes).
    public var autoSaveDelay: TimeInterval = 300.0
    private var ratioAutoSaveTask: Task<Void, Never>?

    private var isWorkspaceRestrictionEnabled: Bool {
        workspaceManager != nil || activeWorkspaceProvider != nil
    }

    private var currentActiveWorkspace: Workspace? {
        activeWorkspaceProvider?() ?? workspaceManager?.activeWorkspace
    }

    private var moveMonitor: Any?
    private var downMonitor: Any?
    private var dragMonitor: Any?
    private var upMonitor: Any?
    private var keyMonitor: Any?
    private var appActivationObserver: NSObjectProtocol?
    private var appTerminationObserver: NSObjectProtocol?
    private var workspaceCancellable: AnyCancellable?

    public var frontmostApplicationProvider: (() -> String?)?

    private var currentFrontmostBundleID: String? {
        frontmostApplicationProvider?() ?? NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private var isNonWorkspaceAppFrontmost: Bool {
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
    private var cachedAXElements: [CGWindowID: AXUIElement] = [:]

    /// Last committed window frames used to skip redundant sub-pixel AX updates during live drag.
    private var lastCommittedFrames: [CGWindowID: CGRect] = [:]

    /// Dynamic minimum size limits discovered at runtime when an application
    /// refuses to shrink below its OS minimum size.
    public private(set) var activeMinSizes: [CGWindowID: CGSize] = [:]

    /// Coalesced high-frequency mouse drag state.
    private var pendingDragPoint: CGPoint?
    private var isDragScheduled = false

    /// Divider set memoised across hover events when layout is static.
    private struct DividerCache {
        let fingerprint: Int
        let container: CGRect
        let gap: CGFloat
        let dividers: [CollinearEdge]
    }

    private var dividerCache: DividerCache?

    /// Container display frame locked at mouseDown to prevent display-crossing mid-drag.
    /// Cleared in stop(), endSession(), and cancelResize().
    private var dragContainer: CGRect?

    /// Window gap snapshotted at mouseDown — gap is constant for the duration of a drag session.
    /// Avoids a per-event async hop into PreferencesStore on the 120Hz hot-path.
    private var dragGap: CGFloat = 0

    /// Primary screen height snapshotted at mouseDown — eliminates per-event DisplayManager queries
    /// inside the AX write loop of applyResizedFrames.
    private var dragPrimaryHeight: CGFloat = 0

    /// Identity of a layout: which windows exist and where they sit.
    private static func fingerprint(of windows: [ManagedWindow]) -> Int {
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

    private func cachedDividers(
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

    public private(set) var isTracking: Bool = false
    public private(set) var managedWindows: [ManagedWindow] = []
    public private(set) var activeDivider: CollinearEdge?
    public private(set) var hoveredDivider: CollinearEdge?
    public private(set) var activeJunction: CrossJunction?
    public private(set) var hoveredJunction: CrossJunction?
    public private(set) var isResizing: Bool = false
    public private(set) var currentCursor: NSCursor = .arrow

    /// Divider set the active drag started from, reused between throttled
    /// re-detections so the overlay still has something honest to draw.
    private var dragDividers: [CollinearEdge] = []

    /// Divider set currently drawn by the resting/hover overlay, used to detect
    /// whether a hover event needs a refresh at all.
    private var lastPresentedDividers: [CollinearEdge] = []

    /// Container and windows the resting overlay was last drawn for. Divider
    /// geometry alone is not enough: two displays can host identical layouts,
    /// and the overlay must still move to the display under the pointer.
    private var lastPresentedContainer: CGRect?
    private var lastPresentedWindows: [ManagedWindow] = []

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

    // MARK: - Lifecycle

    public func start() {
        guard !isTracking else { return }
        isTracking = true
        dividerLogger.debug("Starting AdaptiveDividerCoordinator global monitors")

        if let overlayPanel = overlayManager as? AdaptiveDividerOverlayPanel {
            overlayPanel.overlayView.onDirectMouseDown = { [weak self] pt, _ in self?.triggerMouseDown(at: pt) }
            overlayPanel.overlayView.onDirectMouseDragged = { [weak self] pt in self?.scheduleDragTask(to: pt) }
            overlayPanel.overlayView.onDirectMouseUp = { [weak self] pt in self?.triggerMouseUp(at: pt) }
            overlayPanel.overlayView.onDirectMouseMoved = { [weak self] pt in self?.triggerMouseMoved(at: pt) }
        }
        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.triggerMouseMoved(at: NSEvent.mouseLocation)
        }
        downMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.triggerMouseDown(at: NSEvent.mouseLocation)
        }
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            self?.scheduleDragTask(to: NSEvent.mouseLocation)
        }
        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.triggerMouseUp(at: NSEvent.mouseLocation)
        }
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return }
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                await self.cancelResize()
            }
        }
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isTracking else { return }
            if self.isNonWorkspaceAppFrontmost {
                self.resetState()
            }
        }
        appTerminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                await self.refreshWindowsIfNeeded()
                if self.managedWindows.count < 2 {
                    self.resetState()
                }
            }
        }
        if let workspaceManager {
            workspaceCancellable = workspaceManager.$activeWorkspace
                .dropFirst()
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self, self.isTracking else { return }
                        self.resetState()
                    }
                }
        }
    }

    private func triggerMouseMoved(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self, self.isTracking else { return }
            if let service = self.accessibilityService, !service.isTrusted { return }
            await self.refreshWindowsIfNeeded()
            await self.handleMouseMoved(to: point)
        }
    }

    private func triggerMouseDown(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self, self.isTracking else { return }
            if let service = self.accessibilityService, !service.isTrusted { return }
            await self.refreshWindowsIfNeeded()
            _ = await self.handleMouseDown(at: point)
        }
    }

    private func triggerMouseUp(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self, self.isTracking else { return }
            if let service = self.accessibilityService, !service.isTrusted { return }
            await self.handleMouseUp(at: point)
        }
    }

    public func stop() {
        guard isTracking else { return }
        dividerLogger.debug("Stopping AdaptiveDividerCoordinator global monitors")
        if let moveMonitor { NSEvent.removeMonitor(moveMonitor); self.moveMonitor = nil }
        if let downMonitor { NSEvent.removeMonitor(downMonitor); self.downMonitor = nil }
        if let dragMonitor { NSEvent.removeMonitor(dragMonitor); self.dragMonitor = nil }
        if let upMonitor { NSEvent.removeMonitor(upMonitor); self.upMonitor = nil }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }
        if let appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appActivationObserver)
            self.appActivationObserver = nil
        }
        if let appTerminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appTerminationObserver)
            self.appTerminationObserver = nil
        }
        workspaceCancellable?.cancel()
        workspaceCancellable = nil
        flushPendingDrag()
        isTracking = false
        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        activeJunction = nil
        hoveredJunction = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        dragGap = 0
        dragPrimaryHeight = 0
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        dividerCache = nil
        lastPresentedDividers = []
        lastPresentedWindows = []
        lastPresentedContainer = nil
        setCursor(.arrow)
        // BUG-07: clear overlay view state so phantom hit-areas cannot survive a restart
        if let panel = overlayManager as? AdaptiveDividerOverlayPanel {
            panel.overlayView.updateState(
                containerFrame: .zero, windows: [], dividers: [],
                activeDivider: nil, activeJunction: nil, isDragging: false
            )
        }
        overlayManager?.hide(animated: false)
    }

    /// Coalesces high-frequency mouse drag events to ensure smooth 120Hz tracking without queuing lag.
    ///
    /// **Work-loop invariant (PERF-01):** `isDragScheduled` stays `true` until the loop has fully
    /// drained all pending points. This guarantees that only ONE `handleMouseDragged` call is
    /// in-flight at any moment, regardless of cursor speed. Incoming events during an AX round-trip
    /// only update `pendingDragPoint` (latest wins); they never spawn a new concurrent task.
    private func scheduleDragTask(to point: CGPoint) {
        pendingDragPoint = point
        guard !isDragScheduled else { return }
        isDragScheduled = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            while let targetPoint = self.pendingDragPoint {
                self.pendingDragPoint = nil
                guard self.isTracking else { break }
                if let service = self.accessibilityService, !service.isTrusted { break }
                await self.handleMouseDragged(to: targetPoint)
            }
            // Only cleared once the queue is fully drained — prevents re-entry during AX await.
            self.isDragScheduled = false
        }
    }

    private func flushPendingDrag() {
        pendingDragPoint = nil
        isDragScheduled = false
    }

    // MARK: - Window Management

    public func updateWindows(_ windows: [ManagedWindow]) {
        self.managedWindows = windows
    }

    private func refreshWindowsIfNeeded() async {
        if isResizing { return }
        guard accessibilityService != nil || windowRegistry != nil else { return }
        if isWorkspaceRestrictionEnabled, let activeWorkspace = currentActiveWorkspace {
            if let service = accessibilityService, !service.isTrusted { return }
            let workspaceBundleIDs = Set(activeWorkspace.placements.map { $0.bundleIdentifier.lowercased() })
            if let service = accessibilityService {
                let visible = service.allVisibleManagedWindows()
                let filtered = visible.filter { window in
                    guard let id = window.bundleIdentifier?.lowercased() else { return false }
                    return workspaceBundleIDs.contains(id)
                }
                if filtered.count >= 2 {
                    self.managedWindows = filtered
                    return
                }
            }
            if let registry = windowRegistry {
                let tracked = await registry.allWindows
                let filtered = tracked.filter { window in
                    guard let id = window.bundleIdentifier?.lowercased() else { return false }
                    return workspaceBundleIDs.contains(id)
                }
                if filtered.count >= 2 {
                    self.managedWindows = filtered
                    return
                }
            }
            self.managedWindows = []
            self.dividerCache = nil
            return
        }

        if let service = accessibilityService, !service.isTrusted { return }
        if let service = accessibilityService {
            let visible = service.allVisibleManagedWindows()
            if visible.count >= 2 {
                self.managedWindows = visible
                return
            }
        }
        if let registry = windowRegistry {
            let tracked = await registry.allWindows
            if tracked.count >= 2 {
                self.managedWindows = tracked
                return
            }
        }
        self.managedWindows = []
        self.dividerCache = nil
    }

    private func resolveContainer(at point: CGPoint) async -> CGRect {
        let display = await displayManager.display(containing: point)
        if let display {
            return display.visibleFrame
        }
        let primary = await displayManager.primaryDisplay
        return primary?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    /// Returns the window gap from PreferencesStore synchronously.
    /// `preferencesStore.windowGap` is a `@MainActor` `@AppStorage` property — no actual async
    /// work occurs; the `async` annotation was a no-op causing spurious context-switches.
    private func resolveGap() -> CGFloat {
        preferencesStore?.windowGap ?? 0
    }

    private func filterWindows(for container: CGRect) -> [ManagedWindow] {
        let sourceWindows = (isResizing && !initialWindows.isEmpty) ? Array(initialWindows.values) : managedWindows
        return sourceWindows.filter { window in
            let intersection = window.frame.intersection(container)
            return !intersection.isNull && intersection.width > 20 && intersection.height > 20
        }
    }

    /// Computes the exact seam coordinate directly from the resized window frames,
    /// ensuring the divider line never detaches or penetrates inside window bounds.
    private func seamCoordinate(
        from resizedFrames: [CGWindowID: CGRect],
        for divider: CollinearEdge,
        gap: CGFloat
    ) -> CGFloat? {
        guard !resizedFrames.isEmpty else { return nil }
        let halfGap = gap / 2.0
        switch divider.orientation {
        case .vertical:
            let leadingMaxX = divider.leadingWindowIDs.compactMap { resizedFrames[$0]?.maxX }.max()
            let trailingMinX = divider.trailingWindowIDs.compactMap { resizedFrames[$0]?.minX }.min()
            if let lMaxX = leadingMaxX, let tMinX = trailingMinX {
                return ((lMaxX + tMinX) / 2.0).rounded()
            } else if let lMaxX = leadingMaxX {
                return (lMaxX + halfGap).rounded()
            } else if let tMinX = trailingMinX {
                return (tMinX - halfGap).rounded()
            }
        case .horizontal:
            let leadingMaxY = divider.leadingWindowIDs.compactMap { resizedFrames[$0]?.maxY }.max()
            let trailingMinY = divider.trailingWindowIDs.compactMap { resizedFrames[$0]?.minY }.min()
            if let lMaxY = leadingMaxY, let tMinY = trailingMinY {
                return ((lMaxY + tMinY) / 2.0).rounded()
            } else if let lMaxY = leadingMaxY {
                return (lMaxY + halfGap).rounded()
            } else if let tMinY = trailingMinY {
                return (tMinY - halfGap).rounded()
            }
        }
        return nil
    }

    /// Translates a pinned divider to a new seam coordinate while preserving hitRect span and limits.
    private func seam(
        byMoving reference: CollinearEdge,
        to coordinate: CGFloat,
        gap: CGFloat
    ) -> CollinearEdge {
        guard coordinate != reference.coordinate else { return reference }

        let captureWidth = max(18.0, gap + 16.0)
        let hitRect: CGRect
        switch reference.orientation {
        case .vertical:
            hitRect = CGRect(
                x: coordinate - captureWidth / 2.0,
                y: reference.span.lowerBound,
                width: captureWidth,
                height: max(1.0, reference.span.upperBound - reference.span.lowerBound)
            )
        case .horizontal:
            hitRect = CGRect(
                x: reference.span.lowerBound,
                y: coordinate - captureWidth / 2.0,
                width: max(1.0, reference.span.upperBound - reference.span.lowerBound),
                height: captureWidth
            )
        }

        return CollinearEdge(
            id: reference.id,
            orientation: reference.orientation,
            coordinate: coordinate,
            span: reference.span,
            hitRect: hitRect,
            leadingWindowIDs: reference.leadingWindowIDs,
            trailingWindowIDs: reference.trailingWindowIDs,
            minCoordinate: reference.minCoordinate,
            maxCoordinate: reference.maxCoordinate
        )
    }

    /// Whether candidate represents the same seam as reference (orientation and adjacent windows).
    private func isSameSeam(_ candidate: CollinearEdge, as reference: CollinearEdge) -> Bool {
        candidate.orientation == reference.orientation
            && Set(candidate.leadingWindowIDs) == Set(reference.leadingWindowIDs)
            && Set(candidate.trailingWindowIDs) == Set(reference.trailingWindowIDs)
    }

    /// Whether two divider sets describe identical geometry.
    private func sameDividerSet(_ lhs: [CollinearEdge], _ rhs: [CollinearEdge]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy {
            $0.orientation == $1.orientation && $0.coordinate == $1.coordinate &&
            $0.span == $1.span && $0.leadingWindowIDs == $1.leadingWindowIDs &&
            $0.trailingWindowIDs == $1.trailingWindowIDs
        }
    }

    /// Returns the divider set with the dragged seam replaced with its updated position.
    private func overlaySet(
        from dividers: [CollinearEdge],
        dragging reference: CollinearEdge,
        to dragged: CollinearEdge
    ) -> [CollinearEdge] {
        var result = dividers.map { candidate in
            isSameSeam(candidate, as: reference) ? dragged : candidate
        }
        if result.contains(where: { isSameSeam($0, as: reference) }) == false {
            result.append(dragged)
        }
        return result
    }

    // MARK: - Hover

    public func handleMouseMoved(to point: CGPoint) async {
        guard !isResizing else { return }


        if let service = accessibilityService, !service.isTrusted {
            if hoveredDivider != nil {
                setCursor(.arrow)
                hoveredDivider = nil
            }
            overlayManager?.hide(animated: false)
            return
        }

        let gap = resolveGap()
        let container = await resolveContainer(at: point)

        // Ensure mouse is on the same display where the workspace windows actually reside
        if isWorkspaceRestrictionEnabled && currentActiveWorkspace != nil && !managedWindows.isEmpty {
            let belongsToWorkspaceScreen = managedWindows.contains { win in
                let intersection = win.frame.intersection(container)
                return !intersection.isNull && intersection.width > 20 && intersection.height > 20
            }
            if !belongsToWorkspaceScreen {
                if hoveredDivider != nil {
                    setCursor(.arrow)
                    hoveredDivider = nil
                }
                overlayManager?.hide(animated: false)
                return
            }
        }

        // Ensure the active frontmost application belongs to the workspace or FlowSnap itself.
        // If the user switched to another app (e.g. Antigravity IDE, Browser, Slack),
        // the workspace is in the background — never draw the divider overlay on top of foreground apps.
        if isNonWorkspaceAppFrontmost {
            if hoveredDivider != nil || hoveredJunction != nil {
                setCursor(.arrow)
                hoveredDivider = nil
                hoveredJunction = nil
            }
            overlayManager?.hide(animated: false)
            return
        }

        let displayWindows = filterWindows(for: container)
        guard displayWindows.count >= 2 else {
            if hoveredDivider != nil || hoveredJunction != nil {
                setCursor(.arrow)
                hoveredDivider = nil
                hoveredJunction = nil
            }
            if !lastPresentedDividers.isEmpty || !lastPresentedWindows.isEmpty {
                lastPresentedDividers = []
                lastPresentedWindows = []
                lastPresentedContainer = nil
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
            }
            overlayManager?.hide(animated: false)
            return
        }
        let dividers = cachedDividers(for: displayWindows, container: container, gap: gap)
        let junctions = detector.detectJunctions(in: dividers, tolerance: max(gap + 12.0, 16.0))
        let hoveredJunc = detector.hitTestJunction(at: point, in: junctions)
        let hovered = hoveredJunc != nil ? nil : detector.hitTestDivider(at: point, in: dividers)

        // Nothing on screen changes unless the seam set or the hovered seam/junction
        // changed, so skip the overlay refresh when they did not. Without this,
        // a 120Hz pointer re-presents the panel on every single event.
        let junctionChanged = (hoveredJunction?.id != hoveredJunc?.id)
        let activeChanged: Bool
        switch (hoveredDivider, hovered) {
        case (nil, nil):
            activeChanged = junctionChanged
        case let (previous?, current?):
            activeChanged = previous.coordinate != current.coordinate || !isSameSeam(previous, as: current) || junctionChanged
        default:
            activeChanged = true
        }
        // The overlay draws window outlines too, so a change in which windows
        // are on screen is a change even when the seams look identical.
        let setChanged = !sameDividerSet(dividers, lastPresentedDividers)
            || displayWindows != lastPresentedWindows
            || container != lastPresentedContainer

        if let junc = hoveredJunc {
            hoveredJunction = junc
            hoveredDivider = nil
            setCursor(.crosshair)
        } else if let divider = hovered {
            hoveredJunction = nil
            hoveredDivider = divider
            switch divider.orientation {
            case .vertical:
                setCursor(.resizeLeftRight)
            case .horizontal:
                setCursor(.resizeUpDown)
            }
        } else {
            if hoveredDivider != nil || hoveredJunction != nil { setCursor(.arrow) }
            hoveredDivider = nil
            hoveredJunction = nil
        }

        guard activeChanged || setChanged else { return }
        lastPresentedDividers = dividers
        lastPresentedWindows = displayWindows
        lastPresentedContainer = container

        if let junc = hoveredJunc {
            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: nil,
                activeJunction: junc,
                isDragging: false
            )
        } else if let activeDivider = hovered {
            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: activeDivider,
                activeJunction: nil,
                isDragging: false
            )
        } else {
            overlayManager?.hide(animated: true)
        }
    }

    public private(set) var initialWindows: [CGWindowID: ManagedWindow] = [:]

    public func handleMouseDown(at point: CGPoint) async -> Bool {
        // BUG-01: guard against dual-trigger (overlay callback + global downMonitor both fire)
        guard !isResizing else { return false }

        if let service = accessibilityService, !service.isTrusted {
            return false
        }

        // PERF-02+03: resolve gap and primaryHeight once at mouseDown and cache them.
        // Both values are constant for the lifetime of the drag session.
        let gap = resolveGap()
        dragGap = gap
        dragPrimaryHeight = await displayManager.primaryScreenHeight
        let container = await resolveContainer(at: point)
        if isWorkspaceRestrictionEnabled && currentActiveWorkspace != nil && !managedWindows.isEmpty {
            let belongsToWorkspaceScreen = managedWindows.contains { win in
                let intersection = win.frame.intersection(container)
                return !intersection.isNull && intersection.width > 20 && intersection.height > 20
            }
            if !belongsToWorkspaceScreen { return false }
        }
        if isWorkspaceRestrictionEnabled && isNonWorkspaceAppFrontmost {
            return false
        }
        let displayWindows = filterWindows(for: container)
        let dividers = cachedDividers(for: displayWindows, container: container, gap: gap)
        let junctions = detector.detectJunctions(in: dividers, tolerance: max(gap + 12.0, 16.0))

        if let junction = detector.hitTestJunction(at: point, in: junctions) {
            activeJunction = junction
            activeDivider = nil
            dragDividers = dividers
            dragContainer = container
            isResizing = true
            var initMap: [CGWindowID: ManagedWindow] = [:]
            for w in displayWindows {
                initMap[w.id] = w
            }
            self.initialWindows = initMap
            self.lastCommittedFrames = initMap.mapValues { $0.frame }
            self.activeMinSizes.removeAll()

            cachedAXElements.removeAll()
            if let service = accessibilityService {
                for w in displayWindows {
                    if let element = service.windowElement(for: w) {
                        cachedAXElements[w.id] = element
                    }
                }
            }

            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: nil,
                activeJunction: junction,
                isDragging: true
            )
            dividerLogger.debug("Started junction resize session at \(junction.point.x, privacy: .public),\(junction.point.y, privacy: .public)")
            return true
        }

        guard let divider = detector.hitTestDivider(at: point, in: dividers) else {
            return false
        }

        activeDivider = divider
        activeJunction = nil
        dragDividers = dividers
        // BUG-03: lock container to the display where drag started
        dragContainer = container
        isResizing = true
        var initMap: [CGWindowID: ManagedWindow] = [:]
        for w in displayWindows {
            initMap[w.id] = w
        }
        self.initialWindows = initMap
        self.lastCommittedFrames = initMap.mapValues { $0.frame }
        self.activeMinSizes.removeAll()

        // Cache AXUIElement references at mouseDown to eliminate redundant IPC lookups during drag
        cachedAXElements.removeAll()
        if let service = accessibilityService {
            for w in displayWindows {
                if let element = service.windowElement(for: w) {
                    cachedAXElements[w.id] = element
                }
            }
        }

        overlayManager?.show(
            containerFrame: container,
            windows: displayWindows,
            dividers: dividers,
            activeDivider: divider,
            activeJunction: nil,
            isDragging: true
        )
        dividerLogger.debug("Started divider resize session on \(divider.orientation.rawValue, privacy: .public) divider at \(divider.coordinate, privacy: .public)")
        return true
    }

    /// Injects dynamic minimum size limits into windows so geometric computations clamp appropriately.
    private func preparedWindowsForResize(_ windows: [ManagedWindow]) -> [ManagedWindow] {
        guard !activeMinSizes.isEmpty else { return windows }
        return windows.map { window in
            guard let dynamicMin = activeMinSizes[window.id] else { return window }
            var updated = window
            if let existing = window.minSize {
                updated.minSize = CGSize(
                    width: max(existing.width, dynamicMin.width),
                    height: max(existing.height, dynamicMin.height)
                )
            } else {
                updated.minSize = dynamicMin
            }
            return updated
        }
    }

    /// Clears dynamic minimum size constraints when dragging back in the expanding direction.
    private func updateActiveMinSizes(with resizedFrames: [CGWindowID: CGRect], orientation: DividerOrientation) {
        for (id, minSize) in activeMinSizes {
            guard let frame = resizedFrames[id] else { continue }
            switch orientation {
            case .vertical:
                if frame.width > minSize.width + 1 {
                    activeMinSizes.removeValue(forKey: id)
                }
            case .horizontal:
                if frame.height > minSize.height + 1 {
                    activeMinSizes.removeValue(forKey: id)
                }
            }
        }
    }

    public func handleMouseDragged(to point: CGPoint) async {
        guard isResizing else { return }
        if let junction = activeJunction {
            await handleJunctionMouseDragged(to: point, junction: junction)
            return
        }
        guard let divider = activeDivider else { return }

        // PERF-02: use gap cached at mouseDown — no async lookup needed
        let gap = dragGap
        // BUG-03: use the container locked at mouseDown to prevent display-crossing instability
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        let targetCoordinate = (divider.orientation == .vertical) ? point.x : point.y
        let resizedFrames = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        // 1. Where the seam is actually allowed to end up
        let clampedCoordinate: CGFloat
        if let calculatedSeam = seamCoordinate(from: resizedFrames, for: divider, gap: gap) {
            clampedCoordinate = calculatedSeam
        } else {
            clampedCoordinate = (max(divider.minCoordinate, min(divider.maxCoordinate, targetCoordinate))).rounded()
        }
        let draggedDivider = seam(byMoving: divider, to: clampedCoordinate, gap: gap)

        // 2. Real-time preview frames for visual overlay
        var previewWindows: [ManagedWindow] = []
        for var window in displayWindows {
            if let newFrame = resizedFrames[window.id] {
                var stableFrame = newFrame
                if let initial = initialWindows[window.id] {
                    if divider.orientation == .vertical {
                        stableFrame.origin.y = initial.frame.origin.y
                        stableFrame.size.height = initial.frame.size.height
                    } else {
                        stableFrame.origin.x = initial.frame.origin.x
                        stableFrame.size.width = initial.frame.size.width
                    }
                }
                window.frame = stableFrame
            }
            previewWindows.append(window)
        }

        // 3. Real-time visual overlay update (120Hz ProMotion responsiveness)
        var overlayDividers = overlaySet(from: dragDividers, dragging: divider, to: draggedDivider)
        activeDivider = draggedDivider

        let now = ProcessInfo.processInfo.systemUptime
        if throttler.shouldProcess(timestamp: now) {
            let refreshed = detector.detectDividers(
                in: previewWindows, containerFrame: container, gap: gap, tolerance: max(gap + 16.0, 24.0)
            )
            if !refreshed.isEmpty {
                dragDividers = refreshed
                overlayDividers = overlaySet(from: refreshed, dragging: divider, to: draggedDivider)
            }
        }

        overlayManager?.update(
            containerFrame: container,
            windows: previewWindows,
            dividers: overlayDividers,
            activeDivider: draggedDivider,
            isDragging: true
        )

        // PERF-03: use primaryHeight cached at mouseDown — no DisplayManager round-trip per event
        await applyResizedFrames(resizedFrames, primaryHeight: dragPrimaryHeight)
    }

    private func handleJunctionMouseDragged(to point: CGPoint, junction: CrossJunction) async {
        let gap = dragGap
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        let resizedFrames = detector.compute2DResizedFrames(
            for: junction,
            targetPoint: point,
            in: dragDividers,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        let vDivider = dragDividers.first(where: { isSameSeam($0, as: junction.verticalDivider) }) ?? junction.verticalDivider
        let hDivider = dragDividers.first(where: { isSameSeam($0, as: junction.horizontalDivider) }) ?? junction.horizontalDivider

        let clampedX = seamCoordinate(from: resizedFrames, for: vDivider, gap: gap)
            ?? max(vDivider.minCoordinate, min(vDivider.maxCoordinate, point.x)).rounded()
        let clampedY = seamCoordinate(from: resizedFrames, for: hDivider, gap: gap)
            ?? max(hDivider.minCoordinate, min(hDivider.maxCoordinate, point.y)).rounded()

        let draggedPoint = CGPoint(x: clampedX, y: clampedY)
        let draggedVDivider = seam(byMoving: vDivider, to: clampedX, gap: gap)
        let draggedHDivider = seam(byMoving: hDivider, to: clampedY, gap: gap)

        let draggedJunction = CrossJunction(
            id: junction.id,
            point: draggedPoint,
            verticalDivider: draggedVDivider,
            horizontalDivider: draggedHDivider,
            hitRadius: junction.hitRadius,
            participatingWindowIDs: junction.participatingWindowIDs
        )
        activeJunction = draggedJunction

        var previewWindows: [ManagedWindow] = []
        for var window in displayWindows {
            if let newFrame = resizedFrames[window.id] {
                window.frame = newFrame
            }
            previewWindows.append(window)
        }

        var overlayDividers = overlaySet(from: dragDividers, dragging: vDivider, to: draggedVDivider)
        overlayDividers = overlaySet(from: overlayDividers, dragging: hDivider, to: draggedHDivider)

        let now = ProcessInfo.processInfo.systemUptime
        if throttler.shouldProcess(timestamp: now) {
            let refreshed = detector.detectDividers(
                in: previewWindows, containerFrame: container, gap: gap, tolerance: max(gap + 16.0, 24.0)
            )
            if !refreshed.isEmpty {
                dragDividers = refreshed
                overlayDividers = overlaySet(from: refreshed, dragging: vDivider, to: draggedVDivider)
                overlayDividers = overlaySet(from: overlayDividers, dragging: hDivider, to: draggedHDivider)
            }
        }

        overlayManager?.update(
            containerFrame: container,
            windows: previewWindows,
            dividers: overlayDividers,
            activeDivider: nil,
            activeJunction: draggedJunction,
            isDragging: true
        )

        updateActiveMinSizes(with: resizedFrames, orientation: .vertical)
        updateActiveMinSizes(with: resizedFrames, orientation: .horizontal)
        await applyResizedFrames(resizedFrames, primaryHeight: dragPrimaryHeight)
    }

    public func handleMouseUp(at point: CGPoint) async {
        guard isResizing else { return }
        if let junction = activeJunction {
            await handleJunctionMouseUp(at: point, junction: junction)
            return
        }
        guard let divider = activeDivider else { return }
        dividerLogger.debug("Ended divider resize session with final snap")
        // PERF-02+03: use values cached at mouseDown
        let gap = dragGap
        // BUG-03: keep container consistent with drag session
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        // BUG-04: use the already-clamped divider.coordinate rather than raw mouse point
        // to prevent a 1-2pt jump between the live preview position and final committed frame.
        let targetCoordinate = divider.coordinate
        let resizedFrames = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        let primaryHeight = dragPrimaryHeight
        await applyResizedFrames(resizedFrames, primaryHeight: primaryHeight, force: true)

        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        throttler.reset()
        setCursor(.arrow)

        // BUG-02: re-sync managedWindows with actual AX frames so the next drag
        // session starts from correct geometry (prevents X-axis drift on repeated horizontal drags).
        dividerCache = nil
        await refreshWindowsIfNeeded()

        let finalDisplayWindows = filterWindows(for: container)
        let finalDividers = cachedDividers(for: finalDisplayWindows, container: container, gap: gap)
        lastPresentedDividers = finalDividers
        lastPresentedWindows = finalDisplayWindows
        lastPresentedContainer = container

        // Auto-save customized ratio to the active workspace after autoSaveDelay (5 minutes)
        if let workspace = currentActiveWorkspace {
            var updatedNormalizedRects: [String: CGRect] = [:]
            for window in finalDisplayWindows {
                if let bundleID = window.bundleIdentifier {
                    let normRect = ZoneInference.normalizedRect(of: window.frame, within: container)
                    updatedNormalizedRects[bundleID] = normRect
                }
            }
            if !updatedNormalizedRects.isEmpty {
                ratioAutoSaveTask?.cancel()
                let delay = self.autoSaveDelay
                let targetWorkspaceID = workspace.id
                ratioAutoSaveTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    guard !Task.isCancelled, let self else { return }
                    try? await self.workspaceManager?.updateWorkspaceRatios(
                        workspaceID: targetWorkspaceID,
                        normalizedRects: updatedNormalizedRects
                    )
                }
            }
        }

        overlayManager?.hide(animated: true)
    }

    private func handleJunctionMouseUp(at point: CGPoint, junction: CrossJunction) async {
        dividerLogger.debug("Ended junction resize session with final snap")
        let gap = dragGap
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        let targetPoint = junction.point
        let resizedFrames = detector.compute2DResizedFrames(
            for: junction,
            targetPoint: targetPoint,
            in: dragDividers,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        let primaryHeight = dragPrimaryHeight
        await applyResizedFrames(resizedFrames, primaryHeight: primaryHeight, force: true)

        isResizing = false
        activeJunction = nil
        activeDivider = nil
        hoveredJunction = nil
        hoveredDivider = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        throttler.reset()
        setCursor(.arrow)

        dividerCache = nil
        await refreshWindowsIfNeeded()

        let finalDisplayWindows = filterWindows(for: container)
        let finalDividers = cachedDividers(for: finalDisplayWindows, container: container, gap: gap)
        lastPresentedDividers = finalDividers
        lastPresentedWindows = finalDisplayWindows
        lastPresentedContainer = container

        if let workspace = currentActiveWorkspace {
            var updatedNormalizedRects: [String: CGRect] = [:]
            for window in finalDisplayWindows {
                if let bundleID = window.bundleIdentifier {
                    let normRect = ZoneInference.normalizedRect(of: window.frame, within: container)
                    updatedNormalizedRects[bundleID] = normRect
                }
            }
            if !updatedNormalizedRects.isEmpty {
                ratioAutoSaveTask?.cancel()
                let delay = self.autoSaveDelay
                let targetWorkspaceID = workspace.id
                ratioAutoSaveTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    guard !Task.isCancelled, let self else { return }
                    try? await self.workspaceManager?.updateWorkspaceRatios(
                        workspaceID: targetWorkspaceID,
                        normalizedRects: updatedNormalizedRects
                    )
                }
            }
        }

        overlayManager?.hide(animated: true)
    }

    /// Dispatches resized frames to WindowManager using a 2-phase ordering:
    /// Shrinking windows first to free up space, followed by Expanding windows.
    private func applyResizedFrames(
        _ resizedFrames: [CGWindowID: CGRect],
        primaryHeight: CGFloat,
        force: Bool = false
    ) async {
        var updates: [(window: ManagedWindow, stableFrame: CGRect, isShrinking: Bool)] = []
        for (id, frame) in resizedFrames {
            guard let index = managedWindows.firstIndex(where: { $0.id == id }) else { continue }
            let currentWindow = managedWindows[index]

            var stableFrame = frame
            if let initial = initialWindows[id] {
                if let activeDivider, activeDivider.orientation == .vertical {
                    stableFrame.origin.y = initial.frame.origin.y
                    stableFrame.size.height = initial.frame.size.height
                } else if let activeDivider, activeDivider.orientation == .horizontal {
                    stableFrame.origin.x = initial.frame.origin.x
                    stableFrame.size.width = initial.frame.size.width
                }
            }
            stableFrame.origin.x = stableFrame.origin.x.rounded()
            stableFrame.origin.y = stableFrame.origin.y.rounded()
            stableFrame.size.width = stableFrame.size.width.rounded()
            stableFrame.size.height = stableFrame.size.height.rounded()

            // Skip redundant sub-pixel AX frame updates (< 0.5pt delta)
            if !force, let lastFrame = lastCommittedFrames[id] {
                let dx = abs(lastFrame.origin.x - stableFrame.origin.x)
                let dy = abs(lastFrame.origin.y - stableFrame.origin.y)
                let dw = abs(lastFrame.width - stableFrame.width)
                let dh = abs(lastFrame.height - stableFrame.height)
                if dx < 0.5 && dy < 0.5 && dw < 0.5 && dh < 0.5 {
                    continue
                }
            }

            // BUG-08: compare the relevant dimension rather than area so that windows
            // with extreme aspect ratios are ordered correctly in the 2-phase dispatch.
            let isShrinking: Bool
            if let activeDivider {
                switch activeDivider.orientation {
                case .vertical:
                    isShrinking = stableFrame.width <= currentWindow.frame.width
                case .horizontal:
                    isShrinking = stableFrame.height <= currentWindow.frame.height
                }
            } else {
                isShrinking = (stableFrame.width * stableFrame.height)
                    <= (currentWindow.frame.width * currentWindow.frame.height)
            }
            updates.append((window: currentWindow, stableFrame: stableFrame, isShrinking: isShrinking))
        }

        guard !updates.isEmpty else { return }
        let sortedUpdates = updates.sorted { ($0.isShrinking ? 0 : 1) < ($1.isShrinking ? 0 : 1) }

        // PERF-04: separate AX writes from registry updates so actor hops do not multiply
        // with window count. Perform all AX writes first (order-sensitive), then batch
        // the registry updates in a single pass.
        var updatedWindowsForRegistry: [ManagedWindow] = []

        for update in sortedUpdates {
            if let index = managedWindows.firstIndex(where: { $0.id == update.window.id }) {
                var updatedWindow = managedWindows[index]
                updatedWindow.frame = update.stableFrame
                managedWindows[index] = updatedWindow
                lastCommittedFrames[update.window.id] = update.stableFrame

                let axFrame = CoordinateTransformer.toAX(rect: update.stableFrame, primaryScreenHeight: primaryHeight)
                let element = cachedAXElements[update.window.id]
                try? await windowManager.move(updatedWindow, to: axFrame, element: element)
                // Only shrinking windows can hit a minimum size constraint.
                // Skipping AX readback on expanding windows eliminates ~50% of IPC latency per frame.
                if update.isShrinking {
                    syncActualWindowFrame(for: &updatedWindow, at: index, requested: update.stableFrame, primaryHeight: primaryHeight, cachedElement: element)
                }
                updatedWindowsForRegistry.append(updatedWindow)
            }
        }

        // Batch registry updates after all AX writes complete.
        if let registry = windowRegistry {
            for window in updatedWindowsForRegistry {
                await registry.update(window)
            }
        }
    }

    private func syncActualWindowFrame(
        for updatedWindow: inout ManagedWindow,
        at index: Int,
        requested: CGRect,
        primaryHeight: CGFloat,
        cachedElement: AXUIElement?
    ) {
        guard let service = accessibilityService,
              let axElement = cachedElement ?? service.windowElement(for: updatedWindow),
              let actualAXFrame = service.frame(of: axElement) else { return }
        let actualAppKitFrame = CoordinateTransformer.toAppKit(rect: actualAXFrame, primaryScreenHeight: primaryHeight)
        if actualAppKitFrame.width > requested.width + 2 || actualAppKitFrame.height > requested.height + 2 {
            let clampedMinSize = CGSize(
                width: max(activeMinSizes[updatedWindow.id]?.width ?? 0, actualAppKitFrame.width),
                height: max(activeMinSizes[updatedWindow.id]?.height ?? 0, actualAppKitFrame.height)
            )
            activeMinSizes[updatedWindow.id] = clampedMinSize
        }
        if actualAppKitFrame.width > requested.width + 1 || actualAppKitFrame.height > requested.height + 1 {
            updatedWindow.frame = actualAppKitFrame
            lastCommittedFrames[updatedWindow.id] = actualAppKitFrame
            managedWindows[index] = updatedWindow
        }
    }

    // MARK: - Cancellation

    public func cancelResize() async {
        guard isResizing else { return }
        flushPendingDrag()
        dividerLogger.debug("Divider resize cancelled; restoring \(self.initialWindows.count, privacy: .public) windows")

        // Use cached primaryHeight if available (drag was cancelled mid-session), else fetch fresh.
        let primaryHeight = dragPrimaryHeight > 0 ? dragPrimaryHeight : await displayManager.primaryScreenHeight
        for (id, original) in initialWindows {
            guard let index = managedWindows.firstIndex(where: { $0.id == id }) else { continue }
            var window = managedWindows[index]
            guard window.frame != original.frame else { continue }

            window.frame = original.frame
            managedWindows[index] = window
            let axFrame = CoordinateTransformer.toAX(rect: original.frame, primaryScreenHeight: primaryHeight)
            let element = cachedAXElements[id]
            try? await windowManager.move(window, to: axFrame, element: element)
            await windowRegistry?.update(window)
        }

        dragContainer = nil
        endSession()
    }

    /// Tears down drag state without committing anything.
    private func endSession() {
        flushPendingDrag()
        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        activeJunction = nil
        hoveredJunction = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        dragGap = 0
        dragPrimaryHeight = 0
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        throttler.reset()
        dividerCache = nil
        lastPresentedDividers = []
        lastPresentedWindows = []
        lastPresentedContainer = nil
        setCursor(.arrow)
        // BUG-07: clear overlay view state so no phantom dividers survive after cancel
        if let panel = overlayManager as? AdaptiveDividerOverlayPanel {
            panel.overlayView.updateState(
                containerFrame: .zero, windows: [], dividers: [],
                activeDivider: nil, activeJunction: nil, isDragging: false
            )
        }
        overlayManager?.hide(animated: true)
    }

    // MARK: - Cursor

    private func setCursor(_ cursor: NSCursor) {
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

