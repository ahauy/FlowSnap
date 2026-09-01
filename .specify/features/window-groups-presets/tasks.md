# Tasks: Window Groups & Workspace Presets (US-WORK-012)

**Feature Slug:** `window-groups-presets`  
**Spec:** [.specify/features/window-groups-presets/spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/window-groups-presets/spec.md)  
**Plan:** [.specify/features/window-groups-presets/plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/window-groups-presets/plan.md)  
**Data Model:** [.specify/features/window-groups-presets/data-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/window-groups-presets/data-model.md)  
**Contracts:** [.specify/features/window-groups-presets/contracts/](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/window-groups-presets/contracts/)  
**DoD:** Swift 6 strict concurrency, no force unwrap/try!/as!, file < 800 LOC, function < 50 LOC, `swiftlint lint --strict` clean, Swift Testing `@Test`, zero private API.

---

## Phase 1: Setup & Domain Models (Foundation)

**Purpose**: Establish pure immutable domain models and factories for presets and window groups.

- [x] T001 [P] Create `PresetAppCategory.swift` and `PresetAppSlot.swift` in `FlowSnap/Domain/Workspace/PresetAppSlot.swift`
- [x] T002 [P] Create `WorkspacePreset.swift` in `FlowSnap/Domain/Workspace/WorkspacePreset.swift`
- [x] T003 [P] Create `BuiltinPresetFactory.swift` in `FlowSnap/Domain/Workspace/BuiltinPresetFactory.swift` defining 4 immutable presets (`Coding`, `Research`, `Writing`, `Design`)
- [x] T004 [P] Create `GroupSyncOptions.swift` and `WindowGroup.swift` in `FlowSnap/Domain/Window/WindowGroup.swift`
- [x] T005 [P] Create unit tests in `FlowSnapTests/Domain/PresetAndGroupModelTests.swift` validating domain model properties, Codable round-trip, and hashability

---

## Phase 2: Foundational Infrastructure & Engines (Blocking Prerequisites)

**Purpose**: Core infrastructure and coordinator foundations required across all user stories.

- [x] T006 [P] Extend `WindowCommand` enum in `FlowSnap/Domain/Commands/WindowCommand.swift` with `.restorePreset(String)` case
- [x] T007 [P] Extend `WindowManaging` protocol and `WindowManager.swift` in `FlowSnap/Core/Window/` to implement `minimize(_:)` and `unminimize(_:)` via `AccessibilityService`
- [x] T008 Implement `WindowGroupManager` coordinator in `FlowSnap/Core/Window/WindowGroupManager.swift` with group creation, dissolution, member pruning, and re-entrancy generation locking
- [x] T009 [P] Create unit tests in `FlowSnapTests/Core/WindowGroupManagerTests.swift` testing group membership cardinality, auto-dissolution (<2 members), and re-entrancy locking

---

## Phase 3: User Story 1 — Activate Built-in Workflow Presets (Priority: P1) 🎯 MVP

**Goal**: Enable instant restoration of standard curated workflow presets via hotkey or menu bar across active displays.  
**Independent Test**: Press `⌃⌥C` with running editor, browser, and terminal; verify 60/25/15 layout framing on active display.

- [x] T010 [P] [US1] Create unit tests in `FlowSnapTests/Core/PresetResolverTests.swift` validating zone calculations across standard and ultrawide displays
- [x] T011 [US1] Implement `PresetResolving` protocol and `PresetResolver` engine in `FlowSnap/Core/Workspace/PresetResolver.swift` for preset layout computation and window placement
- [x] T012 [US1] Integrate `PresetResolver` into `FlowSnap/Core/Commands/CommandDispatcher.swift` to route `.restorePreset(id)` with latest-wins cancellation debouncing
- [x] T013 [US1] Integrate Presets submenu and trigger actions into `FlowSnap/UI/MenuBar/MenuBarViewModel.swift` and `FlowSnap/UI/MenuBar/MenuBarView.swift`
- [x] T014 [P] [US1] Create integration tests in `FlowSnapTests/Core/PresetActivationIntegrationTests.swift` validating end-to-end preset dispatch

---

## Phase 4: User Story 2 — Smart App Category Fallback & Resilient Launch (Priority: P2)

**Goal**: Resolve fallback candidate applications when primary tools are missing; launch installed apps with bounded 10.0s timeout.  
**Independent Test**: Trigger Coding preset when VS Code is missing; verify Xcode or TextEdit is resolved, launched, and placed with graceful summary.

- [x] T015 [P] [US2] Create unit tests in `FlowSnapTests/Core/PresetFallbackResolutionTests.swift` testing candidate matching chains (running → installed → timeout → skip)
- [x] T016 [US2] Implement candidate fallback resolution and bounded auto-launch (≤10.0s) in `FlowSnap/Core/Workspace/PresetResolver.swift`
- [x] T017 [US2] Create non-blocking `RestoreSummaryBanner.swift` in `FlowSnap/UI/Components/RestoreSummaryBanner.swift` displaying placed count and skipped app reasons

---

## Phase 5: User Story 3 — Link & Synchronize Window Groups (Priority: P3)

