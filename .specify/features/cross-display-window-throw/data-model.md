# Data Model — Cross-Display Window Throw (US-DISP-015)

> DTOs, value types, and lifecycle states introduced or modified by US-DISP-015.
> All types conform to `Sendable` per Swift 6 strict concurrency.

---

## 1. New & Extended Types

### 1.1 `WindowCommand` (extended enum, Domain)

```swift
public enum WindowCommand: Hashable, Sendable {
    // Existing snap cases
    case snap(SnapTarget, targetDisplayID: CGDirectDisplayID? = nil)
    case maximize
    case restore
    case minimize

    // Display navigation
    case moveToDisplay(CGDirectDisplayID)
    case moveToNextDisplay      // NEW: US-DISP-015
    case moveToPreviousDisplay  // NEW: US-DISP-015

    // Workspace & Presets
    case restoreWorkspace(UUID)
    case saveWorkspace(String)
    case restorePreset(String)
}
```

- **Location**: `FlowSnap/Domain/Commands/WindowCommand.swift`
- **Purpose**: Semantic intents dispatched when user triggers `⌃⌥⇧→` or `⌃⌥⇧←`.

### 1.2 `ShortcutAction` (extended enum, Domain)

```swift
// Default commands updated in ShortcutAction:
case .nextDisplay: return .moveToNextDisplay
case .previousDisplay: return .moveToPreviousDisplay

// Default shortcuts assigned in ShortcutAction:
case .nextDisplay:
    return KeyboardShortcut(keyCode: 124, carbonModifiers: ctrlOptShift) // ⌃⌥⇧→
case .previousDisplay:
    return KeyboardShortcut(keyCode: 123, carbonModifiers: ctrlOptShift) // ⌃⌥⇧←
```

- **Location**: `FlowSnap/Domain/Hotkeys/ShortcutAction.swift`
- **Purpose**: Wires the out-of-the-box keyboard shortcuts and connects to the correct `WindowCommand`.

### 1.3 `DisplayNavigating` & `DisplayNavigator` (Core)

```swift
public protocol DisplayNavigating: Sendable {
    func sortedDisplays(from displays: [Display]) -> [Display]
    func nextDisplay(after current: Display, in displays: [Display]) -> Display?
    func previousDisplay(before current: Display, in displays: [Display]) -> Display?
}

public struct DisplayNavigator: DisplayNavigating {
    public init() {}
    // Implements spatial left-to-right sorting and cyclic modulo index traversal
}
```

- **Location**: `FlowSnap/Core/Display/DisplayNavigator.swift`
- **Purpose**: Deterministic spatial calculations for multi-monitor topologies.

### 1.4 `RelativeFrameScaler` (Core)

```swift
public struct RelativeFrameScaler: Sendable {
    public static func scale(
        frame: CGRect,
        from sourceBounds: CGRect,
        to targetBounds: CGRect,
        minSize: CGSize = CGSize(width: 200, height: 200)
    ) -> CGRect
}
```

- **Location**: `FlowSnap/Core/Display/RelativeFrameScaler.swift`
- **Purpose**: Proportional translation of window boundaries across displays with `FrameClampingHelper` integration.

### 1.5 `CursorWarping` & `CursorManager` (Infrastructure)

```swift
public protocol CursorWarping: Sendable {
    func warpCursor(to point: CGPoint)
}

public final class CursorManager: CursorWarping {
    public init() {}
    public func warpCursor(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
    }
}
```

- **Location**: `FlowSnap/Infrastructure/macOS/CursorManager.swift`
- **Purpose**: Relocates system mouse pointer to center of thrown window on destination display.
