import Foundation

/// Actions accessible directly from the FlowSnap Menu Bar interface.
///
/// Maps visual grid items to semantic snap targets and keyboard shortcut representations.
public enum MenuBarAction: String, Sendable, CaseIterable, Identifiable {
    // MARK: - Halves
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"

    // MARK: - Full & Restore
    case maximize = "Maximize"
    case restore = "Restore"

    // MARK: - Quarters
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"

    public var id: String { rawValue }

    /// Associated domain SnapTarget for this menu action.
    public var snapTarget: SnapTarget {
        switch self {
        case .leftHalf: return .left
        case .rightHalf: return .right
        case .topHalf: return .top
        case .bottomHalf: return .bottom
        case .maximize: return .maximize
        case .restore: return .restore
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return .bottomRight
        }
    }

    /// SF Symbol icon name representing the geometric layout.
    public var iconName: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.inset.filled"
        case .rightHalf: return "rectangle.righthalf.inset.filled"
        case .topHalf: return "rectangle.tophalf.inset.filled"
        case .bottomHalf: return "rectangle.bottomhalf.inset.filled"
        case .maximize: return "arrow.up.left.and.arrow.down.right.rectangle"
        case .restore: return "arrow.counterclockwise"
        case .topLeft: return "rectangle.inset.topleft.filled"
        case .topRight: return "rectangle.inset.topright.filled"
        case .bottomLeft: return "rectangle.inset.bottomleft.filled"
        case .bottomRight: return "rectangle.inset.bottomright.filled"
        }
    }

    /// User-friendly keyboard shortcut badge string.
    public var shortcutBadge: String {
        switch self {
        case .leftHalf: return "⌃⌥←"
        case .rightHalf: return "⌃⌥→"
        case .topHalf: return "⌃⌥↑"
        case .bottomHalf: return "⌃⌥↓"
        case .maximize: return "⌃⌥↑"
        case .restore: return "⌃⌥↓"
        case .topLeft: return "⌃⌥1"
        case .topRight: return "⌃⌥2"
        case .bottomLeft: return "⌃⌥3"
        case .bottomRight: return "⌃⌥4"
        }
    }
}
