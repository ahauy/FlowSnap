import Foundation

/// Where a window should snap to.
///
/// Used by SnapEngine to determine the target zone,
/// then passed to LayoutEngine to compute the actual frame.
/// See spec §31.
public enum SnapTarget: Hashable, Sendable, Codable {
    // MARK: - Standard Zone Target
    case zone(LayoutZone)

    // MARK: - Restore Action
    case restore

    // MARK: - Custom Layout
    case layout(Layout)

    // MARK: - Convenience Shorthands (Half Screen)
    public static let left = SnapTarget.zone(.leftHalf)
    public static let right = SnapTarget.zone(.rightHalf)
    public static let top = SnapTarget.zone(.topHalf)
    public static let bottom = SnapTarget.zone(.bottomHalf)

    public static let leftHalf = SnapTarget.left
    public static let rightHalf = SnapTarget.right
    public static let topHalf = SnapTarget.top
    public static let bottomHalf = SnapTarget.bottom

    // MARK: - Convenience Shorthands (Quarter Screen)
    public static let topLeft = SnapTarget.zone(.topLeft)
    public static let topRight = SnapTarget.zone(.topRight)
    public static let bottomLeft = SnapTarget.zone(.bottomLeft)
    public static let bottomRight = SnapTarget.zone(.bottomRight)

    // MARK: - Convenience Shorthands (Full Screen)
    public static let maximize = SnapTarget.zone(.maximize)

    /// Returns the associated LayoutZone if this target targets a standard zone.
    public var zone: LayoutZone? {
        if case .zone(let z) = self {
            return z
        }
        return nil
    }
}
