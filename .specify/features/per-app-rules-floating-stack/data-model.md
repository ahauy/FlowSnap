# Data Model — Per-App Window Policies & Smart Floating Stack (US-WORK-014)

> DTOs, value types, and lifecycle states introduced by US-WORK-014.
> All types are `Sendable` or actor-isolated per Swift 6 strict concurrency.

## 1. New & Extended Types

### 1.1 `WindowPolicy` (extended enum, Domain)

```swift
public enum WindowPolicy: Codable, Hashable, Sendable {
    case currentSpace
    case currentDisplay
    case floating
    case rememberPosition
    case assignedLayout(LayoutZone)
    case assignedWorkspace(UUID)
}
```

- **Location**: `FlowSnap/Domain/Window/WindowPolicy.swift`
- **Associated Values**:
  - `assignedLayout(LayoutZone)` holds the canonical target `LayoutZone` (`.leftHalf`, `.rightHalf`, `.left70_30`, etc.).
  - `assignedWorkspace(UUID)` holds the target workspace ID.

### 1.2 `AppPolicyRule` (struct, Domain)

```swift
public struct AppPolicyRule: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let bundleID: String
    public var appName: String
    public var policy: WindowPolicy
    public var iconName: String

    public init(
        id: UUID = UUID(),
        bundleID: String,
        appName: String,
        policy: WindowPolicy,
        iconName: String = "app.dashed"
    ) {
        self.id = id
        self.bundleID = bundleID
        self.appName = appName
        self.policy = policy
        self.iconName = iconName
    }
}
```

- **Location**: `FlowSnap/Domain/Policy/AppPolicyRule.swift`
- **Usage**: Encapsulates one custom rule mapping a specific application's `bundleIdentifier` to a `WindowPolicy`.

### 1.3 `RememberedFrame` (struct, Domain)

```swift
public struct RememberedFrame: Codable, Hashable, Sendable {
    public let bundleID: String
    public let frame: CGRect
    public let displayID: CGDirectDisplayID?
    public let savedAt: Date

    public init(
        bundleID: String,
        frame: CGRect,
        displayID: CGDirectDisplayID? = nil,
        savedAt: Date = Date()
    ) {
        self.bundleID = bundleID
        self.frame = frame
        self.displayID = displayID
        self.savedAt = savedAt
    }
}
```

- **Location**: `FlowSnap/Domain/Policy/RememberedFrame.swift`
- **Usage**: Persists the last geometry for an app with a timestamp and origin display identifier.

### 1.4 `SmartFocusStack` (class / struct, Core)

```swift
@MainActor
public final class SmartFocusStack {
    private var windowHistory: [CGWindowID] = []
    private var floatingWindowIDs: Set<CGWindowID> = []

    public init() {}

    public func recordFocus(windowID: CGWindowID, isFloating: Bool) {
        if isFloating {
            floatingWindowIDs.insert(windowID)
        } else {
            windowHistory.removeAll { $0 == windowID }
            windowHistory.append(windowID)
        }
    }

    public func removeFloatingWindow(windowID: CGWindowID) -> CGWindowID? {
        floatingWindowIDs.remove(windowID)
        return windowHistory.last
    }
}
```

- **Location**: `FlowSnap/Core/Policy/SmartFocusStack.swift`
- **Usage**: Tracks MRU focus order so that closing a floating window brings the preceding non-floating window back to active focus.

---

## 2. Persistence Model in `PreferencesStore`

```swift
// Added to PreferencesStore:
@Published public private(set) var appRules: [AppPolicyRule]
@Published public private(set) var rememberedFrames: [String: RememberedFrame]

public func setAppRule(_ rule: AppPolicyRule)
public func removeAppRule(forBundleID bundleID: String)
public func saveRememberedFrame(_ frame: CGRect, forBundleID bundleID: String, displayID: CGDirectDisplayID?)
public func rememberedFrame(forBundleID bundleID: String) -> RememberedFrame?
```

- Stored in `UserDefaults` under keys:
  - `"appPolicyRules"` (JSON encoded `[AppPolicyRule]`)
  - `"rememberedFrames"` (JSON encoded `[String: RememberedFrame]`)
