import Foundation

/// Protocol for throttling high-frequency live resize operations.
public protocol LiveResizeThrottling: Sendable {
    /// Whether an incoming frame resize event should be processed given the current timestamp.
    func shouldProcess(timestamp: TimeInterval) -> Bool
    /// Reset internal timestamp tracking.
    func reset()
}
