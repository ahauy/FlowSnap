# Data Model: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

## 1. Domain Entities & Value Types

### 1.1 `SnapDetectionResult`

```swift
public struct SnapDetectionResult: Equatable, Sendable {
    public let target: SnapTarget
    public let previewFrame: CGRect
    public let displayID: CGDirectDisplayID
    public let isAdjacentEdge: Bool

    public init(
        target: SnapTarget,
        previewFrame: CGRect,
        displayID: CGDirectDisplayID,
        isAdjacentEdge: Bool = false
    ) {
        self.target = target
        self.previewFrame = previewFrame
        self.displayID = displayID
        self.isAdjacentEdge = isAdjacentEdge
    }
}
```

### 1.2 `SnapEdgeKind`

```swift
public enum SnapEdgeKind: Equatable, Sendable {
    case left
    case right
    case top
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}
```

---

## 2. Service Protocols

### 2.1 `SnapDetecting`

```swift
public protocol SnapDetecting: Sendable {
    func detectZone(
        at point: CGPoint,
        on display: Display,
        adjacentDisplays: [Display]
    ) -> SnapDetectionResult?
}
```

### 2.2 `MouseDragTracking`

```swift
@MainActor
public protocol MouseDragTracking: AnyObject, Sendable {
    var isTracking: Bool { get }
    func startTracking(
        onDrag: @escaping @Sendable (CGPoint) -> Void,
        onRelease: @escaping @Sendable (CGPoint) -> Void
    )
    func stopTracking()
}
```

### 2.3 `SnapPreviewManaging`

```swift
@MainActor
public protocol SnapPreviewManaging: AnyObject, Sendable {
    var isPreviewVisible: Bool { get }
    func showPreview(frame: CGRect, displayID: CGDirectDisplayID)
    func hidePreview(animated: Bool)
    func flashSnapSuccess(frame: CGRect)
}
```
