import CoreGraphics
import Foundation

/// Defines the contract for managing Always-On-Top window pinning and dynamic LIFO Z-stacking.
@MainActor
public protocol WindowPinningCoordinating: AnyObject, Sendable {
    /// Ordered list of pinned windows in LIFO order (first element is topmost pinned).
    var pinnedWindows: [PinnedWindowRecord] { get }

    /// Whether at least one window is currently pinned.
    var isPinningActive: Bool { get }

    /// Checks if a window is currently pinned by its CGWindowID.
    func isPinned(windowID: CGWindowID) -> Bool

    /// Toggles the pinning state of a window. Returns true if pinned, false if unpinned.
    @discardableResult
    func togglePin(window: ManagedWindow) async -> Bool

    /// Unpins a specific window by CGWindowID.
    func unpin(windowID: CGWindowID)

    /// Unpins all currently pinned windows.
    func unpinAll()

    /// Handles system-wide window focus or activation changes to re-assert pinned windows.
    func handleFocusChange(activeWindowID: CGWindowID?, activePID: pid_t?) async
}
