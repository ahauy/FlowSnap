import Foundation

/// Manages workspace save, restore, and preset operations.
///
/// See spec §38.
@MainActor
final class WorkspaceManager {

    private let windowManager: WindowManaging
    private let layoutEngine: LayoutCalculating
    private let workspaceStore: WorkspaceStore

    init(
        windowManager: WindowManaging,
        layoutEngine: LayoutCalculating,
        workspaceStore: WorkspaceStore
    ) {
        self.windowManager = windowManager
        self.layoutEngine = layoutEngine
        self.workspaceStore = workspaceStore
    }

    /// Save the current window arrangement as a named workspace.
    func saveCurrent(name: String) async throws {
        // TODO: Capture current window positions, create Workspace, persist
    }

    /// Restore a previously saved workspace.
    func restore(_ workspace: Workspace) async throws {
        // TODO: Find matching windows by bundleIdentifier, apply placements
    }
}
