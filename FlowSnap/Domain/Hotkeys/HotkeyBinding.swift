import Foundation

/// Entity binding a physical KeyboardShortcut to a domain WindowCommand.
///
/// Tracks system registration state. See spec §34.
public struct HotkeyBinding: Identifiable, Hashable, Sendable {
    public let id: UInt32
    public let shortcut: KeyboardShortcut
    public let command: WindowCommand
    public let isRegistered: Bool

    public init(
        id: UInt32,
        shortcut: KeyboardShortcut,
        command: WindowCommand,
        isRegistered: Bool = false
    ) {
        self.id = id
        self.shortcut = shortcut
        self.command = command
        self.isRegistered = isRegistered
    }

    /// Returns a copy with updated registration status.
    public func withRegistrationStatus(_ registered: Bool) -> HotkeyBinding {
        HotkeyBinding(id: id, shortcut: shortcut, command: command, isRegistered: registered)
    }
}
