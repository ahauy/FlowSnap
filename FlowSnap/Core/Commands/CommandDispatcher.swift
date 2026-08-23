import Foundation

/// Central command router for all FlowSnap actions.
///
/// All input sources (hotkey, menu bar, automation) produce
/// WindowCommands that flow through this dispatcher.
/// See spec §35.
///
/// Flow:
/// ```
/// Keyboard / Menu Bar / Automation
///        ↓
///    WindowCommand
///        ↓
///    CommandDispatcher
///        ↓
///    SnapEngine / WorkspaceManager / WindowManager
/// ```
@MainActor
final class CommandDispatcher {

    private let windowManager: WindowManaging
    private let snapEngine: SnapEngine
    private let displayManager: DisplayManaging

    init(
        windowManager: WindowManaging,
        snapEngine: SnapEngine,
        displayManager: DisplayManaging
    ) {
        self.windowManager = windowManager
        self.snapEngine = snapEngine
        self.displayManager = displayManager
    }

    /// Dispatch a command for execution.
    func dispatch(_ command: WindowCommand) async throws {
        // TODO: Route command to appropriate service
        // TODO: Get focused window, determine display, calculate frame, move
    }
}
