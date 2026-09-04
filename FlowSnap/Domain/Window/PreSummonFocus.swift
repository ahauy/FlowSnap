import CoreGraphics
import Foundation

/// Snapshot of the frontmost application and focused window prior to summoning the Scratchpad.
public struct PreSummonFocus: Sendable, Equatable {
    public let pid: pid_t
    public let windowID: CGWindowID?
    public let timestamp: Date

    public init(pid: pid_t, windowID: CGWindowID? = nil, timestamp: Date = Date()) {
        self.pid = pid
        self.windowID = windowID
        self.timestamp = timestamp
    }
}
