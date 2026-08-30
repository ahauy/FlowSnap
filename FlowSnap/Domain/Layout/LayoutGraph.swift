import CoreGraphics
import Foundation

/// Represents a spatial constraint graph and layout partitioning structure
/// for a collection of managed windows on a display.
public struct LayoutGraph: Sendable {
    public let root: LayoutNode?
    public let windows: [ManagedWindow]
    public let containerFrame: CGRect
    public let gap: CGFloat

    public init(
        root: LayoutNode? = nil,
        windows: [ManagedWindow] = [],
        containerFrame: CGRect = .zero,
        gap: CGFloat = 0
    ) {
        self.root = root
        self.windows = windows
        self.containerFrame = containerFrame
        self.gap = gap
    }

    /// Extract concrete frames for all tracked windows in this graph.
    public func frames() -> [CGWindowID: CGRect] {
        if let root {
            return root.computeFrames(in: containerFrame)
        }
        var dict: [CGWindowID: CGRect] = [:]
        for window in windows {
            dict[window.id] = window.frame
        }
        return dict
    }

    /// Detect all shared collinear dividers in this layout graph.
    public func detectDividers(tolerance: CGFloat = 6.0) -> [CollinearEdge] {
        let detector = CollinearEdgeDetector()
        return detector.detectDividers(in: windows, containerFrame: containerFrame, gap: gap, tolerance: tolerance)
    }

    /// Hit-test a coordinate against all shared dividers in this graph.
    public func divider(at point: CGPoint, tolerance: CGFloat = 6.0) -> CollinearEdge? {
        let detector = CollinearEdgeDetector()
        let dividers = detectDividers(tolerance: tolerance)
        return detector.hitTestDivider(at: point, in: dividers)
    }

    /// Compute a new LayoutGraph with resized window frames after moving a divider.
    public func applyingResize(
        divider: CollinearEdge,
        targetCoordinate: CGFloat
    ) -> LayoutGraph {
        let detector = CollinearEdgeDetector()
        let resized = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: windows,
            containerFrame: containerFrame,
            gap: gap
        )

        var updatedWindows = windows
        for i in 0..<updatedWindows.count {
            let id = updatedWindows[i].id
            if let newFrame = resized[id] {
                var w = updatedWindows[i]
                w.frame = newFrame
                updatedWindows[i] = w
            }
        }

        return LayoutGraph(
            root: root,
            windows: updatedWindows,
            containerFrame: containerFrame,
            gap: gap
        )
    }
}
