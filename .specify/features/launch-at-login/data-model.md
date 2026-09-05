# Data Model: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: `launch-at-login`
- **Story ID**: `US-SNAP-024`
- **Date**: 2026-09-05

---

## 1. Domain Entities & Value Types

### `LaunchAtLoginStatus`

```swift
/// Represents the operating-system-level status of FlowSnap as a login item.
public enum LaunchAtLoginStatus: Sendable, Equatable {
    case enabled
    case notRegistered
    case requiresApproval
    case notFound
    case error(String)

    public var isEnabled: Bool {
        self == .enabled
    }

    public var requiresUserApproval: Bool {
        self == .requiresApproval
    }
}
```

---

## 2. Protocols & Interfaces

### `LaunchAtLoginManaging`

```swift
/// Protocol defining the login item management contract.
public protocol LaunchAtLoginManaging: Sendable {
    /// Returns the current SMAppService status mapped to LaunchAtLoginStatus.
    func currentStatus() -> LaunchAtLoginStatus

    /// Registers the app with the ServiceManagement framework.
    func register() throws

    /// Unregisters the app from the ServiceManagement framework.
    func unregister() throws

    /// Directs the user to macOS System Settings > Login Items.
    func openSystemSettings()
}
```

---

## 3. Store Integration

### `PreferencesStore` updates

```swift
// Published status properties
@Published public private(set) var launchAtLoginStatus: LaunchAtLoginStatus

// Initialization parameter
public init(
    defaults: UserDefaults = .standard,
    launchAtLoginManager: (any LaunchAtLoginManaging)? = nil
)

// Actions
public func setLaunchAtLogin(_ enabled: Bool)
public func refreshLaunchAtLoginStatus()
```
