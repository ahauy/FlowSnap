# Tasks: Workspace Snapshot & Restoration (US-WORK-011)

**Feature Slug:** `workspace-snapshot-restoration` · **Status:** Complete (T001–T020, plus T021 post-verify fix). Build clean, `swiftlint --strict` clean, `265/265` tests passing, docs shipped.
**DoD:** Swift 6 strict concurrency, no force unwrap/try!/as!, file < 800 LOC, function < 50 LOC,
`swiftlint lint --strict` clean, Swift Testing `@Test`, zero private API.

## Phase 1 — Domain & Persistence (foundation)

- [x] T001 [P] Reshape `FlowSnap/Domain/Workspace/WindowPlacement.swift` per ADR-001:
      `bundleIdentifier: String, zone: LayoutZone, expectedWindowCount: Int, orderIndex: Int`.
- [x] T002 [P] Extend `FlowSnap/Domain/Workspace/Workspace.swift`: add `Sendable`, `createdAt`,
      `lastRestoredAt`, `schemaVersion`-aware envelope types (`WorkspaceDocument`).
- [x] T003 [P] Create `FlowSnap/Domain/Workspace/RestoreSummary.swift`:
      `RestoreSummary`, `SkippedApp`, `SkipReason`, `WorkspaceError`.
- [x] T004 Rewrite `FlowSnap/Infrastructure/Persistence/WorkspaceStore.swift` as actor (ADR-003):
      async load/save/upsert/delete, atomic temp+rename, corrupt-file typed error, injectable
      directory; remove layouts stubs and the `.first!` force unwrap.
- [x] T005 [P] Tests `FlowSnapTests/Infrastructure/WorkspaceStoreTests.swift`:
      round-trip, missing file → [], corrupt JSON → corruptFile, atomic overwrite, upsert/delete.

## Phase 2 — Core Orchestration

- [x] T006 Create `FlowSnap/Infrastructure/macOS/AppLauncher.swift` (ADR-004):
      `ApplicationLaunching` protocol + NSWorkspace production impl + AX first-window polling.
- [x] T007 Implement `WorkspaceManager.saveCurrentAsWorkspace(name:icon:)`:
      eligibility filter, bundle-id grouping, zone inference (max-IoU, deterministic tie-break),
      count capture, orderIndex, uniqueness guard, store upsert.
- [x] T008 Implement `WorkspaceManager.restore(_:)`:
      pre-flight AX trust, target display resolution (focused→cursor→primary), placement loop,
      auto-launch + 10s wait, primary→zone frame via LayoutEngine with current gap, cascade
      extras with clamping, per-window error tolerance, RestoreSummary.
- [x] T009 [P] Tests `FlowSnapTests/Core/WorkspaceManagerSaveTests.swift`:
      zone inference (exact/tie-break/oversized), grouping, count capture, duplicate-name,
      empty-name, no-eligible-windows.
- [x] T010 [P] Tests `FlowSnapTests/Core/WorkspaceManagerRestoreTests.swift`:
      happy path, notInstalled skip, launchTimeout skip, noWindow skip, cascade clamping,
      fewer/more windows than saved, AX move failure tolerance, summary correctness.
- [x] T011 [P] Tests `FlowSnapTests/Core/WorkspaceCrossDisplayTests.swift` (mandatory E8):
      save on 1440x900 visibleFrame → restore on 2560x1440 visibleFrame → assert recomputed
      frames match zone ratios, not saved pixels.

## Phase 3 — UI Integration

- [x] T012 Create `FlowSnap/UI/Workspace/WorkspaceSaveSheet.swift` (name + curated SF Symbol
      grid, inline errors E1/E2/E3).
- [x] T013 Create `FlowSnap/UI/Workspace/WorkspaceListView.swift` (rows, Restore button,
      empty state) and wire into `MenuBarView` + `MenuBarViewModel`.
- [x] T014 Create `FlowSnap/UI/Settings/WorkspaceSettingsView.swift` (list/rename/delete/restore
      with confirmation) and register the "Workspaces" tab in `SettingsView`.
- [x] T015 [P] Tests `FlowSnapTests/UI/WorkspaceViewModelTests.swift`: save/restore/delete
      flows via mocked manager, summary surfacing, error states.

## Phase 4 — Quality & Docs

- [x] T016 Run `xcodegen generate`; build app + test targets; fix all warnings (strict concurrency).
      Result: `xcodebuild build` → BUILD SUCCEEDED, no warnings in owned files (fixed unused
      `height` binding in `WorkspaceManager+Restore.swift:184` → `!= nil` guard).
- [x] T017 Run `swiftlint lint --strict` and full test suite; fix violations.
      Result: 0 violations across all owned files (renamed short identifiers `fm`/`ws`/`ax` →
      `fileManager`/`workspace`/`accessibility`); `261/261` tests pass across 35 suites.
- [x] T018 [P] Update `docs/` technical documentation + user guide (save/restore flows).
      Added `docs/features/workspace-snapshot-restoration/README.md` and
      `docs/user-guides/workspace-snapshot-restoration.md`; registered both in their indexes.
      Illustrations: `scripts/render_workspace_screenshots.swift` generates 3 Retina-2x mockups
      into `docs/user-guides/images/workspace-snapshot-restoration/` (save sheet, Menu Bar
      Workspaces section, Settings Workspaces tab), embedded at the matching steps.
- [x] T019 Update roadmap: mark US-WORK-011 `[x]` with evidence links (only after DoD met).
      `docs/PRODUCT_BACKLOG_ROADMAP.md`: story + all AC/tasks sub-items checked.
- [x] T020 [P] Update feature CHANGELOG.md and traceability-matrix.md with final file/test list.
- [x] T021 POST-VERIFY FIX — "restored but invisible" (spec §2 J2.3, E5/E10 boundary).
      Symptom: a restore could report `Restored 3/3` while the user saw nothing change.
      Cause: a hidden app (Cmd+H) or one whose windows sit on another Space still exposes a
      fully addressable AX window with a real frame, so `matchingWindows` found it, the move
      succeeded, and the pass counted it `placed` — but nothing was ever surfaced to the user.
      Fix: `ApplicationLaunching.reveal(bundleID:)` (best-effort; `AppLauncher` un-hides then
      `activate(options: [.activateAllWindows])`), called from `WorkspaceManager+Restore` once
      per placement *after* the move so the app is never flashed at its old position. A refused
      activation deliberately does not downgrade a `placed` outcome.
      Tests: +4 in `FlowSnapTests/Core/Workspace/WorkspaceRestoreRevealTests.swift` (placed →
      revealed; E4 unplaced → not revealed; E6 move-failed → not revealed; refused reveal keeps
      `placed`). `MockApplicationLaunching` gains `revealAttempts` / `unrevealableBundleIDs`.
      Also extracted `place(...)` + `move(...)` from `restore(_:displays:options:)` to stay inside
      the `function_body_length` limit.
      Result: `xcodebuild build` SUCCEEDED; `swiftlint --strict` clean in owned files; full suite
      `265/265` across 36 suites.

## Dependency Notes

- T004 depends on T002/T003 (types). T007/T008 depend on T004/T006.
- T012–T014 depend on T007/T008. T016 depends on all code tasks; T017 on T016.
- [P] = parallelizable within its phase.
