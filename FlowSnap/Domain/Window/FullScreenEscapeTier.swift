import Foundation

/// Defines the execution tier used to trigger a macOS Native Full Screen exit.
public enum FullScreenEscapeTier: String, Sendable, CaseIterable, Codable {
    /// Tier 0: Direct attribute write (AXFullscreen / AXFullScreen = false). Fastest for Cocoa apps.
    case attributeWrite
    /// Tier 1: Accessibility button action (kAXFullScreenButtonAttribute + kAXPressAction). Primary for Electron/Chromium.
    case axButtonPress
    /// Tier 2: Synthesized macOS keyboard shortcut (Control + Command + F) posted via CGEvent to target PID.
    case cgEventShortcut
}
