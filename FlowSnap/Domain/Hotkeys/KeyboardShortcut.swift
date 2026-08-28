import Carbon
import Foundation

/// Value object representing a physical key combination and Carbon modifier mask.
///
/// Immutable, Codable, and Sendable. See spec §34.
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

    /// Formatted canonical macOS display glyphs (e.g. "⌃⌥←", "⌃⌥1").
    public var displayString: String {
        var glyphs = ""
        if carbonModifiers & UInt32(controlKey) != 0 { glyphs += "⌃" }
        if carbonModifiers & UInt32(optionKey) != 0 { glyphs += "⌥" }
        if carbonModifiers & UInt32(shiftKey) != 0 { glyphs += "⇧" }
        if carbonModifiers & UInt32(cmdKey) != 0 { glyphs += "⌘" }

        switch keyCode {
        case 123: glyphs += "←" // kVK_LeftArrow
        case 124: glyphs += "→" // kVK_RightArrow
        case 125: glyphs += "↓" // kVK_DownArrow
        case 126: glyphs += "↑" // kVK_UpArrow
        case 18: glyphs += "1"  // kVK_ANSI_1
        case 19: glyphs += "2"  // kVK_ANSI_2
        case 20: glyphs += "3"  // kVK_ANSI_3
        case 21: glyphs += "4"  // kVK_ANSI_4
        default: glyphs += "[\(keyCode)]"
        }
        return glyphs
    }
}
