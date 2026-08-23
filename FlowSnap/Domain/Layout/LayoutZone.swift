import Foundation
import CoreGraphics

/// A single zone within a Layout.
///
/// Coordinates are normalized to the range 0...1, where
/// (0, 0) is the top-left corner of the display's visible frame.
/// This makes layouts resolution- and display-independent.
/// See spec §26.
struct LayoutZone: Identifiable, Codable, Hashable {
    let id: UUID

    /// Normalized x position (0...1).
    let x: CGFloat

    /// Normalized y position (0...1).
    let y: CGFloat

    /// Normalized width (0...1).
    let width: CGFloat

    /// Normalized height (0...1).
    let height: CGFloat

    init(id: UUID = UUID(), x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.id = id
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}
