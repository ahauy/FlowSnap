# Tasks: Verified Workspace Restoration

**Input**: [`spec.md`](spec.md), [`plan.md`](plan.md), [`data-model.md`](data-model.md),
[`contracts/RestoreContracts.md`](contracts/RestoreContracts.md), [`quickstart.md`](quickstart.md)

**Prerequisites**: Signed-off baseline v1.0; tests follow TDD (test-plan first).

**Organization**: Tasks are grouped by user story. `[P]` marks tasks that touch
different files and have no dependency on unfinished work.

## Phase 1: Setup (Shared Infrastructure)

- [ ] T001 Confirm the generated Xcode project includes `FlowSnap` and `FlowSnapTests` sources after `xcodegen generate` in `project.yml`
- [x] T002 Create `.specify/features/workspace-restore-verification/test-plan.md` mapping US-WRV scenarios to TC-WRV-001 through TC-WRV-019 before writing tests

## Phase 2: Foundational (Blocking Prerequisites)

- [ ] T003 [P] Inventory and update all `RestoreSummary` consumers in `FlowSnap/Core/Workspace/PresetResolver.swift`, `FlowSnap/UI/Workspace/WorkspaceViewModel.swift`, `FlowSnap/UI/Components/RestoreSummaryBanner.swift`, and `FlowSnapTests`
- [ ] T004 [P] Define immutable `RestorePlacementResult`, `RestoreIssue`, typed categories, and extended reasons in `FlowSnap/Domain/Workspace/RestoreSummary.swift`
- [ ] T005 [P] Add `RestoreVerificationPolicy`, `WindowVerificationResult`, and pure frame/state helper seams in `FlowSnap/Core/Workspace/RestoreVerification.swift`
- [ ] T006 [P] Add `isFullScreen(_:)` to `FlowSnap/Infrastructure/Accessibility/AccessibilityService.swift` and implement existing classifier reuse in `FlowSnap/Infrastructure/Accessibility/AXAccessibilityService.swift`
- [ ] T007 [P] Update `MockAccessibilityService` and shared AX fixtures for scripted fullscreen/frame/minimized reads in `FlowSnapTests/Mocks/MockAccessibilityService.swift`
- [ ] T008 Remove fixed fullscreen sleep and duplicate preparation behavior from `FlowSnap/Core/Window/WindowManager.swift`, preserving exact-element move semantics and explicit errors
- [ ] T009 Update `FlowSnap/Core/Workspace/WorkspaceRestoring.swift` documentation and result contract for typed counters/issues without changing pass-level `RestoreError`

**Checkpoint**: Domain/result contracts and AX seam compile; no restore behavior is changed until story tests exist.

## Phase 3: User Story 1 — Trustworthy Placement (Priority: P1) 🎯 MVP

**Goal**: Count a placement only after verified frame and state post-conditions,
retrying recoverable errors/mismatches and treating missing AX elements as
unverifiable.

**Independent Test**: `WorkspaceManager+Restore` tests simulate silent writes,
nil frames, minimized state, missing AX elements, and move errors.

### Tests for User Story 1

- [ ] T010 [P] [US1] Add silent-write retry and final unverifiable tests in `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`
- [ ] T011 [P] [US1] Add nil-frame, minimized-after-move, and missing-element safety tests in `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`
- [ ] T012 [P] [US1] Add move-error retry/non-recoverable classification tests in `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`

### Implementation for User Story 1

- [ ] T013 [US1] Implement exact-element guard and `MoveOutcome` mapping in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T014 [US1] Implement read-back frame/state verification with `RestoreVerificationPolicy` tolerance in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T015 [US1] Implement three-attempt retry/backoff and explicit `.moveFailed`/`.unverifiablePlacement` results in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T016 [US1] Update workspace restore fixtures and mocks to expose actual post-move AX reads in `FlowSnapTests/Mocks/MockWindowManaging.swift` and `FlowSnapTests/Mocks/MockAccessibilityService.swift`

**Checkpoint**: US1 tests pass; silent AX ignore and unverifiable targets never increment `placedCount`.

## Phase 4: User Story 2 — Deterministic Fullscreen Preparation (Priority: P1)

**Goal**: Exit and verify fullscreen before placement; timeout/throw prevents
`setFrame` and records an explicit reason.

**Independent Test**: Script fullscreen state transitions through the protocol mock
and assert polling order, timeout, and zero move calls on failure.

### Tests for User Story 2

- [ ] T017 [P] [US2] Add fullscreen exit-confirmed polling test in `FlowSnapTests/Core/Workspace/WorkspaceFullscreenRestoreTests.swift`
- [ ] T018 [P] [US2] Add fullscreen throw/timeout zero-move tests in `FlowSnapTests/Core/Workspace/WorkspaceFullscreenRestoreTests.swift`

### Implementation for User Story 2

