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

        // Pause global hotkeys during shortcut recording in Settings so the recorder can capture any key combination
        preferences.$isRecordingShortcut
            .removeDuplicates()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] isRecording in
                guard let self = self else { return }
                if isRecording {
                    self.dependencies.hotkeyManager.unregisterAll()
                } else {
                    self.dependencies.hotkeyManager.registerShortcuts(from: self.dependencies.preferencesStore) { command in
                        Task { @MainActor in
                            try? await dispatcher.dispatch(command)
                        }
                    }
                }
            }
            .store(in: &cancellables)

        // Start Drag-to-Snap observation
        dependencies.dragToSnapCoordinator.start()

        // Start Adaptive Multi-Window Divider observation
        dependencies.adaptiveDividerCoordinator.start()

        // US-WORK-013: start launch + window-policy observation. The order
        // matters: `workspaceObserver` must be started before
        // `applicationObserver` so that the latter's `EventBus` subscription
        // to `.applicationLaunched` is wired up before any notification fires.
        dependencies.windowPolicyManager.prePopulateExistingWindows()
        dependencies.workspaceObserver.startObserving()
        dependencies.eventBus.subscribe(dependencies.windowPolicyManager) { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if case .activeSpaceChanged = event {
                    self.dependencies.windowPolicyManager.prePopulateExistingWindows()
                }
                await self.dependencies.windowPolicyManager.handle(event: event)
            }
        }
        if let observer = dependencies.applicationObserver as? AnyObject {
            dependencies.eventBus.subscribe(observer) { [weak self] event in
                guard case .applicationLaunched(let pid, let bundleID) = event else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.dependencies.applicationObserver.observe(pid: pid, bundleID: bundleID)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        dependencies.hotkeyManager.unregisterAll()
        dependencies.dragToSnapCoordinator.stop()
        dependencies.adaptiveDividerCoordinator.stop()
        dependencies.workspaceObserver.stopObserving()
        dependencies.displayHotPlugObserver.stopObserving()
        dependencies.eventBus.unsubscribe(dependencies.windowPolicyManager)
        cancellables.removeAll()
    }
}
