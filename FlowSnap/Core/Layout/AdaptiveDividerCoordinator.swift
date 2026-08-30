import AppKit
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

    public private(set) var managedWindows: [ManagedWindow] = []
    public private(set) var activeDivider: CollinearEdge?
    public private(set) var hoveredDivider: CollinearEdge?
    public private(set) var isResizing: Bool = false
    public private(set) var currentCursor: NSCursor = .arrow

    public init(
        detector: CollinearEdgeDetecting = CollinearEdgeDetector(),
        windowManager: WindowManaging,
        displayManager: DisplayManaging,
        throttler: LiveResizeThrottling = LiveResizeThrottler(fps: 60.0),
        preferencesStore: PreferencesStore? = nil
    ) {
        self.detector = detector
        self.windowManager = windowManager
        self.displayManager = displayManager
        self.throttler = throttler
        self.preferencesStore = preferencesStore
    }

    public func updateWindows(_ windows: [ManagedWindow]) {
        self.managedWindows = windows
    }

    private func resolveContainer(at point: CGPoint) async -> CGRect {
        let display = await displayManager.display(containing: point)
        if let display {
            return display.visibleFrame
        }
        let primary = await displayManager.primaryDisplay
        return primary?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    private func resolveGap() async -> CGFloat {
        guard let preferencesStore else { return 0 }
        return await preferencesStore.windowGap
    }

    public func handleMouseMoved(to point: CGPoint) async {
        guard !isResizing else { return }

        let gap = await resolveGap()
        let container = await resolveContainer(at: point)
        let dividers = detector.detectDividers(in: managedWindows, containerFrame: container, gap: gap, tolerance: 6.0)

        if let divider = detector.hitTestDivider(at: point, in: dividers) {
            hoveredDivider = divider
            switch divider.orientation {
            case .vertical:
                setCursor(.resizeLeftRight)
            case .horizontal:
                setCursor(.resizeUpDown)
            }
        } else {
            if hoveredDivider != nil {
                hoveredDivider = nil
                setCursor(.arrow)
            }
        }
    }

    public func handleMouseDown(at point: CGPoint) async -> Bool {
        let gap = await resolveGap()
        let container = await resolveContainer(at: point)
        let dividers = detector.detectDividers(in: managedWindows, containerFrame: container, gap: gap, tolerance: 6.0)

        guard let divider = detector.hitTestDivider(at: point, in: dividers) else {
            return false
        }

        activeDivider = divider
        isResizing = true
        dividerLogger.debug("Started divider resize session on \(divider.orientation.rawValue, privacy: .public) divider at \(divider.coordinate, privacy: .public)")
        return true
    }

    public func handleMouseDragged(to point: CGPoint) async {
        guard isResizing, let divider = activeDivider else { return }

        let now = ProcessInfo.processInfo.systemUptime
        guard throttler.shouldProcess(timestamp: now) else { return }

        let gap = await resolveGap()
        let container = await resolveContainer(at: point)

        let targetCoordinate = (divider.orientation == .vertical) ? point.x : point.y
        let resizedFrames = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: managedWindows,
            containerFrame: container,
            gap: gap
        )

        for (id, frame) in resizedFrames {
            if let index = managedWindows.firstIndex(where: { $0.id == id }) {
                var window = managedWindows[index]
                window.frame = frame
                managedWindows[index] = window
                try? await windowManager.move(window, to: frame)
            }
        }
    }

    public func handleMouseUp(at point: CGPoint) async {
        guard isResizing else { return }
        dividerLogger.debug("Ended divider resize session")
        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        throttler.reset()
        setCursor(.arrow)
    }

    private func setCursor(_ cursor: NSCursor) {
        currentCursor = cursor
        cursor.set()
    }
}