**Goal**: Coordinate simultaneous minimize/un-minimize, focus with relative z-order, and movement across linked window group members.  
**Independent Test**: Minimize one window in a 2-window group; verify both windows minimize together and restore together without feedback loops.

- [x] T018 [P] [US3] Create unit tests in `FlowSnapTests/Core/WindowGroupSyncTests.swift` testing simultaneous minimize, focus, and move synchronization
- [x] T019 [US3] Implement `handleWindowMinimize` and `handleWindowRestore` in `FlowSnap/Core/Window/WindowGroupManager.swift`
- [x] T020 [US3] Implement `handleWindowFocus` with descending z-order preservation (anchor raised last) in `FlowSnap/Core/Window/WindowGroupManager.swift`
- [x] T021 [US3] Implement `handleWindowMove` with relative delta translation in `FlowSnap/Core/Window/WindowGroupManager.swift`
- [ ] T022 [US3] Connect window destruction events (`kAXUIElementDestroyedNotification`) in `FlowSnap/Infrastructure/Accessibility/AXAccessibilityService.swift` to invoke `WindowGroupManager.handleWindowDestroyed`

---

## Phase 6: User Story 4 — Presets Gallery & Hotkey Customization (Priority: P4)

**Goal**: Provide a native Settings Presets Gallery tab for visual preset inspection and shortcut recording with collision prevention.  
**Independent Test**: Record shortcut `⌃⌥⇧R` for Research preset in Settings; attempt colliding `⌃⌥←` and verify collision rejection.

- [x] T023 [P] [US4] Create unit tests in `FlowSnapTests/Infrastructure/PresetShortcutTests.swift` validating shortcut persistence and collision checking
- [x] T024 [US4] Extend `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift` with preset shortcut persistence and `hasPresetConflict` validation
- [x] T025 [US4] Update `FlowSnap/Infrastructure/Hotkeys/GlobalHotkeyManager.swift` to register active preset shortcuts dynamically
- [x] T026 [P] [US4] Create `PresetGalleryView.swift` in `FlowSnap/UI/Settings/PresetGalleryView.swift` with schematic layout cards and shortcut recorders
- [x] T027 [P] [US4] Create `WindowGroupSettingsView.swift` in `FlowSnap/UI/Settings/WindowGroupSettingsView.swift` with active groups list and sync toggles
- [x] T028 [US4] Register "Presets" and "Window Groups" tabs in `FlowSnap/UI/Settings/SettingsView.swift` and wire dependencies in `FlowSnap/App/AppDependencies.swift`

---

## Phase 7: Polish, Quality & Documentation

**Purpose**: Ensure 100% conformance to Definition of Done, strict concurrency, tests, and documentation.

- [x] T029 Run `xcodegen generate` and verify clean build with Swift 6 strict concurrency (`xcodebuild build -scheme FlowSnap`)
- [x] T030 Run `swiftlint lint --strict` and execute full test suite (`xcodebuild test -scheme FlowSnapTests`), fixing any compiler or linter issues
- [ ] T031 [P] Create technical documentation in `docs/features/window-groups-presets/README.md` and user guide in `docs/user-guides/window-groups-presets.md`
- [ ] T032 [P] Update `docs/PRODUCT_BACKLOG_ROADMAP.md` marking Epic 10 / US-WORK-012 with evidence links upon completion

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Domain Models)**: Can start immediately. No dependencies.
- **Phase 2 (Foundational)**: Depends on Phase 1 completion — BLOCKS all user stories.
- **Phase 3 (User Story 1 - MVP)**: Depends on Phase 2 completion.
- **Phase 4 (User Story 2)**: Depends on Phase 3 (extends `PresetResolver`).
- **Phase 5 (User Story 3)**: Depends on Phase 2 (uses `WindowGroupManager`). Can run in parallel with US1/US2.
- **Phase 6 (User Story 4)**: Depends on Phase 1 & 2 (UI settings and hotkeys).
- **Phase 7 (Polish & Quality)**: Depends on all user story implementations being complete.

### Parallel Execution Opportunities

- Tasks marked `[P]` within each phase operate on separate files and can execute concurrently.
- User Story 1 (Presets Engine) and User Story 3 (Window Group Sync) can be developed concurrently once Phase 2 foundational tasks are complete.

---

## Implementation Strategy (MVP First)

1. **Step 1 (MVP)**: Complete Phase 1 (Domain) + Phase 2 (Foundational) + Phase 3 (US1: Presets Activation).
   - _Outcome_: Working preset activation for running apps via hotkey & menu bar.
2. **Step 2**: Complete Phase 4 (US2: Smart Fallbacks).
   - _Outcome_: Robust candidate resolution and auto-launch for missing apps.
3. **Step 3**: Complete Phase 5 (US3: Group Synchronization).
   - _Outcome_: Linked window group minimize, focus, and move coordination.
4. **Step 4**: Complete Phase 6 (US4: Settings Gallery & Hotkeys).
   - _Outcome_: Full UI discovery, customization, and collision detection.
5. **Step 5**: Complete Phase 7 (DoD Quality & Docs).
   - _Outcome_: Strict concurrency clean, zero lint warnings, 100% tests passing, roadmap updated.
