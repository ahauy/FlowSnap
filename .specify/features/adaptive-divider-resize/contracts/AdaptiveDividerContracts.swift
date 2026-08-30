import CoreGraphics
import Foundation

/// Protocol for detecting collinear shared edges between adjacent windows.
public protocol CollinearEdgeDetecting: Sendable {
    /// Detect all shared collinear edges among a set of managed windows within a container frame.
    func detectDividers(
        in windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat,
        tolerance: CGFloat
    ) -> [CollinearEdge]

    /// Hit-test a mouse coordinate against available dividers.
    func hitTestDivider(
        at point: CGPoint,
        in dividers: [CollinearEdge]
    ) -> CollinearEdge?

    /// Compute updated window frames when dragging a divider to a new target coordinate.
    func computeResizedFrames(
        for divider: CollinearEdge,
        targetCoordinate: CGFloat,
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat
    ) -> [CGWindowID: CGRect]
}

/// Protocol for throttling high-frequency live resize operations.
public protocol LiveResizeThrottling: Sendable {
    /// Whether an incoming frame resize event should be processed given the current timestamp.
    func shouldProcess(timestamp: TimeInterval) -> Bool
}

/// Protocol for coordinating mouse tracking, divider hover, and live window resizing.
@MainActor
public protocol AdaptiveDividerCoordinating: AnyObject {
    var activeDivider: CollinearEdge? { get }
    var isResizing: Bool { get }

    func updateWindows(_ windows: [ManagedWindow])
    func handleMouseMoved(to point: CGPoint)
    func handleMouseDown(at point: CGPoint)
    func handleMouseDragged(to point: CGPoint) async
    func handleMouseUp(at point: CGPoint) async
}
