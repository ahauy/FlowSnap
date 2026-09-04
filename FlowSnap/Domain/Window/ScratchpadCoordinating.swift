import CoreGraphics
import Foundation

/// Defines the contract for managing the Quake-style Quick Scratchpad lifecycle and instant toggle.
@MainActor
public protocol ScratchpadCoordinating: AnyObject, Sendable {
    /// The current lifecycle and visibility state of the Scratchpad.
    var state: ScratchpadState { get }

    /// The metadata of the currently assigned Scratchpad window, if any.
    var currentRecord: ScratchpadRecord? { get }

    /// Whether the Scratchpad window is currently visible on screen.
    var isVisible: Bool { get }

    /// Assigns the currently focused window as the active Scratchpad.
    @discardableResult
    func assignFocusedWindow() async -> Bool

    /// Toggles the Scratchpad visibility (summon if hidden, dismiss if visible).
    @discardableResult
    func toggleScratchpad() async -> Bool

    /// Summons the Scratchpad window to the frontmost layer in < 50ms.
    @discardableResult
    func summonScratchpad() async -> Bool

    /// Dismisses the Scratchpad window and restores focus to the previously active application.
    @discardableResult
    func dismissScratchpad() async -> Bool

    /// Manually detaches the active Scratchpad, reverting to `.unassigned`.
    func detachScratchpad()
}
