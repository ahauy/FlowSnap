import CoreGraphics
import Foundation

/// Saved geometry for an application window.
///
/// See spec §37, US-WORK-014.
public struct RememberedFrame: Codable, Hashable, Sendable {
    public let bundleID: String
    public let frame: CGRect
    public let displayID: CGDirectDisplayID?
    public let savedAt: Date

    public init(
        bundleID: String,
        frame: CGRect,
        displayID: CGDirectDisplayID? = nil,
        savedAt: Date = Date()
    ) {
        self.bundleID = bundleID
        self.frame = frame
        self.displayID = displayID
        self.savedAt = savedAt
    }
}
