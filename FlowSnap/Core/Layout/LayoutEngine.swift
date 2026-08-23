import CoreGraphics

/// Computes concrete window frames from layout definitions.
///
/// Pure computation — no side effects, no system dependencies.
/// See spec §30.
struct LayoutEngine: LayoutCalculating {

    func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout,
        gap: CGFloat
    ) -> [CGWindowID: CGRect] {
        // TODO: Convert normalized LayoutZone coordinates to pixel frames
        // TODO: Apply gap between zones
        // TODO: Map windows to zones
        [:]
    }
}
