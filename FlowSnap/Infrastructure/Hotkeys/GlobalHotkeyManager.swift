import Carbon
import Foundation

/// Concrete hotkey manager using Carbon Event APIs.
///
/// Wraps Carbon's RegisterEventHotKey for global hotkey support.
/// May be replaced with KeyboardShortcuts package (Sindre Sorhus)
/// in a future iteration. See spec §34.
final class GlobalHotkeyManager: GlobalHotkeyManaging {

    private var registeredHotkeys: [KeyboardShortcut: EventHotKeyRef] = [:]

    func register(_ shortcut: KeyboardShortcut, action: @escaping () -> Void) {
        // TODO: Use Carbon RegisterEventHotKey or KeyboardShortcuts package
    }

    func unregisterAll() {
        // TODO: Unregister all Carbon hotkeys
        registeredHotkeys.removeAll()
    }

    deinit {
        unregisterAll()
    }
}
