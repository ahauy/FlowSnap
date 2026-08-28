import Carbon
import CoreGraphics
import Foundation

// MARK: - Hotkey Contracts (US-SNAP-004)

/// Value object representing a physical key code and Carbon modifier mask.
public struct KeyboardShortcutContract: Hashable, Codable, Sendable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    /// Formatted glyph string (e.g. "⌃⌥←", "⌃⌥1").
    public var displayString: String {
        var result = ""
        if carbonModifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { result += "⌘" }

        switch keyCode {
        case 123: result += "←" // kVK_LeftArrow
        case 124: result += "→" // kVK_RightArrow
        case 125: result += "↓" // kVK_DownArrow
        case 126: result += "↑" // kVK_UpArrow
        case 18: result += "1"  // kVK_ANSI_1
        case 19: result += "2"  // kVK_ANSI_2
        case 20: result += "3"  // kVK_ANSI_3
        case 21: result += "4"  // kVK_ANSI_4
        default: result += "[\(keyCode)]"
        }
        return result
    }
}

/// Identifiable binding pairing a shortcut with a semantic command.
public struct HotkeyBindingContract: Identifiable, Hashable, Sendable {
    public let id: UInt32
    public let shortcut: KeyboardShortcutContract
    public let command: WindowCommand
    public let isRegistered: Bool

    public init(
        id: UInt32,
        shortcut: KeyboardShortcutContract,
        command: WindowCommand,
        isRegistered: Bool = false
    ) {
        self.id = id
        self.shortcut = shortcut
        self.command = command
        self.isRegistered = isRegistered
    }
}

/// Abstract protocol for global system-wide hotkey management.
public protocol GlobalHotkeyManagingContract: AnyObject, Sendable {
    /// Registers a single hotkey binding with action handler.
    func register(_ binding: HotkeyBindingContract, action: @escaping @Sendable (WindowCommand) -> Void) -> Bool

    /// Registers the standard FlowSnap default 8 hotkeys.
    func registerDefaultHotkeys(action: @escaping @Sendable (WindowCommand) -> Void) -> [HotkeyBindingContract]

    /// Unregisters all registered hotkeys from the system.
    func unregisterAll()

    /// Returns currently tracked bindings and registration status.
    var activeBindings: [HotkeyBindingContract] { get }
}

/// Protocol for asynchronous window command routing.
public protocol CommandDispatchingContract: Sendable {
    func dispatch(_ command: WindowCommand) async throws
}
