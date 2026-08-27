import CoreGraphics
import Foundation

/// A named collection of layout zones that defines how windows
/// should be arranged on a display.
///
/// Zones use normalized coordinates (0...1) so layouts are
/// resolution-independent. See spec §26.
public struct Layout: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var zones: [LayoutZone]

    public init(id: UUID = UUID(), name: String, zones: [LayoutZone]) {
        self.id = id
        self.name = name
        self.zones = zones
    }
}
