# Data Model: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Feature**: `accessibility-window-discovery`
- **Architect**: `system-architect`

---

## 1. Domain Entities & Value Objects

### 1.1 `ManagedWindow` (Value Object / Entity)

```swift
import CoreGraphics
import Foundation

/// A snapshot of a window's state tracked and managed by FlowSnap.
/// Does not hold a direct reference to AXUIElement to preserve pure domain isolation.
public struct ManagedWindow: Identifiable, Hashable, Sendable {
    public let id: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let title: String
    public var frame: CGRect
    public var isMinimized: Bool
    public var isResizable: Bool
    public var kind: WindowKind

    public init(
        id: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String? = nil,
        title: String,
        frame: CGRect,
        isMinimized: Bool = false,
        isResizable: Bool = true,
        kind: WindowKind = .normal
    ) {
        self.id = id
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.frame = frame
        self.isMinimized = isMinimized
        self.isResizable = isResizable
        self.kind = kind
    }
}
```

---

### 1.2 `WindowKind` (Enum)

```swift
import Foundation

/// Semantic classification of a window to determine its eligibility for snap layouts.
public enum WindowKind: String, Codable, Sendable, Hashable {
    /// Standard resizable application window (eligible for snapping).
    case normal

    /// Modal or system dialog window.
    case dialog

    /// Attached sheet window (e.g. print sheet, save sheet).
    case sheet

    /// OS system element (e.g. Spotlight, Notification Center, Menubar extra).
    case system

    /// Unrecognized or non-standard element lacking geometry/settable attributes.
    case unsupported

    /// Whether this window kind is eligible for snap operations.
    public var isSnappable: Bool {
        self == .normal
    }
}
```

---

### 1.3 `AccessibilityError` (Enum / Domain Error)

```swift
import Foundation

/// Typed errors representing Accessibility operations and boundary failures.
public enum AccessibilityError: Error, Equatable, Sendable {
    case notTrusted
    case applicationNotFound(pid_t)
    case windowNotFound
    case attributeUnsupported(String)
    case invalidGeometry
    case cannotComplete
    case systemFailure(Int32)
}
```
