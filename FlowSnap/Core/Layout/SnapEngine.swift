import CoreGraphics

/// Converts a SnapTarget into a concrete frame using LayoutEngine.
///
/// Flow: Mouse/Hotkey → SnapEngine → SnapTarget → LayoutEngine → WindowManager.
/// See spec §31.
struct SnapEngine {

    private let layoutEngine: LayoutCalculating

    init(layoutEngine: LayoutCalculating) {
        self.layoutEngine = layoutEngine
    }

    /// Calculate the frame for snapping a window to a target on a display.
    func frame(
        for target: SnapTarget,
        on display: Display,
        gap: CGFloat
    ) -> CGRect {
        // TODO: Convert SnapTarget to Layout, delegate to LayoutEngine
        .zero
    }
}
