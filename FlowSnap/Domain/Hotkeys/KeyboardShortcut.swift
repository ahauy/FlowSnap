import AppKit
import Carbon
import Foundation

/// Value object representing a physical key combination and Carbon modifier mask.
///
/// Immutable, Codable, and Sendable. See spec §34 and ADR-0005.
public struct KeyboardShortcut: Hashable, Codable, Sendable {
    public let keyCode: UInt32
    public let carbonModifiers: UInt32

    public init(keyCode: UInt32, carbonModifiers: UInt32) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }

    /// Convenience initializer using standard Carbon Virtual Keycodes and modifiers.
    public init(keyCode: Int, carbonModifiers: Int) {
        self.keyCode = UInt32(keyCode)
        self.carbonModifiers = UInt32(carbonModifiers)
    }

    /// Converts NSEvent.ModifierFlags to Carbon modifier bits.
    public static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }

    /// Initializes a KeyboardShortcut from a local NSEvent keydown event.
    public init?(from event: NSEvent) {
        let carbonMods = Self.carbonModifiers(from: event.modifierFlags)
        // Require at least one modifier key (BR-SET-002)
        guard carbonMods != 0 else { return nil }
        self.keyCode = UInt32(event.keyCode)
        self.carbonModifiers = carbonMods
    }

    /// Formatted canonical macOS display glyphs (e.g. "⌃⌥←", "⌃⌥1", "⌘⇧P").
    public var displayString: String {
        var glyphs = ""
        if carbonModifiers & UInt32(controlKey) != 0 { glyphs += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { glyphs += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { glyphs += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { glyphs += "⌘" }

        glyphs += keyDisplayString(for: keyCode)
        return glyphs
    }

    private func keyDisplayString(for code: UInt32) -> String {
        switch code {
        // Arrow keys
        case 123: return "←" // kVK_LeftArrow
        case 124: return "→" // kVK_RightArrow
        case 125: return "↓" // kVK_DownArrow
        case 126: return "↑" // kVK_UpArrow

        // Number row
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"

        // Letters
        case 0: return "A"
        case 11: return "B"
        case 8: return "C"
        case 2: return "D"
        case 14: return "E"
        case 3: return "F"
        case 5: return "G"
        case 4: return "H"
        case 34: return "I"
        case 38: return "J"
        case 40: return "K"
        case 37: return "L"
        case 46: return "M"
        case 45: return "N"
        case 31: return "O"
        case 35: return "P"
        case 12: return "Q"
        case 15: return "R"
        case 1: return "S"
        case 17: return "T"
        case 32: return "U"
        case 9: return "V"
        case 13: return "W"
        case 7: return "X"
        case 16: return "Y"
        case 6: return "Z"

        // Special and navigation keys
        case 36: return "↩"
        case 48: return "⇥"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "⎋"
        case 115: return "↖"
        case 119: return "↘"
        case 116: return "⇞"
        case 121: return "⇟"
        case 117: return "⌦"

        // Symbols
        case 50: return "`"
        case 27: return "-"
        case 24: return "="
        case 33: return "["
        case 30: return "]"
        case 42: return "\\"
        case 41: return ";"
        case 39: return "'"
        case 43: return ","
        case 47: return "."
        case 44: return "/"

        // Function keys
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"

        default: return "[\(code)]"
        }
    }
}
