import CoreGraphics
import Foundation

/// A standard snap zone on a display.
///
/// Standard zones provide deterministic, resolution-independent layouts.
/// Coordinates in normalized space range from 0...1 with origin at top-left.
public enum LayoutZone: String, Sendable, Codable, Hashable, CaseIterable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
    @available(*, deprecated, renamed: "left70_30")
    case leftTwoThirds
    case rightOneThird
    case leftThird
    case centerThird
    case rightThird

    // MARK: - New asymmetric ratios (US-SNAP-008)

    case left60_40
    case right40_60
    case left80_20
    case right20_80
    case left25
    case center50
    case right25
    case left70_30

    /// All non-deprecated zones. `leftTwoThirds` is intentionally excluded;
    /// use `left70_30` (same normalizedRect).
    public static let allCases: [LayoutZone] = [
        .leftHalf, .rightHalf, .topHalf, .bottomHalf,
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        .maximize, .rightOneThird, .leftThird, .centerThird, .rightThird,
        .left60_40, .right40_60, .left80_20, .right20_80,
        .left25, .center50, .right25, .left70_30,
    ]

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
        case .leftTwoThirds:
            CGRect(x: 0, y: 0, width: 0.7, height: 1.0)
        case .rightOneThird:
            CGRect(x: 0.7, y: 0, width: 0.3, height: 1.0)
        case .leftThird:
            CGRect(x: 0, y: 0, width: 1.0 / 3.0, height: 1.0)
        case .centerThird:
            CGRect(x: 1.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1.0)
        case .rightThird:
            CGRect(x: 2.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1.0)
        case .left60_40:
            CGRect(x: 0, y: 0, width: 0.6, height: 1.0)
        case .right40_60:
            CGRect(x: 0.6, y: 0, width: 0.4, height: 1.0)
        case .left80_20:
            CGRect(x: 0, y: 0, width: 0.8, height: 1.0)
        case .right20_80:
            CGRect(x: 0.8, y: 0, width: 0.2, height: 1.0)
        case .left25:
            CGRect(x: 0, y: 0, width: 0.25, height: 1.0)
        case .center50:
            CGRect(x: 0.25, y: 0, width: 0.5, height: 1.0)
        case .right25:
            CGRect(x: 0.75, y: 0, width: 0.25, height: 1.0)
        case .left70_30:
            CGRect(x: 0, y: 0, width: 0.7, height: 1.0)
        }
    }
}
