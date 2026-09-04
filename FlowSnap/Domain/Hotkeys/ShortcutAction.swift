import Carbon
import Foundation

/// Taxonomic category for grouping shortcut actions in the Settings UI.
public enum ShortcutCategory: String, CaseIterable, Identifiable, Sendable {
    case halvesAndMaximize = "Halves & Maximize"
    case quarters = "Quarter Screens"
    case asymmetric = "Asymmetric & Thirds"
    case displays = "Display Navigation"
    case pinning = "Window Pinning"

    public var id: String { rawValue }
}

/// Canonical identifier for all user-configurable window and layout commands.
///
/// See spec §8, §34 and ADR-0005.
public enum ShortcutAction: String, CaseIterable, Codable, Sendable, Identifiable {
    // MARK: - Halves & Maximize
    case leftHalf = "leftHalf"
    case rightHalf = "rightHalf"
    case topHalf = "topHalf"
    case bottomHalf = "bottomHalf"
    case maximize = "maximize"
    case restore = "restore"

    // MARK: - Quarters
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"

    // MARK: - Asymmetric & Thirds
    case left70_30 = "left70_30"
    case rightOneThird = "rightOneThird"
    case leftThird = "leftThird"
    case centerThird = "centerThird"
    case rightThird = "rightThird"

    // MARK: - Displays
    case nextDisplay = "nextDisplay"
    case previousDisplay = "previousDisplay"
    case moveWorkspaceNextDisplay = "moveWorkspaceNextDisplay"
    case moveWorkspacePreviousDisplay = "moveWorkspacePreviousDisplay"

    // MARK: - Pinning (US-SNAP-021)
    case togglePinFocusedWindow = "togglePinFocusedWindow"

    public var id: String { rawValue }

