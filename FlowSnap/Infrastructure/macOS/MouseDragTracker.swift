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

    private var dragMonitor: Any?
    private var releaseMonitor: Any?
    private var lastDragTimestamp: TimeInterval = 0
    private let throttleInterval: TimeInterval = 1.0 / 60.0 // 60fps (~16.6ms)

    public private(set) var isTracking: Bool = false

    public init() {}

    /// Starts observing global mouse drag and mouse release events.
    public func startTracking(
        onDrag: @escaping @Sendable (CGPoint) -> Void,
        onRelease: @escaping @Sendable (CGPoint) -> Void
    ) {
        guard !isTracking else { return }

        logger.debug("Starting global mouse drag observation")
        isTracking = true

        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            guard let self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            if now - self.lastDragTimestamp >= self.throttleInterval {
                self.lastDragTimestamp = now
                let location = NSEvent.mouseLocation
                onDrag(location)
            }
        }

        releaseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            guard let self else { return }
            self.lastDragTimestamp = 0
            let location = NSEvent.mouseLocation
            onRelease(location)
        }
    }

    /// Stops observing global mouse events and releases event monitors.
    public func stopTracking() {
        guard isTracking else { return }

        logger.debug("Stopping global mouse drag observation")
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
    }
}
