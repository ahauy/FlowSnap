import CoreGraphics
import Foundation

/// Represents a shared collinear boundary between adjacent windows.
///
/// A collinear edge can span across multiple adjacent windows (e.g. 1 window on the left
/// and 2 stacked windows on the right in a T-junction layout). See spec §30.
public struct CollinearEdge: Identifiable, Hashable, Sendable {
    public let id: UUID
    /// Orientation of the divider (vertical = left/right split; horizontal = top/bottom split).
    public let orientation: DividerOrientation
    /// Coordinate along the divider axis (X for vertical, Y for horizontal).
    public let coordinate: CGFloat
    /// Orthogonal span of the divider (Y range for vertical, X range for horizontal).
    public let span: ClosedRange<CGFloat>
    /// Expanded bounding rectangle for hit testing.
    public let hitRect: CGRect
    /// Windows on the leading side (left or bottom).
    public let leadingWindowIDs: [CGWindowID]
    /// Windows on the trailing side (right or top).
    public let trailingWindowIDs: [CGWindowID]
    /// Minimum coordinate boundary clamped by leading window minSizes.
    public let minCoordinate: CGFloat
    /// Maximum coordinate boundary clamped by trailing window minSizes.
    public let maxCoordinate: CGFloat

    public init(
        id: UUID = UUID(),
        orientation: DividerOrientation,
        coordinate: CGFloat,
        span: ClosedRange<CGFloat>,
        hitRect: CGRect,
        leadingWindowIDs: [CGWindowID],
        trailingWindowIDs: [CGWindowID],
        minCoordinate: CGFloat,
        maxCoordinate: CGFloat
    ) {
        self.id = id
        self.orientation = orientation
        self.coordinate = coordinate
        self.span = span
        self.hitRect = hitRect
        self.leadingWindowIDs = leadingWindowIDs
        self.trailingWindowIDs = trailingWindowIDs
        self.minCoordinate = minCoordinate
        self.maxCoordinate = maxCoordinate
    }

    /// Checks whether a given point lies within the hit-test bounds of this divider.
    public func contains(_ point: CGPoint) -> Bool {
        hitRect.contains(point)
    }
}
