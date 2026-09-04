# Data Model: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature**: `cross-junction-divider-resize`

---

## 1. Domain Entities

### `CrossJunction`

```swift
public struct CrossJunction: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let point: CGPoint
    public let verticalDividerID: UUID
    public let horizontalDividerID: UUID
    public let hitRadius: CGFloat
    public let participatingWindowIDs: Set<CGWindowID>

    public init(
        id: UUID = UUID(),
        point: CGPoint,
        verticalDividerID: UUID,
        horizontalDividerID: UUID,
        hitRadius: CGFloat = 14.0,
        participatingWindowIDs: Set<CGWindowID>
    ) {
        self.id = id
        self.point = point
        self.verticalDividerID = verticalDividerID
        self.horizontalDividerID = horizontalDividerID
        self.hitRadius = hitRadius
        self.participatingWindowIDs = participatingWindowIDs
    }

    public func contains(_ testPoint: CGPoint) -> Bool {
        let dx = testPoint.x - point.x
        let dy = testPoint.y - point.y
        return (dx * dx + dy * dy) <= (hitRadius * hitRadius)
    }
}
```

---

## 2. Extended Protocol Signatures

### `CollinearEdgeDetecting`

```swift
public protocol CollinearEdgeDetecting: Sendable {
    // Existing:
    func detectDividers(in windows: [ManagedWindow], containerFrame: CGRect, gap: CGFloat, tolerance: CGFloat) -> [CollinearEdge]
    func hitTestDivider(at point: CGPoint, in dividers: [CollinearEdge]) -> CollinearEdge?
    func computeResizedFrames(for divider: CollinearEdge, targetCoordinate: CGFloat, windows: [ManagedWindow], containerFrame: CGRect, gap: CGFloat) -> [CGWindowID: CGRect]

    // New Extensions:
    func detectJunctions(in dividers: [CollinearEdge], tolerance: CGFloat) -> [CrossJunction]
    func hitTestJunction(at point: CGPoint, in junctions: [CrossJunction]) -> CrossJunction?
    func compute2DResizedFrames(for junction: CrossJunction, targetPoint: CGPoint, in dividers: [CollinearEdge], windows: [ManagedWindow], containerFrame: CGRect, gap: CGFloat) -> [CGWindowID: CGRect]
}
```
