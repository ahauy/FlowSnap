import AppKit

/// Handles macOS application lifecycle events that SwiftUI doesn't cover.
///
/// Responsibilities:
/// - Bootstrap core services on launch
/// - Register global hotkeys (US-SNAP-004)
/// - Clean up system handlers on termination
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    let dependencies = AppDependencies()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let dispatcher = dependencies.commandDispatcher

        // Register global hotkeys to dispatch commands via CommandDispatcher
        dependencies.hotkeyManager.registerDefaultHotkeys { command in
            Task { @MainActor in
                try? await dispatcher.dispatch(command)
            }
        }

        // Start Drag-to-Snap observation
        dependencies.dragToSnapCoordinator.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dependencies.hotkeyManager.unregisterAll()
        dependencies.dragToSnapCoordinator.stop()
    }
}
