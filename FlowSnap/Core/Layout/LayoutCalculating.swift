import CoreGraphics

/// Pure layout calculation — no dependency on AppKit or Accessibility.
///
/// Takes a layout definition and display geometry, returns
/// concrete window frames. Easily unit-testable. See spec §30.
protocol LayoutCalculating {
    /// Calculate concrete frames for windows given a layout and display area.
    ///
    /// - Parameters:
    ///   - windows: The windows to arrange.
    ///   - availableFrame: The display's visible frame (excluding menu bar/dock).
    ///   - layout: The layout template to apply.
    ///   - gap: Pixel gap between windows (spec §18).
    /// - Returns: Mapping of window ID to its calculated frame.
    func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout,
        gap: CGFloat
    ) -> [CGWindowID: CGRect]
}