    /// Human-readable display label in Settings.
    public var displayName: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .maximize: return "Maximize"
        case .restore: return "Restore / Center"
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        case .left70_30: return "Left 70% / 2/3"
        case .rightOneThird: return "Right 30% / 1/3"
        case .leftThird: return "Left 1/3"
        case .centerThird: return "Center 1/3"
        case .rightThird: return "Right 1/3"
        case .nextDisplay: return "Move to Next Display"
        case .previousDisplay: return "Move to Previous Display"
        case .moveWorkspaceNextDisplay: return "Move Workspace to Next Display"
        case .moveWorkspacePreviousDisplay: return "Move Workspace to Previous Display"
        case .togglePinFocusedWindow: return "Pin / Unpin Window"
        }
    }

    /// Section category for UI organization.
    public var category: ShortcutCategory {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf, .maximize, .restore:
            return .halvesAndMaximize
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return .quarters
        case .left70_30, .rightOneThird, .leftThird, .centerThird, .rightThird:
            return .asymmetric
        case .nextDisplay, .previousDisplay, .moveWorkspaceNextDisplay, .moveWorkspacePreviousDisplay:
            return .displays
        case .togglePinFocusedWindow:
            return .pinning
        }
    }

    /// Default out-of-the-box shortcut if not customized by the user.
    public var defaultShortcut: KeyboardShortcut? {
        let ctrlOpt = UInt32(controlKey | optionKey)
        let ctrlOptShift = UInt32(controlKey | optionKey | shiftKey)

        switch self {
        case .leftHalf:
            return KeyboardShortcut(keyCode: 123, carbonModifiers: ctrlOpt) // ⌃⌥←
        case .rightHalf:
            return KeyboardShortcut(keyCode: 124, carbonModifiers: ctrlOpt) // ⌃⌥→
        case .maximize:
            return KeyboardShortcut(keyCode: 126, carbonModifiers: ctrlOpt) // ⌃⌥↑
        case .restore:
            return KeyboardShortcut(keyCode: 125, carbonModifiers: ctrlOpt) // ⌃⌥↓
        case .topLeft:
            return KeyboardShortcut(keyCode: 18, carbonModifiers: ctrlOpt)  // ⌃⌥1
        case .topRight:
            return KeyboardShortcut(keyCode: 19, carbonModifiers: ctrlOpt)  // ⌃⌥2
        case .bottomLeft:
            return KeyboardShortcut(keyCode: 20, carbonModifiers: ctrlOpt)  // ⌃⌥3
        case .bottomRight:
            return KeyboardShortcut(keyCode: 21, carbonModifiers: ctrlOpt)  // ⌃⌥4
        case .topHalf:
            return KeyboardShortcut(keyCode: 126, carbonModifiers: ctrlOptShift) // ⌃⌥⇧↑
        case .bottomHalf:
            return KeyboardShortcut(keyCode: 125, carbonModifiers: ctrlOptShift) // ⌃⌥⇧↓
        case .left70_30:
            return KeyboardShortcut(keyCode: 18, carbonModifiers: ctrlOptShift)  // ⌃⌥⇧1
        case .rightOneThird:
            return KeyboardShortcut(keyCode: 19, carbonModifiers: ctrlOptShift)  // ⌃⌥⇧2
        case .leftThird:
            return KeyboardShortcut(keyCode: 20, carbonModifiers: ctrlOptShift)  // ⌃⌥⇧3
        case .centerThird:
            return KeyboardShortcut(keyCode: 21, carbonModifiers: ctrlOptShift)  // ⌃⌥⇧4
        case .rightThird:
            return KeyboardShortcut(keyCode: 23, carbonModifiers: ctrlOptShift)  // ⌃⌥⇧5
        case .nextDisplay:
            return KeyboardShortcut(keyCode: 124, carbonModifiers: ctrlOptShift) // ⌃⌥⇧→
        case .previousDisplay:
            return KeyboardShortcut(keyCode: 123, carbonModifiers: ctrlOptShift) // ⌃⌥⇧←
        case .moveWorkspaceNextDisplay:
            let ctrlOptShiftCmd = UInt32(controlKey | optionKey | shiftKey | cmdKey)
            return KeyboardShortcut(keyCode: 124, carbonModifiers: ctrlOptShiftCmd) // ⌃⌥⇧⌘→
        case .moveWorkspacePreviousDisplay:
            let ctrlOptShiftCmd = UInt32(controlKey | optionKey | shiftKey | cmdKey)
            return KeyboardShortcut(keyCode: 123, carbonModifiers: ctrlOptShiftCmd) // ⌃⌥⇧⌘←
        case .togglePinFocusedWindow:
            return KeyboardShortcut(keyCode: 35, carbonModifiers: ctrlOpt) // ⌃⌥P (kVK_ANSI_P = 35)
        }
    }

    /// Corresponding default WindowCommand mapped to this action.
    public var defaultCommand: WindowCommand {
        switch self {
        case .leftHalf: return .snap(.zone(.leftHalf))
        case .rightHalf: return .snap(.zone(.rightHalf))
        case .topHalf: return .snap(.zone(.topHalf))
        case .bottomHalf: return .snap(.zone(.bottomHalf))
        case .maximize: return .maximize
        case .restore: return .restore
        case .topLeft: return .snap(.zone(.topLeft))
        case .topRight: return .snap(.zone(.topRight))
        case .bottomLeft: return .snap(.zone(.bottomLeft))
        case .bottomRight: return .snap(.zone(.bottomRight))
        case .left70_30: return .snap(.zone(.left70_30))
        case .rightOneThird: return .snap(.zone(.rightOneThird))
        case .leftThird: return .snap(.zone(.leftThird))
        case .centerThird: return .snap(.zone(.centerThird))
        case .rightThird: return .snap(.zone(.rightThird))
        case .nextDisplay: return .moveToNextDisplay
        case .previousDisplay: return .moveToPreviousDisplay
        case .moveWorkspaceNextDisplay: return .migrateWorkspace(.next)
        case .moveWorkspacePreviousDisplay: return .migrateWorkspace(.previous)
        case .togglePinFocusedWindow: return .togglePinFocusedWindow
        }
    }
}
