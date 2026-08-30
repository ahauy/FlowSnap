import Foundation

/// The spatial orientation of a shared layout divider.
public enum DividerOrientation: String, Codable, Sendable {
    /// A vertical divider separating windows horizontally (left/right).
    case vertical
    /// A horizontal divider separating windows vertically (top/bottom).
    case horizontal
}
