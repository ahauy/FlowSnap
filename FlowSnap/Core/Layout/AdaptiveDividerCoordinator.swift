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
    private let accessibilityService: AccessibilityService?
    private let windowRegistry: WindowRegistry?
    private let overlayManager: AdaptiveDividerOverlayManaging?

    private var moveMonitor: Any?
    private var downMonitor: Any?
    private var dragMonitor: Any?
    private var upMonitor: Any?

    public private(set) var isTracking: Bool = false
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
        preferencesStore: PreferencesStore? = nil,
        accessibilityService: AccessibilityService? = nil,
        windowRegistry: WindowRegistry? = nil,
        overlayManager: AdaptiveDividerOverlayManaging? = nil
    ) {
        self.detector = detector
        self.windowManager = windowManager
        self.displayManager = displayManager
        self.throttler = throttler
        self.preferencesStore = preferencesStore
        self.accessibilityService = accessibilityService
        self.windowRegistry = windowRegistry
        self.overlayManager = overlayManager
    }

    // MARK: - Lifecycle

    public func start() {
        guard !isTracking else { return }
        isTracking = true
        dividerLogger.debug("Starting AdaptiveDividerCoordinator global monitors")

        if let overlayPanel = overlayManager as? AdaptiveDividerOverlayPanel {
            overlayPanel.overlayView.onDirectMouseDown = { [weak self] point, _ in
                Task { @MainActor [weak self] in
                    guard let self, self.isTracking else { return }
                    await self.refreshWindowsIfNeeded()
                    _ = await self.handleMouseDown(at: point)
                }
            }
            overlayPanel.overlayView.onDirectMouseDragged = { [weak self] point in
                Task { @MainActor [weak self] in
                    guard let self, self.isTracking else { return }
                    await self.handleMouseDragged(to: point)
                }
            }
            overlayPanel.overlayView.onDirectMouseUp = { [weak self] point in
                Task { @MainActor [weak self] in
                    guard let self, self.isTracking else { return }
                    await self.handleMouseUp(at: point)
                }
            }
            overlayPanel.overlayView.onDirectMouseMoved = { [weak self] point in
                Task { @MainActor [weak self] in
                    guard let self, self.isTracking else { return }
                    await self.handleMouseMoved(to: point)
                }
            }
        }

        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                let point = NSEvent.mouseLocation
                await self.refreshWindowsIfNeeded()
                await self.handleMouseMoved(to: point)
            }
        }

        downMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                let point = NSEvent.mouseLocation
                await self.refreshWindowsIfNeeded()
                _ = await self.handleMouseDown(at: point)
            }
        }

        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                let point = NSEvent.mouseLocation
                await self.handleMouseDragged(to: point)
            }
        }

        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                let point = NSEvent.mouseLocation
                await self.handleMouseUp(at: point)
            }
        }
    }

    public func stop() {
        guard isTracking else { return }
        dividerLogger.debug("Stopping AdaptiveDividerCoordinator global monitors")
        if let moveMonitor { NSEvent.removeMonitor(moveMonitor); self.moveMonitor = nil }
        if let downMonitor { NSEvent.removeMonitor(downMonitor); self.downMonitor = nil }
        if let dragMonitor { NSEvent.removeMonitor(dragMonitor); self.dragMonitor = nil }
        if let upMonitor { NSEvent.removeMonitor(upMonitor); self.upMonitor = nil }
        isTracking = false
        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        setCursor(.arrow)
        overlayManager?.hide(animated: false)
    }

    // MARK: - Window Management

    public func updateWindows(_ windows: [ManagedWindow]) {
        self.managedWindows = windows
    }

    private func refreshWindowsIfNeeded() async {
        if isResizing { return }
        if let registry = windowRegistry {
            let tracked = await registry.allWindows
            if tracked.count >= 2 {
                self.managedWindows = tracked
                return
            }
        }
        if let service = accessibilityService {
            let visible = service.allVisibleManagedWindows()
            if visible.count >= 2 {
                self.managedWindows = visible
            }
        }
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

    private func filterWindows(for container: CGRect) -> [ManagedWindow] {
        managedWindows.filter { window in
            let intersection = window.frame.intersection(container)
            return !intersection.isNull && intersection.width > 20 && intersection.height > 20
        }
    }

    public func handleMouseMoved(to point: CGPoint) async {
        guard !isResizing else { return }

        let gap = await resolveGap()
        let container = await resolveContainer(at: point)
        let displayWindows = filterWindows(for: container)
        let dividers = detector.detectDividers(in: displayWindows, containerFrame: container, gap: gap, tolerance: 6.0)

        if let divider = detector.hitTestDivider(at: point, in: dividers) {
            hoveredDivider = divider
            switch divider.orientation {
            case .vertical:
                setCursor(.resizeLeftRight)
            case .horizontal:
                setCursor(.resizeUpDown)
            }
            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: divider,
                isDragging: false
            )
        } else {
            if hoveredDivider != nil {
                hoveredDivider = nil
                setCursor(.arrow)
            }
            overlayManager?.hide(animated: true)
        }
    }

    public private(set) var initialWindows: [CGWindowID: ManagedWindow] = [:]

    public func handleMouseDown(at point: CGPoint) async -> Bool {
        let gap = await resolveGap()
        let container = await resolveContainer(at: point)
        let displayWindows = filterWindows(for: container)
        let dividers = detector.detectDividers(in: displayWindows, containerFrame: container, gap: gap, tolerance: 6.0)

        guard let divider = detector.hitTestDivider(at: point, in: dividers) else {
            return false
        }

        activeDivider = divider
        isResizing = true
        var initMap: [CGWindowID: ManagedWindow] = [:]
        for w in displayWindows {
            initMap[w.id] = w
        }
        self.initialWindows = initMap
        overlayManager?.show(
            containerFrame: container,
            windows: displayWindows,
            dividers: dividers,
            activeDivider: divider,
            isDragging: true
        )
        dividerLogger.debug("Started divider resize session on \(divider.orientation.rawValue, privacy: .public) divider at \(divider.coordinate, privacy: .public)")
        return true
    }

    public func handleMouseDragged(to point: CGPoint) async {
        guard isResizing, let divider = activeDivider else { return }

        let now = ProcessInfo.processInfo.systemUptime
        guard throttler.shouldProcess(timestamp: now) else { return }

        let gap = await resolveGap()
        let container = await resolveContainer(at: point)
        let displayWindows = filterWindows(for: container)

        let targetCoordinate = (divider.orientation == .vertical) ? point.x : point.y
        let resizedFrames = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: displayWindows.isEmpty ? managedWindows : displayWindows,
            containerFrame: container,
            gap: gap
        )

        let primaryHeight = await displayManager.primaryScreenHeight
        for (id, frame) in resizedFrames {
            if let index = managedWindows.firstIndex(where: { $0.id == id }) {
                var window = managedWindows[index]

                // Strictly lock the orthogonal dimension to prevent any vertical/horizontal jumping
                var stableFrame = frame
                if let initial = initialWindows[id] {
                    if divider.orientation == .vertical {
                        stableFrame.origin.y = initial.frame.origin.y
                        stableFrame.size.height = initial.frame.size.height
                    } else {
                        stableFrame.origin.x = initial.frame.origin.x
                        stableFrame.size.width = initial.frame.size.width
                    }
                }

                window.frame = stableFrame
                managedWindows[index] = window
                let axFrame = CoordinateTransformer.toAX(rect: stableFrame, primaryScreenHeight: primaryHeight)
                try? await windowManager.move(window, to: axFrame)
                await windowRegistry?.update(window)
            }
        }

        let updatedDisplayWindows = filterWindows(for: container)
        let updatedDividers = detector.detectDividers(in: updatedDisplayWindows, containerFrame: container, gap: gap, tolerance: 6.0)
        let updatedActiveDivider = updatedDividers.first { $0.orientation == divider.orientation } ?? divider

        overlayManager?.update(
            containerFrame: container,
            windows: updatedDisplayWindows,
            dividers: updatedDividers,
            activeDivider: updatedActiveDivider,
            isDragging: true
        )
    }

    public func handleMouseUp(at point: CGPoint) async {
        guard isResizing else { return }
        dividerLogger.debug("Ended divider resize session")
        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        initialWindows.removeAll()
        throttler.reset()
        setCursor(.arrow)
        overlayManager?.hide(animated: true)
    }

    private func setCursor(_ cursor: NSCursor) {
        currentCursor = cursor
        cursor.set()
    }
}
