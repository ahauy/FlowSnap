# Changelog: US-DISP-017 Atomic Workspace Cross-Display Migration

## [1.0.0] - 2026-09-04

### Added

- **Domain Protocol & Types (`FlowSnap/Domain/Workspace/WorkspaceMigrating.swift`)**:
  - `MigrationDirection` enum (`.next`, `.previous`).
  - `MigrationResult` enum (`.success(windowsMigrated:targetDisplayID:)`, `.noOp(reason:)`).
  - `WorkspaceMigrating` protocol.
- **Core Migration Service (`FlowSnap/Core/Workspace/WorkspaceMigrator.swift`)**:
  - `WorkspaceMigrator` coordinator implementing `WorkspaceMigrating`.
  - Topology resolution for source and target display via `DisplayNavigator`.
  - Proportional geometry scaling via `RelativeFrameScaler`.
  - Adaptive move ordering:
    - Stage Manager Active: Staggered IPC (40ms) + `kAXRaiseAction` on secondary windows + final focus lock on Anchor window without stage swaps.
    - Stage Manager Inactive: Two-phase transit (shrinking windows first, expanding windows second).
  - Post-migration cursor warping to primary window center on destination display.
  - Primary window focus activation via `WindowManager.focus(_:)`.
  - Seamless `AdaptiveDividerCoordinator.resetState()` invocation.
- **Command & Shortcut Routing**:
  - Added `.migrateWorkspace(MigrationDirection)` to `WindowCommand`.
  - Added `.moveWorkspaceNextDisplay` (`⌃⌥⇧⌘→`) and `.moveWorkspacePreviousDisplay` (`⌃⌥⇧⌘←`) to `ShortcutAction`.
  - Wired `WorkspaceMigrator` into `CommandDispatcher`.
  - Added "Move Workspace to Next Display" button in `MenuBarView`.
- **Unit & Integration Test Suite (`FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`)**:
  - 7 test cases covering `TC-MIG-001` through `TC-MIG-007`.
- **Architectural & Technical Documentation**:
  - `adr/0014-workspace-cross-display-migration.md`.
  - `docs/features/workspace-cross-display-migration/README.md`.
  - `docs/user-guides/workspace-cross-display-migration.md`.

### Fixed

- Fixed re-entrancy defect in `WorkspaceManager+Restore.swift` (`guard restoringID == nil || restoringID == workspace.id else`).
