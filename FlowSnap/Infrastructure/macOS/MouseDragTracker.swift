import AppKit
import CoreGraphics
import Foundation
import OSLog

/// Infrastructure service for monitoring global mouse drag and mouse up events.
///
/// Uses `NSEvent.addGlobalMonitorForEvents` to passively observe window dragging interactions
/// with 60fps (~16ms) throttling. Conforms to `MouseDragTracking` (@MainActor, Sendable).
@MainActor
public final class MouseDragTracker: MouseDragTracking {

    private let logger = Logger(subsystem: "com.flowsnap.app", category: "MouseDragTracker")

    private var downMonitor: Any?
    private var dragMonitor: Any?
    private var releaseMonitor: Any?
    private var lastDragTimestamp: TimeInterval = 0
    private let throttleInterval: TimeInterval = 1.0 / 60.0 // 60fps (~16.6ms)

    /// Minimum cursor movement (in points) from mouseDown required before recognizing an intentional drag.
    /// Filters out human hand micro-jitter during clicks (spec US-SNAP-010).
    public let dragDeadzone: CGFloat = 16.0
    private var dragStartLocation: CGPoint?
    private var isDragThresholdExceeded: Bool = false

    public private(set) var isTracking: Bool = false

    public init() {}

    /// Starts observing global mouse drag and mouse release events.
    public func startTracking(
        onDrag: @escaping @Sendable (CGPoint) -> Void,
        onRelease: @escaping @Sendable (CGPoint) -> Void
    ) {
        guard !isTracking else { return }

        logger.debug("Starting global mouse drag observation with deadzone \(self.dragDeadzone)pt")
        isTracking = true
        isDragThresholdExceeded = false
        dragStartLocation = nil

        downMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard let self else { return }
            self.dragStartLocation = NSEvent.mouseLocation
            self.isDragThresholdExceeded = false
        }

        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self else { return }
            let location = NSEvent.mouseLocation

            if !self.isDragThresholdExceeded {
                let start = self.dragStartLocation ?? location
                let dx = location.x - start.x
                let dy = location.y - start.y
                if hypot(dx, dy) >= self.dragDeadzone {
                    self.isDragThresholdExceeded = true
                } else {
                    return // Ignore micro-jitter during window clicks/focus
                }
            }

            let now = ProcessInfo.processInfo.systemUptime
            if now - self.lastDragTimestamp >= self.throttleInterval {
                self.lastDragTimestamp = now
                onDrag(location)
            }
        }

        releaseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            guard let self else { return }
            let wasDragging = self.isDragThresholdExceeded
            self.dragStartLocation = nil
            self.isDragThresholdExceeded = false
            self.lastDragTimestamp = 0

            if wasDragging {
                let location = NSEvent.mouseLocation
                onRelease(location)
            }
        }
    }

    /// Stops observing global mouse events and releases event monitors.
    public func stopTracking() {
        guard isTracking else { return }

        logger.debug("Stopping global mouse drag observation")
        if let downMonitor {
            NSEvent.removeMonitor(downMonitor)
            self.downMonitor = nil
        }
        if let dragMonitor {
            NSEvent.removeMonitor(dragMonitor)
            self.dragMonitor = nil
        }
        if let releaseMonitor {
            NSEvent.removeMonitor(releaseMonitor)
            self.releaseMonitor = nil
        }
        isTracking = false
        lastDragTimestamp = 0
        dragStartLocation = nil
        isDragThresholdExceeded = false
    }
}
