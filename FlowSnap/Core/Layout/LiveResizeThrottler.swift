import Foundation

/// Paces live drag operations at a maximum target FPS (default 60fps / ~16.6ms interval)
/// to prevent WindowServer and Accessibility IPC bottlenecks.
public final class LiveResizeThrottler: LiveResizeThrottling, @unchecked Sendable {
    private let minInterval: TimeInterval
    private var lastProcessedTimestamp: TimeInterval = 0
    private let lock = NSLock()

    public init(fps: Double = 60.0) {
        self.minInterval = 1.0 / max(1.0, fps)
    }

    public func shouldProcess(timestamp: TimeInterval) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if lastProcessedTimestamp == 0 || (timestamp - lastProcessedTimestamp) >= minInterval {
            lastProcessedTimestamp = timestamp
            return true
        }
        return false
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        lastProcessedTimestamp = 0
    }
}
