import CoreGraphics
import Foundation

/// An interactive partition tile inside a `LayoutTemplate`.
///
/// Represents an individual slot/cell in the Top-Edge Layout Picker.
/// Maps normalized coordinates to a concrete `SnapTarget`.
public struct LayoutSlot: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let target: SnapTarget
    public let normalizedRect: CGRect // Normalized bounds (0...1) within the template card

    public init(id: String, title: String, target: SnapTarget, normalizedRect: CGRect) {
        self.id = id
        self.title = title
        self.target = target
        self.normalizedRect = normalizedRect
    }
}
