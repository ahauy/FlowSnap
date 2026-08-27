import CoreGraphics
import Foundation

/// A standard snap zone on a display.
///
/// Standard zones provide deterministic, resolution-independent layouts.
/// Coordinates in normalized space range from 0...1 with origin at top-left.
public enum LayoutZone: String, CaseIterable, Sendable, Codable, Hashable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize

    /// Normalized bounding box (0...1 coordinates with top-left origin).
    public var normalizedRect: CGRect {
        switch self {
        case .leftHalf:
            CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
        case .rightHalf:
            CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)
        case .topHalf:
            CGRect(x: 0, y: 0, width: 1.0, height: 0.5)
        case .bottomHalf:
            CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5)
        case .topLeft:
            CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        case .topRight:
            CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
        case .bottomLeft:
            CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5)
        case .bottomRight:
            CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        case .maximize:
            CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        }
    }
}
