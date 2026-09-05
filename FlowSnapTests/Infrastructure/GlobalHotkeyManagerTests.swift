import Carbon
import Foundation
import Testing
@testable import FlowSnap

private final class TestBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T?

    init(_ initial: T? = nil) {
        self._value = initial
    }

    var value: T? {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

/// Tests for GlobalHotkeyManager and hotkey registration lifecycle.
///
/// Traces to: US-SNAP-004.1 & TC-HOTKEY-005..007.
struct GlobalHotkeyManagerTests {

    @Test func defaultHotkeysRegistrationTracking() {
        let mockManager = MockGlobalHotkeyManager()
        let triggered = TestBox<WindowCommand>()

        let registered = mockManager.registerDefaultHotkeys { command in
            triggered.value = command
        }

        #expect(registered.count == 8)
        #expect(mockManager.activeBindings.count == 8)
        #expect(mockManager.activeBindings.allSatisfy { $0.isRegistered })

        // Simulate trigger
        mockManager.simulateHotKeyTrigger(id: 1)
        #expect(triggered.value == .snap(.zone(.leftHalf)))
    }

    @Test func collisionToleranceGracefulSkip() {
        let mockManager = MockGlobalHotkeyManager()
        // Simulate that ID: 1 (Left Half) has a collision error from another app
        mockManager.collidingIDs.insert(1)

        let registered = mockManager.registerDefaultHotkeys { _ in }

        #expect(registered.count == 8)
        let leftBinding = registered.first(where: { $0.id == 1 })
        #expect(leftBinding?.isRegistered == false)

        let rightBinding = registered.first(where: { $0.id == 2 })
        #expect(rightBinding?.isRegistered == true)
    }

    @Test func unregisterAllReleasesAllBindings() {
        let mockManager = MockGlobalHotkeyManager()
        mockManager.registerDefaultHotkeys { _ in }
        #expect(mockManager.activeBindings.count == 8)

        mockManager.unregisterAll()
        #expect(mockManager.activeBindings.isEmpty)
        #expect(mockManager.unregisterAllCallCount == 1)
    }

    @Test func carbonManagerRegistrationLifecycle() {
        // Test real GlobalHotkeyManager lifecycle without crashing
        let manager = GlobalHotkeyManager()
        let triggered = TestBox<WindowCommand>()

        let list = manager.registerDefaultHotkeys { command in
            triggered.value = command
        }

        #expect(list.count == 8)
        #expect(manager.activeBindings.count == 8)

        manager.unregisterAll()
        #expect(manager.activeBindings.isEmpty)
    }

    @MainActor
    @Test func sharedGroupAndWorkspaceShortcutRegistration() {
        let defaults = UserDefaults(suiteName: "test.globalhotkey.shared.\(UUID().uuidString)")!
        let store = PreferencesStore(defaults: defaults)

        // Set identical shortcut for moveWorkspaceNextDisplay and moveGroupNextDisplay
        let sharedNext = KeyboardShortcut(keyCode: 124, carbonModifiers: UInt32(controlKey | optionKey | cmdKey)) // ⌃⌥⌘→
        store.setShortcut(sharedNext, for: .moveWorkspaceNextDisplay)
        store.setShortcut(sharedNext, for: .moveGroupNextDisplay)

        let mockManager = MockGlobalHotkeyManager()
        let registered = mockManager.registerShortcuts(from: store) { _ in }

        // Confirm only ONE binding was registered for the shared shortcut, mapped to .moveGroupOrWorkspaceToNextDisplay
        let sharedBindings = registered.filter { $0.shortcut == sharedNext }
        #expect(sharedBindings.count == 1)
        #expect(sharedBindings.first?.command == .moveGroupOrWorkspaceToNextDisplay)
    }
}
