import CoreGraphics
import Foundation

/// Pure geometry helpers that turn a window's current rectangle into a
/// `LayoutZone` intent (BR-WORK-002).
///
/// Why this is a separate, dependency-free type: zone inference is the single
/// place where "the user's layout" is decided at capture time. Getting it wrong
/// silently saves the wrong intent, and it is pure math — so it belongs somewhere
/// it can be unit-tested against hand-computed rectangles with no Accessibility,
/// AppKit or display service involved (plan.md §5 "cross-display drift").
enum ZoneInference {

    /// The zone whose rectangle best overlaps a window's normalized rectangle.
    ///
    /// Uses intersection-over-union rather than "nearest corner" because IoU is
    /// scale- and origin-independent: a window covering exactly the left half
    /// scores 1.0 for `.leftHalf` no matter which display it is on, which is what
    /// makes the saved intent resolution-independent (BR-WORK-007).
    ///
    /// - Parameters:
    ///   - normalizedRect: the window's rect in `0...1` display space, y-down
    ///     (matching `LayoutZone.normalizedRect`).
    /// - Returns: the highest-IoU zone. Ties resolve to the first zone in
    ///   `LayoutZone.allCases`, so the result is deterministic.
    static func inferZone(forNormalized normalizedRect: CGRect) -> LayoutZone {
        var best: LayoutZone = .maximize
        var bestScore = -1.0
        for zone in LayoutZone.allCases {
            let score = intersectionOverUnion(normalizedRect, zone.normalizedRect)
            if score > bestScore {
                bestScore = score
                best = zone
            }
        }
        return best
    }

    /// Normalizes a window's AppKit frame into `0...1` space of a display's
    /// visible frame, **y-down** (top-left origin).
    ///
    /// The output convention is deliberately y-down so it lines up with
    /// `LayoutZone.normalizedRect`, which is y-down because the layout picker
    /// renders it directly. The input is AppKit (y-up), so the vertical axis is
    /// flipped here rather than at every call site.
    ///
    /// Clamped so a window that hangs off an edge (partially dragged off-screen)
    /// still yields a sane rect instead of coordinates beyond 1.
    static func normalizedRect(of appKitFrame: CGRect, within visibleFrame: CGRect) -> CGRect {
        guard visibleFrame.width > 0, visibleFrame.height > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        let minX = (appKitFrame.minX - visibleFrame.minX) / visibleFrame.width
        let minY = (appKitFrame.minY - visibleFrame.minY) / visibleFrame.height
        let maxX = (appKitFrame.maxX - visibleFrame.minX) / visibleFrame.width
        let maxY = (appKitFrame.maxY - visibleFrame.minY) / visibleFrame.height

        let clampedMinX = Swift.min(Swift.max(minX, 0), 1)
        let clampedMinY = Swift.min(Swift.max(minY, 0), 1)
        let clampedMaxX = Swift.min(Swift.max(maxX, 0), 1)
        let clampedMaxY = Swift.min(Swift.max(maxY, 0), 1)

        // Flip the vertical axis: a y-up span [minY, maxY] becomes a y-down rect
        // whose top edge is `1 - maxY` and whose height is unchanged.
        return CGRect(
            x: clampedMinX,
            y: 1 - clampedMaxY,
            width: clampedMaxX - clampedMinX,
            height: clampedMaxY - clampedMinY
        )
    }

    /// Intersection-over-union of two rectangles, `0` when either is empty.
    static func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let lhsArea = max(0, lhs.width) * max(0, lhs.height)
        let rhsArea = max(0, rhs.width) * max(0, rhs.height)
        guard lhsArea > 0, rhsArea > 0 else { return 0 }
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else {
            return 0
        }
        let intersectionArea = intersection.width * intersection.height
        return intersectionArea / (lhsArea + rhsArea - intersectionArea)
    }
}
