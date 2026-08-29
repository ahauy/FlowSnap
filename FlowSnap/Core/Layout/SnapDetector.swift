import CoreGraphics
import Foundation

/// Pure mathematical evaluator determining snap targets from cursor coordinates and display boundaries.
///
/// Implements edge threshold detection, corner zone partitioning, and multi-monitor adjacency checks.
/// Conforms to `SnapDetecting` (Sendable). See spec §30, §31.
public struct SnapDetector: SnapDetecting, Sendable {

    /// Distance from screen boundary (in points) that activates snap edge triggers (default: 20px).
    public let edgeThreshold: CGFloat

    /// Portion of screen edge length allocated to corner zones (default: 0.20 = 20%).
    public let cornerRatio: CGFloat

    private let layoutEngine: LayoutEngine

    public init(
        edgeThreshold: CGFloat = 20,
        cornerRatio: CGFloat = 0.20,
        layoutEngine: LayoutEngine = LayoutEngine()
    ) {
        self.edgeThreshold = edgeThreshold
        self.cornerRatio = cornerRatio
        self.layoutEngine = layoutEngine
    }

    /// Evaluates cursor point against the target display geometry and identifies the triggered snap target.
    public func detectZone(
        at point: CGPoint,
        on display: Display,
        adjacentDisplays: [Display]
    ) -> SnapDetectionResult? {
        let frame = display.frame
        let minX = frame.minX
        let maxX = frame.maxX
        let minY = frame.minY
        let maxY = frame.maxY

        let isNearLeft = point.x >= minX - edgeThreshold && point.x <= minX + edgeThreshold
        let isNearRight = point.x >= maxX - edgeThreshold && point.x <= maxX + edgeThreshold
        let isNearBottom = point.y >= minY - edgeThreshold && point.y <= minY + edgeThreshold
        let topBoundary = min(display.visibleFrame.maxY, maxY)
        let isNearTop = point.y >= topBoundary - edgeThreshold && point.y <= maxY + edgeThreshold

        guard isNearLeft || isNearRight || isNearBottom || isNearTop else {
            return nil
        }

        let cornerWidth = frame.width * cornerRatio
        let cornerHeight = frame.height * cornerRatio

        let target: SnapTarget
        let isAdjacent: Bool

        // 1. Check 4 Corners
        if (isNearLeft && point.y >= topBoundary - cornerHeight) || (isNearTop && point.x <= minX + cornerWidth) {
            target = .topLeft
            isAdjacent = isEdgeAdjacent(side: .left, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays) ||
                         isEdgeAdjacent(side: .top, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else if (isNearRight && point.y >= topBoundary - cornerHeight) || (isNearTop && point.x >= maxX - cornerWidth) {
            target = .topRight
            isAdjacent = isEdgeAdjacent(side: .right, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays) ||
                         isEdgeAdjacent(side: .top, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else if (isNearLeft && point.y <= minY + cornerHeight) || (isNearBottom && point.x <= minX + cornerWidth) {
            target = .bottomLeft
            isAdjacent = isEdgeAdjacent(side: .left, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays) ||
                         isEdgeAdjacent(side: .bottom, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else if (isNearRight && point.y <= minY + cornerHeight) || (isNearBottom && point.x >= maxX - cornerWidth) {
            target = .bottomRight
            isAdjacent = isEdgeAdjacent(side: .right, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays) ||
                         isEdgeAdjacent(side: .bottom, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        // 2. Check 4 Halves & Maximize
        } else if isNearLeft {
            target = .left
            isAdjacent = isEdgeAdjacent(side: .left, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else if isNearRight {
            target = .right
            isAdjacent = isEdgeAdjacent(side: .right, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else if isNearTop {
            target = .maximize
            isAdjacent = isEdgeAdjacent(side: .top, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else if isNearBottom {
            target = .bottom
            isAdjacent = isEdgeAdjacent(side: .bottom, minX: minX, maxX: maxX, minY: minY, maxY: maxY, adjacentDisplays: adjacentDisplays)
        } else {
            return nil
        }

        guard let zone = target.zone else {
            return nil
        }

        let isTopCenter = isNearTop && (target == .maximize) && (point.x >= minX + frame.width * 0.3 && point.x <= minX + frame.width * 0.7)
        let previewFrame = layoutEngine.frame(for: zone, in: display.visibleFrame)

        return SnapDetectionResult(
            target: target,
            previewFrame: previewFrame,
            displayID: display.id,
            isAdjacentEdge: isAdjacent,
            isTopCenterZone: isTopCenter
        )
    }

    /// Checks whether the cursor is in the top-center trigger zone (middle 40% width, top edge).
    public func isTopCenterZone(at point: CGPoint, on display: Display) -> Bool {
        let frame = display.frame
        let minX = frame.minX
        let maxY = frame.maxY
        let topBoundary = min(display.visibleFrame.maxY, maxY)
        let isNearTop = point.y >= topBoundary - edgeThreshold && point.y <= maxY + edgeThreshold
        let centerMinX = minX + frame.width * 0.3
        let centerMaxX = minX + frame.width * 0.7
        return isNearTop && point.x >= centerMinX && point.x <= centerMaxX
    }

    private enum EdgeSide {
        case left, right, top, bottom
    }

    private func isEdgeAdjacent(
        side: EdgeSide,
        minX: CGFloat,
        maxX: CGFloat,
        minY: CGFloat,
        maxY: CGFloat,
        adjacentDisplays: [Display]
    ) -> Bool {
        for other in adjacentDisplays {
            let oFrame = other.frame
            switch side {
            case .left:
                if abs(oFrame.maxX - minX) <= 10 && oFrame.minY < maxY && oFrame.maxY > minY {
                    return true
                }
            case .right:
                if abs(oFrame.minX - maxX) <= 10 && oFrame.minY < maxY && oFrame.maxY > minY {
                    return true
                }
            case .top:
                if abs(oFrame.minY - maxY) <= 10 && oFrame.minX < maxX && oFrame.maxX > minX {
                    return true
                }
            case .bottom:
                if abs(oFrame.maxY - minY) <= 10 && oFrame.minX < maxX && oFrame.maxX > minX {
                    return true
                }
            }
        }
        return false
    }
}
