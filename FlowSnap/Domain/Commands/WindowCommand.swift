import CoreGraphics
import Foundation

/// All commands that can be dispatched through FlowSnap.
///
/// Every input source (hotkey, menu bar, automation) produces
/// a WindowCommand that flows through CommandDispatcher.
/// See spec §35.
public enum WindowCommand: Hashable, Sendable {
    // MARK: - Snap

    case snap(SnapTarget, targetDisplayID: CGDirectDisplayID? = nil)

    // MARK: - Window Actions

    case maximize
    case restore
    case minimize

    // MARK: - Display

    case moveToDisplay(CGDirectDisplayID)
    case moveToNextDisplay
    case moveToPreviousDisplay

    // MARK: - Workspace
    case restoreWorkspace(UUID)
    case saveWorkspace(String)
    case migrateWorkspace(MigrationDirection)

    // MARK: - Presets (US-WORK-012)
    case restorePreset(String) // Preset ID, e.g. "builtin.coding"
}
