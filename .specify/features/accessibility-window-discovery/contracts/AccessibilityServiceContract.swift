import ApplicationServices
import CoreGraphics
import Foundation

/// Primary abstraction over Apple's Accessibility API (AXUIElement).
/// Encapsulates OS window inspection, discovery, and geometry reading.
public protocol AccessibilityService: Sendable {
    /// Check whether FlowSnap currently has Accessibility trust from macOS.
    var isTrusted: Bool { get }

    /// Open macOS System Settings directly to Privacy & Security > Accessibility.
    func openSystemSettings()

    /// Obtain the low-level AXUIElement for the system-wide focused window (Infrastructure internal use).
    func focusedWindow() -> AXUIElement?

    /// Query the frontmost application and construct a Domain ManagedWindow snapshot.
    func focusedManagedWindow() -> ManagedWindow?

    /// Read the frame (origin + size) of an AXUIElement window.
    func frame(of window: AXUIElement) -> CGRect?

    /// Move and resize an AXUIElement window.
    func setFrame(_ frame: CGRect, for window: AXUIElement) throws

    /// Bring an AXUIElement window to the front.
    func raise(_ window: AXUIElement) throws
}
