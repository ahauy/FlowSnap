import CoreGraphics
import Foundation

/// Logical category for applications in workspace presets (spec §1.2).
public enum PresetAppCategory: String, Codable, Hashable, Sendable, CaseIterable {
    case editor = "Code & Text Editor"
    case browser = "Web Browser"
    case terminal = "Terminal & Shell"
    case notes = "Notes & Knowledge"
    case writing = "Writing & Documents"
    case design = "Design & UI Tools"
    case custom = "Custom Application"
}

/// Represents a logical application slot within a preset with prioritized fallback bundle IDs.
public struct PresetAppSlot: Codable, Hashable, Sendable, Identifiable {
    public var id: String { "\(roleDescription)-\(zone.rawValue)" }
    public let category: PresetAppCategory
    public let roleDescription: String
    public let preferredBundleIDs: [String]
    public let zone: LayoutZone
    public let ratio: LayoutRatio
    public let normalizedRect: CGRect?

    public init(
        category: PresetAppCategory,
        roleDescription: String,
        preferredBundleIDs: [String],
        zone: LayoutZone,
        ratio: LayoutRatio = .equal,
        normalizedRect: CGRect? = nil
    ) {
        self.category = category
        self.roleDescription = roleDescription
        self.preferredBundleIDs = preferredBundleIDs
        self.zone = zone
        self.ratio = ratio
        self.normalizedRect = normalizedRect
    }
}
