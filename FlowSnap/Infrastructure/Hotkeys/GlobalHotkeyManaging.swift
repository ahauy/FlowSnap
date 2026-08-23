import Foundation

/// Abstraction for global keyboard shortcut registration.
///
/// Hotkeys go through CommandDispatcher — they never
/// call WindowManager directly. See spec §34.
///
/// Flow:
/// ```
/// GlobalHotkeyManager → HotkeyAction → CommandDispatcher
/// ```
protocol GlobalHotkeyManaging {
    /// Register a keyboard shortcut with an associated action.
    func register(_ shortcut: KeyboardShortcut, action: @escaping () -> Void)

    /// Remove all registered shortcuts.
    func unregisterAll()
}

/// Represents a keyboard shortcut combination.
struct KeyboardShortcut: Hashable, Codable {
    let keyCode: UInt16
    let modifiers: UInt

    /// Human-readable description (e.g., "⌃⌥←").
    var displayString: String {
        // TODO: Format modifier flags + key code
        ""
    }
}
