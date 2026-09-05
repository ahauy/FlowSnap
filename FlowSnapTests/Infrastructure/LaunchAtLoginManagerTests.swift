import AppKit
import Foundation
import Testing
@testable import FlowSnap

/// Tests for Launch at Login integration via SMAppService and PreferencesStore (US-SNAP-024).
///
/// Traces to:
/// - BR-LAL-001: System Single Source-of-Truth
/// - BR-LAL-002: Explicit Intent Toggle
/// - BR-LAL-003: Clean Deregistration
/// - BR-LAL-004: Two-Way Synchronization
/// - BR-LAL-005: Approval Required Affordance
/// - BR-LAL-006: Zero Crash in Development
@MainActor
struct LaunchAtLoginManagerTests {

    private func freshDefaults() -> UserDefaults {
        let suiteName = "test-lal-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Failed to create UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeStore(
        defaults: UserDefaults? = nil,
        manager: MockLaunchAtLoginManager
    ) -> PreferencesStore {
        PreferencesStore(defaults: defaults ?? freshDefaults(), launchAtLoginManager: manager)
    }

    @Test func TC_LAL_001_initialStatusEnabled() {
        let mock = MockLaunchAtLoginManager(status: .enabled)
        let store = makeStore(manager: mock)

        #expect(store.launchAtLogin == true)
        #expect(store.launchAtLoginStatus == .enabled)
    }

    @Test func TC_LAL_002_initialStatusNotRegistered() {
        let mock = MockLaunchAtLoginManager(status: .notRegistered)
        let store = makeStore(manager: mock)

        #expect(store.launchAtLogin == false)
        #expect(store.launchAtLoginStatus == .notRegistered)
    }

    @Test func TC_LAL_003_toggleOnRegistersApp() {
        let mock = MockLaunchAtLoginManager(status: .notRegistered)
        let store = makeStore(manager: mock)

        store.setLaunchAtLogin(true)

        #expect(mock.registerCallCount == 1)
        #expect(store.launchAtLogin == true)
        #expect(store.launchAtLoginStatus == .enabled)
    }

    @Test func TC_LAL_004_toggleOffUnregistersApp() {
        let mock = MockLaunchAtLoginManager(status: .enabled)
        let store = makeStore(manager: mock)

        store.setLaunchAtLogin(false)

        #expect(mock.unregisterCallCount == 1)
        #expect(store.launchAtLogin == false)
        #expect(store.launchAtLoginStatus == .notRegistered)
    }

    @Test func TC_LAL_005_registrationFailureRevertsState() {
        let mock = MockLaunchAtLoginManager(status: .notRegistered)
        mock.registerError = NSError(domain: "com.flowsnap.test", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Simulated registration failure"
        ])
        let store = makeStore(manager: mock)

        store.setLaunchAtLogin(true)

        #expect(store.launchAtLogin == false)
        #expect(store.launchAtLoginStatus == .error("Simulated registration failure"))
    }

    @Test func TC_LAL_006_twoWaySyncOnAppActive() {
        let mock = MockLaunchAtLoginManager(status: .enabled)
        let store = makeStore(manager: mock)
        #expect(store.launchAtLogin == true)

        // Simulate external state change (e.g. user toggled in macOS System Settings)
        mock.status = .notRegistered
        NotificationCenter.default.post(name: NSApplication.didBecomeActiveNotification, object: nil)

        #expect(store.launchAtLogin == false)
        #expect(store.launchAtLoginStatus == .notRegistered)
    }

    @Test func TC_LAL_007_requiresApprovalAndOpenSettings() {
        let mock = MockLaunchAtLoginManager(status: .requiresApproval)
        let store = makeStore(manager: mock)

        #expect(store.launchAtLoginStatus.requiresUserApproval == true)

        store.openSystemLoginItemsSettings()
        #expect(mock.openSystemSettingsCallCount == 1)
    }

    @Test func TC_LAL_008_explicitRefreshStatus() {
        let mock = MockLaunchAtLoginManager(status: .notRegistered)
        let store = makeStore(manager: mock)
        #expect(store.launchAtLogin == false)

        mock.status = .enabled
        store.refreshLaunchAtLoginStatus()

        #expect(store.launchAtLogin == true)
        #expect(store.launchAtLoginStatus == .enabled)
    }
}
