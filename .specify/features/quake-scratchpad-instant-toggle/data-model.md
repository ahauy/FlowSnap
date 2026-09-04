# Data Model & Contracts: Quake-Style Quick Scratchpad & Instant Window Toggle (US-SNAP-022)

## 1. Domain Entities & Value Types

### `ScratchpadRecord`

Immutable value type capturing the identity of the currently assigned Scratchpad window.

```swift
public struct ScratchpadRecord: Sendable, Equatable, Identifiable {
    public var id: CGWindowID { windowID }
    public let windowID: CGWindowID
    public let pid: pid_t
    public let bundleID: String?
    public let appName: String
    public let windowTitle: String?
    public let assignedAt: Date

    public init(
        windowID: CGWindowID,
        pid: pid_t,
        bundleID: String?,
        appName: String,
        windowTitle: String?,
        assignedAt: Date = Date()
    ) {
        self.windowID = windowID
        self.pid = pid
        self.bundleID = bundleID
        self.appName = appName
        self.windowTitle = windowTitle
        self.assignedAt = assignedAt
    }
}
```

### `ScratchpadState`

Explicit finite state enum representing the current operational status of the Scratchpad coordinator.

```swift
public enum ScratchpadState: Sendable, Equatable {
    case unassigned
    case visible(record: ScratchpadRecord)
    case hidden(record: ScratchpadRecord)

    public var isAssigned: Bool {
        switch self {
        case .unassigned: return false
        case .visible, .hidden: return true
        }
    }

    public var isVisible: Bool {
        switch self {
        case .visible: return true
        case .unassigned, .hidden: return false
        }
    }

    public var record: ScratchpadRecord? {
        switch self {
        case .unassigned: return nil
        case .visible(let record), .hidden(let record): return record
        }
    }
}
```

### `PreSummonFocus`

Snapshot of the window and application that held focus immediately before the Scratchpad was summoned, used for accurate focus restoration.

```swift
public struct PreSummonFocus: Sendable, Equatable {
    public let pid: pid_t
    public let windowID: CGWindowID?
    public let timestamp: Date

    public init(pid: pid_t, windowID: CGWindowID? = nil, timestamp: Date = Date()) {
        self.pid = pid
        self.windowID = windowID
        self.timestamp = timestamp
    }
}
```

---

## 2. Protocols & Seams

### `ScratchpadCoordinating`

MainActor coordinator protocol injected into `AppDependencies`, `MenuBarViewModel`, and `CommandDispatcher`.

```swift
@MainActor
public protocol ScratchpadCoordinating: AnyObject, Sendable {
    var state: ScratchpadState { get }
    var currentRecord: ScratchpadRecord? { get }
    var isVisible: Bool { get }

    func assignFocusedWindow() async -> Bool
    func toggleScratchpad() async -> Bool
    func summonScratchpad() async -> Bool
    func dismissScratchpad() async -> Bool
    func detachScratchpad()
}
```

---

## 3. Storage & Preferences Schema

### `PreferencesStore` Additions

```swift
// Keys added to PreferencesStore:
@AppStorage("scratchpadDismissOnBlur") public var scratchpadDismissOnBlur: Bool = false
@AppStorage("scratchpadDismissOnEsc") public var scratchpadDismissOnEsc: Bool = true
```

### `ShortcutAction` Additions

```swift
public enum ShortcutAction: String, CaseIterable, Codable, Sendable {
    // Existing actions...
    case togglePinFocusedWindow = "togglePinFocusedWindow"
    case toggleScratchpad = "toggleScratchpad"
    case assignScratchpad = "assignScratchpad"
}
```

Default Key Bindings:

- `ShortcutAction.toggleScratchpad`: `Option + Space` (KeyCode: 49, Modifiers: `.option`)
- `ShortcutAction.assignScratchpad`: `Control + Option + Space` (KeyCode: 49, Modifiers: `[.control, .option]`)