- [ ] T019 [US2] Implement `waitForFullscreenExit` with 100ms polling and 2s policy timeout in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T020 [US2] Map fullscreen throw/timeout to `.fullscreenTransitionTimeout` before any placement attempt in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T021 [US2] Verify minimized/unminimized preparation only targets the requested `ResolvedWindow` in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`

**Checkpoint**: US2 tests pass; no fixed 700ms synchronization remains.

## Phase 5: User Story 3 — Accurate Partial Summary (Priority: P1)

**Goal**: Expose separate placed/failed/unverifiable/skipped counters and
reasoned issue groups through the existing non-blocking banner.

**Independent Test**: Run mixed outcomes and inspect summary counters, details,
and auto-dismiss behavior without a modal.

### Tests for User Story 3

- [ ] T022 [P] [US3] Add summary counter conservation and reason grouping tests in `FlowSnapTests/Core/Workspace/RestoreSummaryTests.swift`
- [ ] T023 [P] [US3] Add mixed restore outcome integration tests in `FlowSnapTests/Core/Workspace/WorkspaceManagerSummaryTests.swift`
- [ ] T024 [P] [US3] Update banner view tests/inspection fixtures for placed, failed, unverifiable, and skipped groups in `FlowSnapTests/UI/RestoreSummaryBannerTests.swift`

### Implementation for User Story 3

- [ ] T025 [US3] Aggregate typed per-placement results into counters and issue collections in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T026 [US3] Update headline/details and grouped category rendering in `FlowSnap/UI/Components/RestoreSummaryBanner.swift`
- [ ] T027 [US3] Update `WorkspaceViewModel` and preset consumers for the additive summary contract in `FlowSnap/UI/Workspace/WorkspaceViewModel.swift` and `FlowSnap/Core/Workspace/PresetResolver.swift`
- [ ] T028 [US3] Preserve existing auto-dismiss/non-modal wiring in `FlowSnap/UI/MenuBar/MenuBarView.swift` and `FlowSnap/UI/Settings/WorkspaceSettingsView.swift`

**Checkpoint**: US3 tests pass; partial failures are explicit and do not abort later placements.

## Phase 6: User Story 4 — Stable Ordering and Final Focus (Priority: P1)

**Goal**: Process placements in ascending order without per-app activation and
perform at most one final focus for the lowest-order verified result.

**Independent Test**: Use unsorted placements and scripted outcomes to assert
call order and one final focus target.

### Tests for User Story 4

- [ ] T029 [P] [US4] Add ascending-order sequential placement test in `FlowSnapTests/Core/Workspace/WorkspaceRestoreOrderingTests.swift`
- [ ] T030 [P] [US4] Add lowest-verified and no-verified final-focus tests in `FlowSnapTests/Core/Workspace/WorkspaceRestoreFocusTests.swift`

### Implementation for User Story 4

- [ ] T031 [US4] Refactor restore loop to collect verified results without per-placement reveal/activation in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T032 [US4] Implement deterministic final reveal/focus selection and preserve best-effort semantics in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T033 [US4] Update launcher/window-manager mocks to record reveal/focus calls for ordering assertions in `FlowSnapTests/Mocks/MockApplicationLaunching.swift` and `FlowSnapTests/Mocks/MockWindowManaging.swift`

**Checkpoint**: US4 tests pass; at most one final focus occurs and only for a verified placement.

## Phase 7: User Story 5 — Safe Visibility and Diagnostics (Priority: P2)

**Goal**: Keep current-Space visibility separate from placement proof and enforce
privacy-safe diagnostics while retaining the existing in-flight guard.

**Independent Test**: Run cross-Space-like fixtures and inspect diagnostic fields
and concurrent-trigger behavior.

### Tests for User Story 5

- [ ] T034 [P] [US5] Add cross-Space geometry/no-visibility-claim test in `FlowSnapTests/Core/Workspace/WorkspaceSpaceVisibilityTests.swift`
- [ ] T035 [P] [US5] Add privacy-safe diagnostics field test in `FlowSnapTests/Core/Workspace/WorkspaceRestoreLoggingTests.swift`
- [ ] T036 [P] [US5] Add repeated-restore guard regression test in `FlowSnapTests/Core/Workspace/WorkspaceRestoreConcurrencyTests.swift`

### Implementation for User Story 5

- [ ] T037 [US5] Route resolve/prepare/place/verify/final-focus diagnostics through the existing logger abstraction with allowed fields only in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
- [ ] T038 [US5] Keep display intersection/reveal behavior explicitly best-effort and out of `WindowVerificationResult` in `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`

**Checkpoint**: US5 tests pass; no title/content/screenshot logging and no current-Space proof claims.

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T039 [P] Run `xcodegen generate` and resolve source/project integration issues in `project.yml`
- [ ] T040 [P] Run full Swift Testing/XCTest suite and update compatibility assertions in `FlowSnapTests`
- [ ] T041 [P] Run `swiftlint lint --strict` and fix violations in changed Swift files
- [ ] T042 [P] Validate `quickstart.md` scripted scenarios and capture evidence in `.specify/features/workspace-restore-verification/quickstart.md`
- [ ] T043 [P] Perform non-blocking US-WORK-013 Cross-Space capability spike and record findings in `.specify/features/workspace-restore-verification/research.md`
- [ ] T044 Run `speckit-analyze` consistency check and resolve any spec/plan/tasks drift before implementation handoff

## Dependencies & Execution Order

- Setup (Phase 1) precedes Foundational (Phase 2); T002 must exist before any test task.
- Foundational (Phase 2) blocks all story phases.
- US1 is the MVP; US2 integrates with its preparation seam; US3 consumes both outcome categories; US4 consumes verified aggregate results; US5 is P2/non-blocking.
- Polish follows required P0 stories; T043 may run independently as a bounded spike.

## Parallel Opportunities

- T003–T007 can run in parallel across domain, protocol, and mock files.
- Test tasks T010–T012, T017–T018, T022–T024, T029–T030, and T034–T036 can run in parallel within their story phase.
- T039–T043 can run in parallel after implementation, subject to shared build outputs.

## Implementation Strategy

1. Create test-plan, then execute US1 red→green as the MVP correctness slice.
2. Add fullscreen preparation, summary accounting, and deterministic final focus.
3. Add privacy diagnostics and run full regression/lint/quickstart evidence.
4. Keep Cross-Space, picker app names, resolve-by-frame fallback, and cancellation outside P0 acceptance.

## Format Validation

All tasks use `- [ ]` checkboxes, sequential IDs, `[P]` only for parallel work,
`[US#]` labels for story phases, and concrete repository file paths.
