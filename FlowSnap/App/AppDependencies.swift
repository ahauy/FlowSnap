import Foundation

/// Dependency injection container for FlowSnap services.
///
/// Centralizes creation and wiring of all core services.
/// Protocols allow swapping implementations for testing.
@MainActor
final class AppDependencies {

    // MARK: - Infrastructure

    // TODO: lazy var accessibilityService: AccessibilityService
    // TODO: lazy var displayManager: DisplayManaging
    // TODO: lazy var hotkeyManager: GlobalHotkeyManaging

    // MARK: - Core

    // TODO: lazy var windowRegistry: WindowRegistry
    // TODO: lazy var windowManager: WindowManaging
    // TODO: lazy var layoutEngine: LayoutCalculating
    // TODO: lazy var snapEngine: SnapEngine
    // TODO: lazy var commandDispatcher: CommandDispatcher
    // TODO: lazy var windowPolicyManager: WindowPolicyManager
    // TODO: lazy var workspaceManager: WorkspaceManager
    // TODO: lazy var eventBus: EventBus

    // MARK: - Persistence

    // TODO: lazy var preferencesStore: PreferencesStore
    // TODO: lazy var workspaceStore: WorkspaceStore
}
