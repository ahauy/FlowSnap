import CoreGraphics
import Foundation

/// Immutable record identifying a pinned window and its metadata.
public struct PinnedWindowRecord: Sendable, Identifiable, Hashable {
    public let id: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let title: String
    public let pinnedAt: Date

    public init(
        id: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String? = nil,
        title: String = "",
        pinnedAt: Date = Date()
    ) {
        self.id = id
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.pinnedAt = pinnedAt
    }
}
