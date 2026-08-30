import CoreGraphics
import Foundation

/// Represents a node in a binary space partitioning (BSP) spatial layout tree.
public indirect enum LayoutNode: Equatable, Sendable {
    /// A leaf node representing a single managed window.
    case leaf(windowID: CGWindowID, frame: CGRect, minSize: CGSize?)
    /// An internal split node dividing space into two subnodes.
    case split(
        axis: DividerOrientation,
        ratio: CGFloat,
        gap: CGFloat,
        first: LayoutNode,
        second: LayoutNode
    )

    /// Collect all leaf window frames in this subtree.
    public func allFrames() -> [CGWindowID: CGRect] {
        switch self {
        case .leaf(let windowID, let frame, _):
            return [windowID: frame]
        case .split(_, _, _, let first, let second):
            var dict = first.allFrames()
            for (id, frame) in second.allFrames() {
                dict[id] = frame
            }
            return dict
        }
    }

    /// Collect all leaf window IDs in this subtree.
    public func allWindowIDs() -> [CGWindowID] {
        switch self {
        case .leaf(let windowID, _, _):
            return [windowID]
        case .split(_, _, _, let first, let second):
            return first.allWindowIDs() + second.allWindowIDs()
        }
    }

    /// Recursively evaluate concrete window frames within the given container bounds.
    public func computeFrames(in bounds: CGRect) -> [CGWindowID: CGRect] {
        switch self {
        case .leaf(let windowID, _, _):
            return [windowID: bounds]
        case .split(let axis, let ratio, let gap, let first, let second):
            let clampedRatio = max(0.05, min(0.95, ratio))
            switch axis {
            case .vertical:
                let effectiveWidth = max(0, bounds.width - gap)
                let firstWidth = floor(effectiveWidth * clampedRatio)
                let secondWidth = effectiveWidth - firstWidth
                let firstBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: firstWidth, height: bounds.height)
                let secondBounds = CGRect(x: bounds.origin.x + firstWidth + gap, y: bounds.origin.y, width: secondWidth, height: bounds.height)
                var result = first.computeFrames(in: firstBounds)
                for (id, frame) in second.computeFrames(in: secondBounds) {
                    result[id] = frame
                }
                return result

            case .horizontal:
                let effectiveHeight = max(0, bounds.height - gap)
                let firstHeight = floor(effectiveHeight * clampedRatio)
                let secondHeight = effectiveHeight - firstHeight
                let firstBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: bounds.width, height: firstHeight)
                let secondBounds = CGRect(x: bounds.origin.x, y: bounds.origin.y + firstHeight + gap, width: bounds.width, height: secondHeight)
                var result = first.computeFrames(in: firstBounds)
                for (id, frame) in second.computeFrames(in: secondBounds) {
                    result[id] = frame
                }
                return result
            }
        }
    }
}
