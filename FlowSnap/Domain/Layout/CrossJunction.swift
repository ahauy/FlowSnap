import CoreGraphics
import Foundation

/// Represents an intersection point where a vertical and horizontal collinear divider meet,
/// forming either a 3-window T-junction or a 4-window Cross junction.
public struct CrossJunction: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let point: CGPoint
    public let verticalDivider: CollinearEdge
    public let horizontalDivider: CollinearEdge
    public let hitRadius: CGFloat
    public let participatingWindowIDs: [CGWindowID]

    public var verticalDividerID: UUID { verticalDivider.id }
    public var horizontalDividerID: UUID { horizontalDivider.id }

    public init(
        id: UUID = UUID(),
        point: CGPoint,
        verticalDivider: CollinearEdge,
        horizontalDivider: CollinearEdge,
        hitRadius: CGFloat = 18.0,
        participatingWindowIDs: [CGWindowID]
    ) {
        self.id = id
        self.point = point
        self.verticalDivider = verticalDivider
        self.horizontalDivider = horizontalDivider
        self.hitRadius = hitRadius
        self.participatingWindowIDs = participatingWindowIDs
    }

    /// Checks whether a given pointer coordinate falls within the circular hit radius of the junction.
    public func contains(_ testPoint: CGPoint) -> Bool {
        let dx = testPoint.x - point.x
        let dy = testPoint.y - point.y
        return (dx * dx + dy * dy) <= (hitRadius * hitRadius)
    }
}
