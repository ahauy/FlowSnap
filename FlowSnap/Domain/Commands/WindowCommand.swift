import CoreGraphics
import Foundation

/// All commands that can be dispatched through FlowSnap.
///
/// Every input source (hotkey, menu bar, automation) produces
/// a WindowCommand that flows through CommandDispatcher.
/// See spec §35.
enum WindowCommand {
    // MARK: - Snap

    case snap(SnapTarget)

    // MARK: - Window Actions

    case maximize
    case restore
    case minimize

    // MARK: - Display

    case moveToDisplay(CGDirectDisplayID)

    // MARK: - Workspace

    case restoreWorkspace(UUID)
    case saveWorkspace(String)
}
