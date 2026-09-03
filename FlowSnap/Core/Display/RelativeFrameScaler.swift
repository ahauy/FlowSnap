import CoreGraphics
import Foundation

/// Pure geometric transformer mapping window frames proportionally between displays.
///
/// Traces to US-DISP-015, BR-DISP-009, ASM-DISP-002.
public struct RelativeFrameScaler: Sendable {

    /// Maps a window frame from source display visible bounds to target display visible bounds.
    ///
    /// - Parameters:
    ///   - frame: Window frame in AppKit or global coordinates.
    ///   - sourceBounds: The visibleFrame of the source display.
    ///   - targetBounds: The visibleFrame of the target display.
    ///   - minSize: Minimum allowable window dimensions (default: 200x200).
    /// - Returns: Proportional CGRect clamped safely within targetBounds.
    public static func scale(
        frame: CGRect,
        from sourceBounds: CGRect,
        to targetBounds: CGRect,
        minSize: CGSize = CGSize(width: 200, height: 200)
    ) -> CGRect {
        guard sourceBounds.width > 0, sourceBounds.height > 0,
              targetBounds.width > 0, targetBounds.height > 0 else {
            return targetBounds
        }

        let relX = (frame.origin.x - sourceBounds.origin.x) / sourceBounds.width
        let relY = (frame.origin.y - sourceBounds.origin.y) / sourceBounds.height
        let relW = frame.size.width / sourceBounds.width
        let relH = frame.size.height / sourceBounds.height

        let targetW = max(minSize.width, min(targetBounds.width, relW * targetBounds.width))
        let targetH = max(minSize.height, min(targetBounds.height, relH * targetBounds.height))
        let targetX = targetBounds.origin.x + (relX * targetBounds.width)
        let targetY = targetBounds.origin.y + (relY * targetBounds.height)

        let candidateFrame = CGRect(x: targetX, y: targetY, width: targetW, height: targetH)
        return FrameClampingHelper.clamp(frame: candidateFrame, to: targetBounds, minVisibilityRatio: 1.0)
    }
}
