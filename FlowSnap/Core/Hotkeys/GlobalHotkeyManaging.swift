import Foundation

/// Abstraction for global system-wide keyboard shortcut registration.
///
/// Dispatches `WindowCommand` payloads through a thread-safe callback.
/// See spec §34, US-SNAP-010.
public protocol GlobalHotkeyManaging: AnyObject, Sendable {
    /// Register a single hotkey binding with an action callback.
    /// Returns true if registration succeeded, false if collision occurred.
    @discardableResult
    func register(_ binding: HotkeyBinding, action: @escaping @Sendable (WindowCommand) -> Void) -> Bool

    /// Registers the standard FlowSnap default 8 hotkeys.
    /// (⌃⌥←, ⌃⌥→, ⌃⌥↑, ⌃⌥↓, ⌃⌥1..4).
    @discardableResult
    func registerDefaultHotkeys(action: @escaping @Sendable (WindowCommand) -> Void) -> [HotkeyBinding]

    /// Registers all active shortcuts from the PreferencesStore (customized + fallback defaults).
    @MainActor
    @discardableResult
    func registerShortcuts(
        from preferencesStore: PreferencesStore,
        action: @escaping @Sendable (WindowCommand) -> Void
    ) -> [HotkeyBinding]

    /// Unregister all active hotkeys from the system.
    func unregisterAll()

    /// Currently tracked bindings and their registration status.
    var activeBindings: [HotkeyBinding] { get }
}
