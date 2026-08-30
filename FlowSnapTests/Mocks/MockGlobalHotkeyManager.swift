import Foundation
@testable import FlowSnap

/// Test double implementing GlobalHotkeyManaging for unit tests without hitting Carbon APIs.
public final class MockGlobalHotkeyManager: GlobalHotkeyManaging, @unchecked Sendable {

    private let lock = NSLock()
    private var bindings: [HotkeyBinding] = []
    private var actionHandler: (@Sendable (WindowCommand) -> Void)?

    /// IDs that should simulate a registration collision failure.
    public var collidingIDs: Set<UInt32> = []

    public var registerCallCount = 0
    public var unregisterAllCallCount = 0

    public init() {}

    public var activeBindings: [HotkeyBinding] {
        lock.withLock { bindings }
    }

    @discardableResult
    public func register(
        _ binding: HotkeyBinding,
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> Bool {
        lock.withLock {
            registerCallCount += 1
            self.actionHandler = action

            bindings.removeAll { $0.id == binding.id }

            if collidingIDs.contains(binding.id) {
                bindings.append(binding.withRegistrationStatus(false))
                return false
            } else {
                bindings.append(binding.withRegistrationStatus(true))
                return true
            }
        }
    }

    @discardableResult
    public func registerDefaultHotkeys(
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> [HotkeyBinding] {
        let defaultShortcuts: [(UInt32, Int, Int, WindowCommand)] = [
            (1, 123, 0x1800, .snap(.zone(.leftHalf))),
            (2, 124, 0x1800, .snap(.zone(.rightHalf))),
            (3, 126, 0x1800, .maximize),
            (4, 125, 0x1800, .restore),
            (5, 18, 0x1800, .snap(.zone(.topLeft))),
            (6, 19, 0x1800, .snap(.zone(.topRight))),
            (7, 20, 0x1800, .snap(.zone(.bottomLeft))),
            (8, 21, 0x1800, .snap(.zone(.bottomRight)))
        ]

        var result: [HotkeyBinding] = []
        for (id, keyCode, modifiers, command) in defaultShortcuts {
            let shortcut = KeyboardShortcut(keyCode: keyCode, carbonModifiers: modifiers)
            let binding = HotkeyBinding(id: id, shortcut: shortcut, command: command)
            register(binding, action: action)
            if let active = activeBindings.first(where: { $0.id == id }) {
                result.append(active)
            }
        }
        return result
    }

    @MainActor
    @discardableResult
    public func registerShortcuts(
        from preferencesStore: PreferencesStore,
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> [HotkeyBinding] {
        unregisterAll()
        var idCounter: UInt32 = 1
        var result: [HotkeyBinding] = []

        for actionType in ShortcutAction.allCases {
            guard let shortcut = preferencesStore.shortcut(for: actionType) else {
                continue
            }
            let binding = HotkeyBinding(
                id: idCounter,
                shortcut: shortcut,
                command: actionType.defaultCommand
            )
            register(binding, action: action)
            if let active = activeBindings.first(where: { $0.id == idCounter }) {
                result.append(active)
            }
            idCounter += 1
        }
        return result
    }

    public func unregisterAll() {
        lock.withLock {
            unregisterAllCallCount += 1
            bindings.removeAll()
        }
    }

    /// Simulates a hotkey press from system.
    public func simulateHotKeyTrigger(id: UInt32) {
        let (command, handler): (WindowCommand?, (@Sendable (WindowCommand) -> Void)?) = lock.withLock {
            let cmd = bindings.first(where: { $0.id == id })?.command
            return (cmd, actionHandler)
        }
        if let command = command, let handler = handler {
            handler(command)
        }
    }
}
