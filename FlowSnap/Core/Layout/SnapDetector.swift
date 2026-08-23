import CoreGraphics

/// Determines the snap target based on cursor/window position.
///
/// Detects which edge/corner of the display the cursor or window
/// is near, and returns the corresponding SnapTarget.
struct SnapDetector {

    /// The distance from screen edge (in points) that triggers snapping.
    var edgeThreshold: CGFloat = 10

    /// Detect which snap target the cursor position implies.
    func detectTarget(
        cursorPosition: CGPoint,
        displayFrame: CGRect
    ) -> SnapTarget? {
        // TODO: Check proximity to edges/corners
        // TODO: Return appropriate SnapTarget
        nil
    }
}
