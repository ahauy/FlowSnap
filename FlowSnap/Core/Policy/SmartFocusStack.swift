import CoreGraphics
import Foundation

/// Maintains a Most-Recently-Used (MRU) focus stack of windows.
///
/// Ensures that when a floating or temporary window (e.g. chat, calculator)
/// is closed or hidden, focus naturally returns to the previously active
/// tiled window beneath it. See spec §37, BR-POLICY-004, US-WORK-014.
@MainActor
public final class SmartFocusStack {

    private var nonFloatingHistory: [CGWindowID] = []
    private var floatingWindowIDs: Set<CGWindowID> = []

    public init() {}

    /// Records that a window gained focus.
    ///
    /// - Parameters:
    ///   - windowID: The CGWindowID of the active window.
    ///   - isFloating: True if the window belongs to an app configured as `.floating`.
    public func recordFocus(windowID: CGWindowID, isFloating: Bool) {
        if isFloating {
            floatingWindowIDs.insert(windowID)
        } else {
            nonFloatingHistory.removeAll { $0 == windowID }
            nonFloatingHistory.append(windowID)
        }
    }

    /// Handles dismissal or destruction of a floating window.
    ///
    /// - Parameter windowID: The window ID that was closed.
    /// - Returns: The previous non-floating window ID to restore focus to, if available.
    public func removeFloatingWindow(windowID: CGWindowID) -> CGWindowID? {
        floatingWindowIDs.remove(windowID)
        return nonFloatingHistory.last
    }

    /// Handles general window removal or destruction.
    public func removeWindow(windowID: CGWindowID) {
        floatingWindowIDs.remove(windowID)
        nonFloatingHistory.removeAll { $0 == windowID }
    }

    /// Returns the current history of non-floating windows.
    public var currentHistory: [CGWindowID] {
        nonFloatingHistory
    }

    /// Clears all tracked history.
    public func reset() {
        nonFloatingHistory.removeAll()
        floatingWindowIDs.removeAll()
    }
}
