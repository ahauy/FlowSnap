import Foundation
import CoreGraphics

/// A named collection of layout zones that defines how windows
/// should be arranged on a display.
///
/// Zones use normalized coordinates (0...1) so layouts are
/// resolution-independent. See spec §26.
struct Layout: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var zones: [LayoutZone]

    init(id: UUID = UUID(), name: String, zones: [LayoutZone]) {
        self.id = id
        self.name = name
        self.zones = zones
    }
}
