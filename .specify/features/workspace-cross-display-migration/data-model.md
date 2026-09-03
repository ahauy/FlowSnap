# Data Model & Contracts: Atomic Workspace Cross-Display Migration (US-DISP-017)

## 1. Domain Entities & Value Types

### `MigrationDirection`

```swift
public enum MigrationDirection: String, Sendable, Codable, CaseIterable {
    case next
    case previous
}
```

### `MigrationResult`

```swift
public enum MigrationResult: Equatable, Sendable {
    case success(windowsMigrated: Int, targetDisplayID: CGDirectDisplayID)
    case noOp(reason: NoOpReason)

    public enum NoOpReason: Equatable, Sendable {
        case singleDisplay
        case noActiveWorkspace
        case noWindowsFound
        case accessibilityDenied
    }
}
```

### `WorkspaceMigrating` Protocol

```swift
@MainActor
public protocol WorkspaceMigrating: AnyObject {
    /// Migrates the active workspace on the focused display in the given direction.
    ///
    /// - Parameter direction: .next or .previous.
    /// - Returns: MigrationResult indicating success count or noOp reason.
    func migrateActiveWorkspace(
        direction: MigrationDirection
    ) async throws -> MigrationResult
}
```

---

## 2. Updated Entities

### `WindowCommand`

```swift
public enum WindowCommand: Hashable, Sendable {
    // ... existing commands ...
    case migrateWorkspace(MigrationDirection)
}
```

### `ShortcutAction`

```swift
public enum ShortcutAction: String, CaseIterable, Codable, Sendable, Identifiable {
    // ... existing actions ...
    case moveWorkspaceNextDisplay = "moveWorkspaceNextDisplay"
    case moveWorkspacePreviousDisplay = "moveWorkspacePreviousDisplay"
}
```
