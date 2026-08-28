# Data Model: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Feature**: `display-aware-manipulation`
- **Architect**: `system-architect`

---

## 1. Domain Entities

### `Display` (Value Object / Domain Model)

Path: `FlowSnap/Domain/Display/Display.swift`

```swift
import CoreGraphics
import Foundation

/// Represents a physical or logical display connected to macOS.
public struct Display: Identifiable, Hashable, Sendable {
    /// DirectDisplayID assigned by CoreGraphics.
    public let id: CGDirectDisplayID

    /// Full frame in AppKit coordinates (points).
    public let frame: CGRect

    /// Usable frame excluding menu bar and dock in AppKit coordinates (points).
    public let visibleFrame: CGRect

    /// Retina scale factor (1.0 for standard, 2.0 for Retina/HiDPI).
    public let scaleFactor: CGFloat

    /// Indicates whether this is the primary display (origin at (0,0) in AppKit).
    public let isPrimary: Bool

    public init(
        id: CGDirectDisplayID,
        frame: CGRect,
        visibleFrame: CGRect,
        scaleFactor: CGFloat,
        isPrimary: Bool? = nil
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.scaleFactor = scaleFactor
        self.isPrimary = isPrimary ?? (frame.origin == .zero)
    }
}
```

---

## 2. Core Services & Protocols

### `CoordinateTransformer` (Core Deep Module)

Path: `FlowSnap/Core/Display/CoordinateTransformer.swift`

```swift
import CoreGraphics

/// Pure mathematical involution performing exact bidirectional coordinate conversions
/// between AppKit (bottom-left origin) and Accessibility API (top-left of Primary screen origin).
public struct CoordinateTransformer: Sendable {

    /// Converts an AppKit CGRect to Accessibility API coordinates.
    @inlinable
    public static func toAX(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - (rect.origin.y + rect.height),
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts an Accessibility API CGRect to AppKit coordinates.
    @inlinable
    public static func toAppKit(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - (rect.origin.y + rect.height),
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts an AppKit CGPoint to Accessibility API coordinates.
    @inlinable
    public static func toAX(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }

    /// Converts an Accessibility API CGPoint to AppKit coordinates.
    @inlinable
    public static func toAppKit(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }
}
```

### `DisplayManaging` (Protocol)

Path: `FlowSnap/Core/Display/DisplayManaging.swift`

```swift
import CoreGraphics
import Foundation

/// Protocol abstracting display topology, spatial queries, and screen change notifications.
public protocol DisplayManaging: Sendable {
    /// All active, non-mirrored displays currently connected.
    var displays: [Display] { get async }

    /// The primary display (origin at (0,0) in AppKit), if available.
    var primaryDisplay: Display? { get async }

    /// Total height of the primary display (used for global AX inversion).
    var primaryScreenHeight: CGFloat { get async }

    /// Finds the display containing the specified AppKit point.
    func display(containing point: CGPoint) async -> Display?

    /// Finds the display with maximum intersection area for the given window frame.
    /// Falls back to cursor display, then primary display if outside all bounds.
    func display(for windowFrame: CGRect, cursorPoint: CGPoint?) async -> Display?

    /// Returns the next display in sequence, cycling around. Returns nil if only 1 display.
    func nextDisplay(after currentDisplay: Display) async -> Display?
}
```

---

## 3. Infrastructure Adapter

### `DisplayManager` (AppKit Screen Adapter)

Path: `FlowSnap/Infrastructure/Display/DisplayManager.swift`

```swift
import AppKit
import CoreGraphics

/// Concrete AppKit implementation of DisplayManaging.
/// Observes `NSApplication.didChangeScreenParametersNotification` on MainActor.
public final actor DisplayManager: DisplayManaging {
    // Thread-safe cached display state
    // Coalesces mirrored screens
    // Resolves max intersection area
}
```
