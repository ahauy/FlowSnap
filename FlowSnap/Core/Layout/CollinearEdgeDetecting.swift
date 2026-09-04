import CoreGraphics
import Foundation

/// Protocol for detecting shared collinear edges between adjacent windows.
public protocol CollinearEdgeDetecting: Sendable {
    /// Detect all shared collinear edges among a set of managed windows within a container frame.
    func detectDividers(
        in windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat,
        tolerance: CGFloat
    ) -> [CollinearEdge]

    /// Hit-test a point against available dividers.
    func hitTestDivider(
        at point: CGPoint,
        in dividers: [CollinearEdge]
    ) -> CollinearEdge?

    /// Compute updated window frames when moving a divider to a target coordinate.
    func computeResizedFrames(
        for divider: CollinearEdge,
        targetCoordinate: CGFloat,
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat
    ) -> [CGWindowID: CGRect]

    /// Detect intersection junctions (T-junctions and Cross junctions) among dividers.
    func detectJunctions(
        in dividers: [CollinearEdge],
        tolerance: CGFloat
    ) -> [CrossJunction]

    /// Hit-test a point against available junctions.
    func hitTestJunction(
        at point: CGPoint,
        in junctions: [CrossJunction]
    ) -> CrossJunction?

    /// Compute updated window frames when moving a junction to a target 2D coordinate.
    func compute2DResizedFrames(
        for junction: CrossJunction,
        targetPoint: CGPoint,
        in dividers: [CollinearEdge],
        windows: [ManagedWindow],
        containerFrame: CGRect,
        gap: CGFloat
    ) -> [CGWindowID: CGRect]
}
