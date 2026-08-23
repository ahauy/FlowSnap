import Foundation

/// Where a window should snap to.
///
/// Used by SnapEngine to determine the target zone,
/// then passed to LayoutEngine to compute the actual frame.
/// See spec §31.
enum SnapTarget: Hashable {
    // MARK: - Half Screen

    case left
    case right
    case top
    case bottom

    // MARK: - Quarter Screen

    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    // MARK: - Full

    case maximize

    // MARK: - Custom Layout

    case layout(Layout)
}
