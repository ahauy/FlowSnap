import AppKit
import Foundation

/// Handles routing to macOS System Settings panes.
public struct SystemSettingsRouter: Sendable {

    /// Canonical deep link to macOS Privacy & Security > Accessibility pane.
    public static let accessibilityURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    public init() {}

    /// Opens System Settings to Privacy & Security > Accessibility.
    @MainActor
    public func openAccessibilitySettings() {
        NSWorkspace.shared.open(Self.accessibilityURL)
    }
}
