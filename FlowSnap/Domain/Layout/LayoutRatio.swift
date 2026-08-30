import Foundation

/// A named window-split ratio that maps to a sequence of layout zones.
///
/// Persisted as its raw `String` value. Raw values are stable and MUST NOT be
/// renamed once shipped. See US-SNAP-008, contracts.md §3.2.
public enum LayoutRatio: String, CaseIterable, Sendable, Codable, Hashable {
    case equal
    case sixtyForty
    case seventyThirty
    case eightyTwenty
    case threeColumn25_50_25

    /// The layout zones composing this ratio, in left-to-right order.
    public var zones: [LayoutZone] {
        switch self {
        case .equal:
            return [.leftHalf, .rightHalf]
        case .sixtyForty:
            return [.left60_40, .right40_60]
        case .seventyThirty:
            return [.left70_30, .rightOneThird]
        case .eightyTwenty:
            return [.left80_20, .right20_80]
        case .threeColumn25_50_25:
            return [.left25, .center50, .right25]
        }
    }

    /// The leading (leftmost) layout zone for this ratio.
    public var leftZone: LayoutZone {
        zones.first ?? .leftHalf
    }

    /// The trailing (rightmost) layout zone for this ratio.
    public var rightZone: LayoutZone {
        zones.last ?? .rightHalf
    }
}
