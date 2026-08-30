# Data Model: US-SNAP-009 Adaptive Divider Resize

## 1. Types & Structures

### `DividerOrientation`
```swift
public enum DividerOrientation: String, Codable, Sendable {
    case vertical
    case horizontal
}
```

### `CollinearEdge`
```swift
public struct CollinearEdge: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let orientation: DividerOrientation
    public let coordinate: CGFloat
    public let span: ClosedRange<CGFloat>
    public let hitRect: CGRect
    public let leadingWindowIDs: [CGWindowID]
    public let trailingWindowIDs: [CGWindowID]
    public let minCoordinate: CGFloat
    public let maxCoordinate: CGFloat

    public func contains(_ point: CGPoint) -> Bool {
        hitRect.contains(point)
    }
}
```

### `LayoutNode`
```swift
public indirect enum LayoutNode: Equatable, Sendable {
    case leaf(windowID: CGWindowID, frame: CGRect, minSize: CGSize?)
    case split(axis: DividerOrientation, ratio: CGFloat, gap: CGFloat, first: LayoutNode, second: LayoutNode)
}
```

### `LayoutGraph`
```swift
public struct LayoutGraph: Sendable {
    public let root: LayoutNode?
    public let windows: [ManagedWindow]
    public let containerFrame: CGRect
    public let gap: CGFloat

    public func detectDividers(tolerance: CGFloat = 6.0) -> [CollinearEdge]
    public func divider(at point: CGPoint, tolerance: CGFloat = 6.0) -> CollinearEdge?
    public func applyResize(divider: CollinearEdge, targetCoordinate: CGFloat) -> [CGWindowID: CGRect]
}
```
