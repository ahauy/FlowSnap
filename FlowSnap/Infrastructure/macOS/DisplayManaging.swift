import CoreGraphics

/// Abstraction for querying connected displays.
///
/// Wraps NSScreen to provide display geometry
/// for display-aware snapping. See spec §33.
protocol DisplayManaging {
    /// All currently connected displays.
    var displays: [Display] { get }

    /// Find the display containing a screen coordinate.
    func display(containing point: CGPoint) -> Display?

    /// Find the display containing a window (by its center point).
    func display(containing window: ManagedWindow) -> Display?
}
