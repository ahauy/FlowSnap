import ApplicationServices
import CoreGraphics
import Foundation

/// Abstraction over Apple's Accessibility API (AXUIElement).
///
/// All AX calls are isolated here so Core never depends
/// on AXUIElement directly. See spec §28.
public protocol AccessibilityService: Sendable {
    /// Check whether FlowSnap currently has Accessibility trust from macOS.
    var isTrusted: Bool { get }

    /// Open macOS System Settings directly to Privacy & Security > Accessibility.
    func openSystemSettings()

    /// Get the system-wide focused window element.
    func focusedWindow() -> AXUIElement?

    /// Query the frontmost application and construct a Domain ManagedWindow snapshot.
    func focusedManagedWindow() -> ManagedWindow?

    /// Get all windows for a given process.
    func windows(of pid: pid_t) -> [AXUIElement]

    /// Read the frame (position + size) of a window.
    func frame(of window: AXUIElement) -> CGRect?

    /// Move and resize a window.
    func setFrame(_ frame: CGRect, for window: AXUIElement) throws

    /// Bring a window to the front.
    func raise(_ window: AXUIElement) throws

    /// Resolves the specific AXUIElement for a given ManagedWindow.
    func windowElement(for window: ManagedWindow) -> AXUIElement?

    /// Queries all visible on-screen windows from the macOS Window Server.
    func allVisibleManagedWindows() -> [ManagedWindow]
}
