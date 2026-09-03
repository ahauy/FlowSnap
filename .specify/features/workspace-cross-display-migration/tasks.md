# Tasks: Atomic Workspace Cross-Display Migration (US-DISP-017)

## Phase 1: Domain Contracts & Commands (Data Layer)

- [ ] `T001`: Create `FlowSnap/Domain/Workspace/WorkspaceMigrating.swift` defining `MigrationDirection`, `MigrationResult`, and `WorkspaceMigrating`.
- [ ] `T002`: Add `.migrateWorkspace(MigrationDirection)` to `FlowSnap/Domain/Commands/WindowCommand.swift`.
- [ ] `T003`: Add `.moveWorkspaceNextDisplay` and `.moveWorkspacePreviousDisplay` to `FlowSnap/Domain/Hotkeys/ShortcutAction.swift` with default keycodes and `⌃⌥⇧⌘` modifier chords.

## Phase 2: Core Migration Logic (Logic Layer)

- [ ] `T004`: Implement `WorkspaceMigrator.swift` in `FlowSnap/Core/Workspace/` with:
  - Source/target display resolution using `DisplayNavigating`.
  - Active workspace window matching on `sourceDisplay`.
  - Proportional multi-window frame scaling using `RelativeFrameScaler`.
  - 2-phase move ordering (Stage Manager OFF) and Anchor-first + 40ms stagger + `kAXRaiseAction` (Stage Manager ON).
  - Cursor warping to primary window center and `AdaptiveDividerCoordinator` handoff.
  - Fail-soft graceful no-op handling.
- [ ] `T005`: Create `WorkspaceManager+Migration.swift` providing `migrateActiveWorkspace(direction:)` on `WorkspaceManager`.

## Phase 3: Dispatcher & UI Integration (API & UI Layer)

- [ ] `T006`: Wire `workspaceMigrator` into `CommandDispatcher.swift` to execute `.migrateWorkspace`.
- [ ] `T007`: Wire `WorkspaceMigrator` in `AppDependencies.swift`.
- [ ] `T008`: Add "Move Workspace to Next Display" / "Previous Display" to `MenuBarViewModel.swift` & `MenuBarView.swift`.

## Phase 4: Verification & TDD (Testing Layer)

- [ ] `T009`: Implement unit tests in `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`:
  - 2-window migration across different resolutions.
  - 3-window migration with 2-phase move ordering.
  - Stage Manager ON migration with staggered IPC delay & `kAXRaiseAction`.
  - Single display safe no-op.
  - No active workspace safe no-op.
  - Mouse cursor warp assertion.
- [ ] `T010`: Regenerate Xcode project with `xcodegen generate` and run `xcodebuild test` to ensure 100% test pass rate.
