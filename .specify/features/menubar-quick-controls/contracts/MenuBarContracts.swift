import Foundation
import SwiftUI

// MARK: - MenuBar Contracts

/// Protocol defining the capability of managing the Menu Bar Status Item.
@MainActor
public protocol MenuBarManaging: AnyObject, Sendable {
    /// True if the menu or popover is currently presented on screen.
    var isMenuVisible: Bool { get }
    
    /// Sets up the status item in the system menu bar.
    func setupStatusItem()
    
    /// Programmatically triggers dismissal of the status item popover/menu.
    func dismissMenu()
}

/// Actions accessible directly from the Menu Bar Quick Controls interface.
public enum MenuBarAction: String, Sendable, CaseIterable, Identifiable {
    case snapLeft = "Snap Left"
    case snapRight = "Snap Right"
    case snapTop = "Snap Top"
    case snapBottom = "Snap Bottom"
    case maximize = "Maximize"
    case restore = "Restore"
    case snapTopLeft = "Top Left"
    case snapTopRight = "Top Right"
    case snapBottomLeft = "Bottom Left"
    case snapBottomRight = "Bottom Right"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .snapLeft: return "rectangle.righthalf.inset.filled" // System images or custom SF Symbols
        case .snapRight: return "rectangle.lefthalf.inset.filled"
        case .snapTop: return "rectangle.tophalf.inset.filled"
        case .snapBottom: return "rectangle.bottomhalf.inset.filled"
        case .maximize: return "arrow.up.left.and.arrow.down.right.rectangle"
        case .restore: return "arrow.counterclockwise.rectangle"
        case .snapTopLeft: return "rectangle.inset.topleft.filled"
        case .snapTopRight: return "rectangle.inset.topright.filled"
        case .snapBottomLeft: return "rectangle.inset.bottomleft.filled"
        case .snapBottomRight: return "rectangle.inset.bottomright.filled"
        }
    }
    
    public var shortcutHint: String {
        switch self {
        case .snapLeft: return "⌃⌥←"
        case .snapRight: return "⌃⌥→"
        case .snapTop: return "⌃⌥↑"
        case .snapBottom: return "⌃⌥↓"
        case .maximize: return "⌃⌥↩"
        case .restore: return "⌃⌥⌫"
        case .snapTopLeft: return "⌃⌥1"
        case .snapTopRight: return "⌃⌥2"
        case .snapBottomLeft: return "⌃⌥3"
        case .snapBottomRight: return "⌃⌥4"
        }
    }
}
