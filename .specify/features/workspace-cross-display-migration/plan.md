# Technical Plan: Atomic Workspace Cross-Display Migration (US-DISP-017)

## 1. Architecture & Module Design

### Deep Module Seam

The cross-display workspace migration is encapsulated within `WorkspaceMigrator`, conforming to the protocol `WorkspaceMigrating`.
This keeps the public interface minimal:

```swift
@MainActor
public protocol WorkspaceMigrating: AnyObject {
    func migrateActiveWorkspace(
        direction: MigrationDirection
    ) async throws -> MigrationResult
}
```

All low-level complexities (display navigation, geometric proportional scaling, 2-phase move ordering, Stage Manager IPC staggering and `kAXRaiseAction`, cursor warping, divider overlay invalidation) remain private inside `WorkspaceMigrator`.

```
                  ┌──────────────────────┐
                  │ GlobalHotkeyManager  │ ⌃⌥⇧⌘→ / ⌃⌥⇧⌘←
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  CommandDispatcher   │ .migrateWorkspace(.next)
                  └──────────┬───────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  WorkspaceMigrator   │ (WorkspaceMigrating)
                  └──────────┬───────────┘
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│DisplayNavigator │ │RelativeFrame    │ │StageManager     │
│(targetDisplay)  │ │Scaler (frames)  │ │Detector         │
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
                    ┌─────────────────┐
                    │ WindowManaging  │ (move windows)
                    │  Accessibility  │ (kAXRaiseAction)
                    │  CursorWarping  │ (warp cursor)
                    │ AdaptiveDivider │ (transfer seam)
                    └─────────────────┘
```

---

## 2. File Manifest & Component Responsibilities

### [NEW] `FlowSnap/Domain/Workspace/WorkspaceMigrating.swift`

- Defines `MigrationDirection` (`.next`, `.previous`).
- Defines `MigrationResult` (`.success(windowsMigrated:targetDisplayID:)`, `.noOp(reason:)`).
- Defines `@MainActor public protocol WorkspaceMigrating`.

### [NEW] `FlowSnap/Core/Workspace/WorkspaceMigrator.swift`

- Implements `WorkspaceMigrating`.
- Injects `DisplayManaging`, `DisplayNavigating`, `WindowManaging`, `AccessibilityServing`, `CursorWarping`, `StageManagerDetecting`, `PreferencesStore`, `AdaptiveDividerCoordinating` (or coordinator instance).
- Implements 2-phase move order for non-Stage Manager setups, and Staggered IPC (40ms) + `kAXRaiseAction` when Stage Manager is active.
- Warps cursor to center of primary window on target display.

### [MODIFY] `FlowSnap/Domain/Commands/WindowCommand.swift`

- Add `case migrateWorkspace(MigrationDirection)` to enum `WindowCommand`.

### [MODIFY] `FlowSnap/Domain/Hotkeys/ShortcutAction.swift`

- Add `case moveWorkspaceNextDisplay = "moveWorkspaceNextDisplay"`
- Add `case moveWorkspacePreviousDisplay = "moveWorkspacePreviousDisplay"`
- Map to default shortcuts: `⌃⌥⇧⌘→` (keyCode 124, modifiers: ctrl+opt+shift+cmd) and `⌃⌥⇧⌘←` (keyCode 123, modifiers: ctrl+opt+shift+cmd).
- Map to default commands: `.migrateWorkspace(.next)` and `.migrateWorkspace(.previous)`.

### [MODIFY] `FlowSnap/Core/Commands/CommandDispatcher.swift`

- Inject `workspaceMigrator: (any WorkspaceMigrating)?`.
- Route `.migrateWorkspace(let direction)` to `workspaceMigrator.migrateActiveWorkspace(direction: direction)`.

### [MODIFY] `FlowSnap/App/AppDependencies.swift`

- Instantiate `WorkspaceMigrator` and wire to `CommandDispatcher`, `GlobalHotkeyManager`, and `MenuBarViewModel`.

### [MODIFY] `FlowSnap/UI/MenuBar/MenuBarViewModel.swift` & `MenuBarView.swift`

- Expose "Move Workspace to Next Display" in Quick Controls menu when multiple displays are connected.

### [NEW] `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`

- Comprehensive unit tests:
  - 2-window migration across different display resolutions.
  - 3-window migration with 2-phase move ordering.
  - Stage Manager ON migration with staggered IPC and `kAXRaiseAction` verification.
  - Single display no-op test.
  - No active workspace on source display no-op test.
  - Mouse cursor warp assertion.
