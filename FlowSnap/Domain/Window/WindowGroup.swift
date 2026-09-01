import CoreGraphics
import Foundation

/// Synchronization options for linked window group operations (spec §1.4).
public struct GroupSyncOptions: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let minimizeTogether = GroupSyncOptions(rawValue: 1 << 0)
    public static let focusTogether    = GroupSyncOptions(rawValue: 1 << 1)
    public static let moveTogether     = GroupSyncOptions(rawValue: 1 << 2)

    public static let all: GroupSyncOptions = [.minimizeTogether, .focusTogether, .moveTogether]
}

/// A dynamic association of two or more managed windows cooperating as a unified visual unit (spec §1.4).
public struct WindowGroup: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var windowIDs: Set<CGWindowID>
    public var anchorWindowID: CGWindowID?
    public var syncOptions: GroupSyncOptions
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        windowIDs: Set<CGWindowID>,
        anchorWindowID: CGWindowID? = nil,
        syncOptions: GroupSyncOptions = .all,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.windowIDs = windowIDs
        self.anchorWindowID = anchorWindowID ?? windowIDs.first
        self.syncOptions = syncOptions
        self.createdAt = createdAt
    }

    public var memberCount: Int { windowIDs.count }
    public var isValid: Bool { windowIDs.count >= 2 }
}
