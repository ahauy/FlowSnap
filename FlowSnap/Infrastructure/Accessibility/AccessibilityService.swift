import ApplicationServices
import CoreGraphics
import Foundation

/// A window snapshot paired with the exact AX element it was read from.
///
/// Restoration must act on the *same* element it measured. Re-resolving a window
/// from its frame later is what let a restore write a valid frame onto a different,
/// invisible window (a Chromium tab-search panel, an extension view, a PiP surface)
/// and still report success. Carrying the element alongside the snapshot removes
/// that second guess entirely.
///
/// `@unchecked Sendable`: `AXUIElement` is a CF type whose sends across threads are
/// already treated as safe everywhere else in this codebase (see
/// `AXAccessibilityService`).
public struct ResolvedWindow: @unchecked Sendable {
    public let window: ManagedWindow
    /// `nil` when the snapshot came from the WindowServer list and no AX element
    /// could be matched to it. Callers that must write to the window treat this
    /// as "not addressable" rather than guessing.
    public let element: AXUIElement?

    public init(window: ManagedWindow, element: AXUIElement?) {
        self.window = window
        self.element = element
    }
}

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

    /// All snappable windows owned by a process, read straight from the
    /// Accessibility API instead of the WindowServer's on-screen list.
    ///
    /// `allVisibleManagedWindows()` is built on `CGWindowListCopyWindowInfo` with
    /// `.optionOnScreenOnly`, so it cannot see a window that is minimized or parked
    /// on another Space. Those windows are still fully addressable through AX, which
    /// is what restoration needs to bring them back (US-WORK-011).
    func managedWindows(of pid: pid_t) -> [ManagedWindow]

    /// Clears a window's minimized flag, pulling it back onto the screen.
    func unminimize(_ window: AXUIElement) throws

    /// The app's on-screen windows, each snapshot paired with the exact element it
    /// was read from.
    ///
    /// Prefer this over `managedWindows(of:)` whenever the caller intends to *act*
    /// on a window: the returned element is the one the frame came from, so a
    /// subsequent read or write cannot land on a different window.
    func resolvedWindows(of pid: pid_t) -> [ResolvedWindow]

    /// Clears a window's full-screen flag, transitioning it back to a regular window.
    ///
    /// Best-effort: not all apps honour the AX write. The caller is responsible
    /// for waiting after this returns to let the macOS animation complete before
    /// reading or setting the window's frame.
    func exitFullScreen(_ window: AXUIElement) throws
}
