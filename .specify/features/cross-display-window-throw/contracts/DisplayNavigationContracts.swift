import CoreGraphics
import Foundation

/// Protocol abstracting spatial navigation across multi-monitor topologies.
///
/// Traces to US-DISP-015, BR-DISP-007, BR-DISP-008, BR-DISP-011.
public protocol DisplayNavigating: Sendable {
    /// Sorts displays spatially from left to right (primary: minX, secondary: minY).
    func sortedDisplays(from displays: [Display]) -> [Display]

    /// Returns the next display in spatial sequence with cyclic wrap-around.
    /// If displays.count <= 1, returns nil.
    func nextDisplay(after current: Display, in displays: [Display]) -> Display?

    /// Returns the previous display in spatial sequence with cyclic wrap-around.
    /// If displays.count <= 1, returns nil.
    func previousDisplay(before current: Display, in displays: [Display]) -> Display?
}

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
        guard sourceBounds.width > 0, sourceBounds.height > 0 else {
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

        let scaledFrame = CGRect(x: targetX, y: targetY, width: targetW, height: targetH)
        return FrameClampingHelper.clamp(frame: scaledFrame, within: targetBounds)
    }
}

/// Helper protocol or closure for mouse cursor warping.
///
/// Traces to US-DISP-015, BR-DISP-012, ASM-DISP-003.
public protocol CursorWarping: Sendable {
    func warpCursor(to point: CGPoint)
}
