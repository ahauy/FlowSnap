# Data Model & Interface Contracts: always-on-top-window-pinning (US-SNAP-021)

## 1. Domain Entities & Protocols

### 1.1. `PinnedWindowRecord`

```swift
import CoreGraphics
import Foundation

/// Immutable record identifying a pinned window and its lifecycle metadata.
public struct PinnedWindowRecord: Sendable, Identifiable, Hashable {
    public let id: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let title: String
    public let pinnedAt: Date

    public init(
        id: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String?,
        title: String,
        pinnedAt: Date = Date()
    ) {
        self.id = id
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.pinnedAt = pinnedAt
    }
}
```

### 1.2. `WindowPinningCoordinating`

```swift
import CoreGraphics
import Foundation

/// Orchestrates Always-On-Top window pinning and dynamic LIFO Z-stacking.
@MainActor
public protocol WindowPinningCoordinating: AnyObject, Sendable {
    /// Ordered list of pinned windows in LIFO order (first element = topmost pinned).
    var pinnedWindows: [PinnedWindowRecord] { get }

    /// Whether any window is currently pinned.
    var isPinningActive: Bool { get }

    /// Checks if a window is currently pinned.
    func isPinned(windowID: CGWindowID) -> Bool

    /// Toggles the pinning state of a window. Returns new pinned state (true if pinned).
    @discardableResult
    func togglePin(window: ManagedWindow) async -> Bool

    /// Unpins a specific window by CGWindowID.
    func unpin(windowID: CGWindowID)

    /// Unpins all currently pinned windows.
    func unpinAll()

    /// Handles system-wide window focus/activation changes to re-assert pinned windows.
    func handleFocusChange(activeWindowID: CGWindowID?, activePID: pid_t?) async
}
```

### 1.3. `StageManagerLaunchCoordinating`

```swift
import Foundation

/// Coordinates Stage Manager multi-window cohesion when applications launch.
@MainActor
public protocol StageManagerLaunchCoordinating: AnyObject, Sendable {
    /// Whether launch co-existence is enabled in preferences.
    var isCoexistenceEnabled: Bool { get set }

    /// Handles an application launch event, snapshotting and preserving the active Stage.
    func handleApplicationLaunched(processIdentifier: pid_t, bundleIdentifier: String?) async
}
```

---

## 2. Preferences & Hotkey Contracts

### 2.1. `ShortcutAction` Addition

```swift
public enum ShortcutAction: String, CaseIterable, Codable, Sendable {
    // Existing actions...
    case togglePinFocusedWindow = "togglePinFocusedWindow"
}
```

### 2.2. `PreferencesStore` Keys

```swift
@Published public var stageManagerLaunchCoexistenceEnabled: Bool = true
```

---

## 3. UI ViewModel Contracts

### 3.1. `MenuBarViewModel` Extensions

- `pinnedWindowsCount: Int` (derived from `pinningCoordinator.pinnedWindows.count`)
- `pinnedWindows: [PinnedWindowRecord]`
- `unpin(windowID: CGWindowID)`
- `unpinAll()`
