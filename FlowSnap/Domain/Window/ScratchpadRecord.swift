import CoreGraphics
import Foundation

/// Immutable record identifying the currently assigned Scratchpad window.
public struct ScratchpadRecord: Sendable, Identifiable, Hashable {
    public var id: CGWindowID { windowID }
    public let windowID: CGWindowID
    public let pid: pid_t
    public let bundleID: String?
    public let appName: String
    public let windowTitle: String?
    public let assignedAt: Date

    public init(
        windowID: CGWindowID,
        pid: pid_t,
        bundleID: String? = nil,
        appName: String,
        windowTitle: String? = nil,
        assignedAt: Date = Date()
    ) {
        self.windowID = windowID
        self.pid = pid
        self.bundleID = bundleID
        self.appName = appName
        self.windowTitle = windowTitle
        self.assignedAt = assignedAt
    }
}
