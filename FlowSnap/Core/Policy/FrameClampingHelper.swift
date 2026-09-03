import CoreGraphics
import Foundation

/// Mathematical utility for clamping window bounds within screen visible frames.
///
/// Ensures restored windows are never positioned off-screen or underneath system bars.
/// See spec §37, BR-POLICY-003, US-WORK-014.
public enum FrameClampingHelper {

    /// Clamps a candidate frame into the target visible bounds.
    ///
    /// - Parameters:
    ///   - frame: The requested or remembered window frame.
    ///   - visibleBounds: The visible frame of the active display (excluding menu bar and dock).
    ///   - minVisibilityRatio: Minimum required visible area ratio (default: 0.8).
    /// - Returns: A guaranteed valid, fully or mostly visible `CGRect`.
    public static func clamp(
        frame: CGRect,
        to visibleBounds: CGRect,
        minVisibilityRatio: CGFloat = 0.8
    ) -> CGRect {
        guard !visibleBounds.isEmpty, !frame.isEmpty else {
            return visibleBounds
        }

        // 1. Constrain dimensions so they do not exceed the visible screen
        let width = min(frame.width, visibleBounds.width)
        let height = min(frame.height, visibleBounds.height)

        // 2. Constrain origin X so the window is within screen limits
        var originX = frame.origin.x
        if originX + width * minVisibilityRatio > visibleBounds.maxX {
            originX = visibleBounds.maxX - width
        }
        if originX + width * (1.0 - minVisibilityRatio) < visibleBounds.minX {
            originX = visibleBounds.minX
        }

        if width <= visibleBounds.width {
            originX = max(visibleBounds.minX, min(originX, visibleBounds.maxX - width))
        }

        // 3. Constrain origin Y
        var originY = frame.origin.y
        if originY + height * minVisibilityRatio > visibleBounds.maxY {
            originY = visibleBounds.maxY - height
        }
        if originY + height * (1.0 - minVisibilityRatio) < visibleBounds.minY {
            originY = visibleBounds.minY
        }

        if height <= visibleBounds.height {
            originY = max(visibleBounds.minY, min(originY, visibleBounds.maxY - height))
        }

        return CGRect(x: originX, y: originY, width: width, height: height)
    }
}
