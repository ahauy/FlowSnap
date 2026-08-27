# Data Model: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Feature**: `core-layout-snap-engine`
- **Architect**: `system-architect`
- **Status**: Complete (Pending Gate 2 Review)

---

## 1. Domain Entities & Value Types

### `LayoutZone` (`FlowSnap/Domain/Layout/LayoutZone.swift`)

Standard layout partitions for deterministic window placement:

```swift
public enum LayoutZone: String, CaseIterable, Sendable, Codable, Hashable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
}
```

### `SnapTarget` (`FlowSnap/Domain/Commands/SnapTarget.swift`)

Semantic destination for window positioning commands:

```swift
public enum SnapTarget: Sendable, Hashable {
    case zone(LayoutZone)
    case restore
    case layout(Layout)

    // Convenience shorthands
    public static let left = SnapTarget.zone(.leftHalf)
    public static let right = SnapTarget.zone(.rightHalf)
    public static let top = SnapTarget.zone(.topHalf)
    public static let bottom = SnapTarget.zone(.bottomHalf)
    public static let topLeft = SnapTarget.zone(.topLeft)
    public static let topRight = SnapTarget.zone(.topRight)
    public static let bottomLeft = SnapTarget.zone(.bottomLeft)
    public static let bottomRight = SnapTarget.zone(.bottomRight)
    public static let maximize = SnapTarget.zone(.maximize)

    public var zone: LayoutZone? {
        if case .zone(let z) = self { return z }
        return nil
    }
}
```

---

## 2. Core Service Interfaces & Protocols

### `LayoutCalculating` (`FlowSnap/Core/Layout/LayoutCalculating.swift`)

```swift
public protocol LayoutCalculating: Sendable {
    /// Calculate concrete frame for a single standard layout zone.
    func frame(
        for zone: LayoutZone,
        in availableFrame: CGRect,
        gap: CGFloat
    ) -> CGRect

    /// Calculate concrete frames for multiple windows arranged according to a Layout.
    func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout,
        gap: CGFloat
    ) -> [CGWindowID: CGRect]
}
```

### `LayoutEngine` (`FlowSnap/Core/Layout/LayoutEngine.swift`)

Pure functional implementation of `LayoutCalculating`:

```swift
public struct LayoutEngine: LayoutCalculating, Sendable {
    public init() {}

    public func frame(
        for zone: LayoutZone,
        in availableFrame: CGRect,
        gap: CGFloat = 0
    ) -> CGRect

    public func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout,
        gap: CGFloat = 0
    ) -> [CGWindowID: CGRect]
}
```

### `WindowRegistry` Additions (`FlowSnap/Core/Window/WindowRegistry.swift`)

Actor-isolated pre-snap frame management:

```swift
public actor WindowRegistry {
    private var windows: [CGWindowID: ManagedWindow] = [:]
    private var preSnapFrames: [CGWindowID: CGRect] = [:]

    // Store pre-snap frame if not already recorded for this window
    public func storePreSnapFrameIfNeeded(_ frame: CGRect, for id: CGWindowID)

    // Read cached pre-snap frame without clearing
    public func preSnapFrame(for id: CGWindowID) -> CGRect?

    // Retrieve and remove pre-snap frame (consumed during Restore)
    public func consumePreSnapFrame(for id: CGWindowID) -> CGRect?

    // Explicitly invalidate/clear pre-snap frame
    public func clearPreSnapFrame(for id: CGWindowID)
}
```

### `SnapEngine` (`FlowSnap/Core/Layout/SnapEngine.swift`)

Coordinator bridging Layout calculation, WindowRegistry pre-snap frames, and AccessibilityService:

```swift
public struct SnapEngine: Sendable {
    private let layoutEngine: LayoutCalculating
    private let windowRegistry: WindowRegistry

    public init(layoutEngine: LayoutCalculating = LayoutEngine(), windowRegistry: WindowRegistry)

    /// Calculate target frame for target zone without modifying window state.
    public func calculateTargetFrame(
        for target: SnapTarget,
        window: ManagedWindow,
        availableFrame: CGRect,
        gap: CGFloat = 0
    ) async -> CGRect?

    /// Coordinates pre-snap preservation, frame calculation, and execution via AccessibilityService.
    public func applySnap(
        target: SnapTarget,
        window: ManagedWindow,
        availableFrame: CGRect,
        accessibilityService: AccessibilityService,
        gap: CGFloat = 0
    ) async throws -> CGRect
}
```
