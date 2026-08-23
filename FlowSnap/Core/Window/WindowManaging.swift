import CoreGraphics

/// Abstraction for controlling windows.
///
/// The single interface through which all window manipulation flows.
/// Implementation wraps AccessibilityService. See spec §27.
protocol WindowManaging {
    /// Returns the currently focused window, if any.
    func focusedWindow() async -> ManagedWindow?

    /// Moves and resizes a window to the given frame.
    func move(_ window: ManagedWindow, to frame: CGRect) async throws

    /// Brings a window to the front.
    func focus(_ window: ManagedWindow) async throws

    /// Minimizes a window.
    func minimize(_ window: ManagedWindow) async throws
}
