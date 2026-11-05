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
        let hotkeyManager = dependencies.hotkeyManager
        let preferences = dependencies.preferencesStore

        // Every snap, throw and restore is an AX write, so an app that never
        // asks is an app whose hotkeys do nothing forever. macOS rate-limits
        // the dialog itself; asking on every untrusted launch is what makes
        // first-run recoverable.
        if !dependencies.accessibilityService.isTrusted {
            dependencies.accessibilityService.promptForTrust()
        }

        // Register custom hotkeys from PreferencesStore
        hotkeyManager.registerShortcuts(from: preferences) { [weak self] command in
            Task { @MainActor in
                await self?.run(command)
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
                        await self.run(command)
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
                            await self.run(command)
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

    /// Runs a command raised by a global hotkey and reports why it could not run.
    private func run(_ command: WindowCommand) async {
        do {
            try await dependencies.commandDispatcher.dispatch(command)
        } catch {
            dependencies.menuBarViewModel.reportActionFailure(error)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        dependencies.menuBarViewModel.stopPermissionPolling()
        dependencies.hotkeyManager.unregisterAll()
        dependencies.dragToSnapCoordinator.stop()
        dependencies.adaptiveDividerCoordinator.stop()
        dependencies.workspaceObserver.stopObserving()
        dependencies.displayHotPlugObserver.stopObserving()
        dependencies.eventBus.unsubscribe(dependencies.windowPolicyManager)
        cancellables.removeAll()
    }
}
