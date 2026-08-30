import AppKit
import Combine

/// Handles macOS application lifecycle events that SwiftUI doesn't cover.
///
/// Responsibilities:
/// - Bootstrap core services on launch
/// - Register global hotkeys dynamically (US-SNAP-004, US-SNAP-010)
/// - Clean up system handlers on termination
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let dependencies = AppDependencies()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let dispatcher = dependencies.commandDispatcher
        let hotkeyManager = dependencies.hotkeyManager
        let preferences = dependencies.preferencesStore

        // Register custom hotkeys from PreferencesStore
        hotkeyManager.registerShortcuts(from: preferences) { command in
            Task { @MainActor in
                try? await dispatcher.dispatch(command)
            }
        }

        // Observe custom shortcut changes in PreferencesStore to re-register hotkeys dynamically
        preferences.$customShortcuts
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.dependencies.hotkeyManager.registerShortcuts(from: self.dependencies.preferencesStore) { command in
                    Task { @MainActor in
                        try? await dispatcher.dispatch(command)
                    }
                }
            }
            .store(in: &cancellables)

        // Start Drag-to-Snap observation
        dependencies.dragToSnapCoordinator.start()

        // Start Adaptive Multi-Window Divider observation
        dependencies.adaptiveDividerCoordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dependencies.hotkeyManager.unregisterAll()
        dependencies.dragToSnapCoordinator.stop()
        dependencies.adaptiveDividerCoordinator.stop()
        cancellables.removeAll()
    }
}
