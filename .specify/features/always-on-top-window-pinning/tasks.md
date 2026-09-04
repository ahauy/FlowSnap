# Tasks: Universal Always-On-Top Pinning & Stage Manager Launch Co-existence (US-SNAP-021)

- **Feature**: `always-on-top-window-pinning`
- **Story ID**: `US-SNAP-021`
- **Status**: Ready for Implementation (Phase 5)

---

## Task Decomposition & Dependency Ordering

### [Phase 5.1: Domain & Contracts]

- [ ] **Task 1: Domain Entities & Protocols**
  - **Files**:
    - `FlowSnap/Domain/Policy/PinnedWindowRecord.swift`
    - `FlowSnap/Domain/Policy/WindowPinningCoordinating.swift`
    - `FlowSnap/Domain/StageManager/StageManagerLaunchCoordinating.swift`
  - **Verification**: Clean Sendable models and protocols compiling without warnings.

- [ ] **Task 2: Action & Preferences Contracts**
  - **Files**:
    - `FlowSnap/Domain/Shortcut/ShortcutAction.swift` (add `.togglePinFocusedWindow`)
    - `FlowSnap/Core/Storage/PreferencesStore.swift` (add `stageManagerLaunchCoexistenceEnabled`)
  - **Verification**: New shortcut action and preferences key exposed for UI & dispatcher.

---

### [Phase 5.2: Test Doubles & TDD Red Suite]

- [ ] **Task 3: Test Plan & Test Doubles**
  - **Files**:
    - `.specify/features/always-on-top-window-pinning/test-plan.md`
    - `FlowSnapTests/Mocks/MockWindowPinningCoordinator.swift`
    - `FlowSnapTests/Mocks/MockStageManagerLaunchCoordinator.swift`
  - **Verification**: Mock coordinators capture toggle, unpin, focus change, and launch events.

- [ ] **Task 4: Write Failing Unit Tests (Red)**
  - **Files**:
    - `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`
    - `FlowSnapTests/Infrastructure/StageManagerLaunchCoordinatorTests.swift`
  - **Verification**: Comprehensive tests assert LIFO stacking, re-assertion, modal safety, app termination cleanup, and launch co-existence; fail before implementation (Red).

---

### [Phase 5.3: Core & Infrastructure Implementation (Green Suite)]

- [ ] **Task 5: WindowPinningCoordinator Implementation**
  - **Files**: `FlowSnap/Core/Policy/WindowPinningCoordinator.swift`
  - **Verification**: Manages LIFO stack, handles focus changes, re-asserts pinned windows via `kAXRaiseAction`, safely suspends on system modals, cleans up on process termination; tests pass.

- [ ] **Task 6: StageManagerLaunchCoordinator Implementation**
  - **Files**: `FlowSnap/Infrastructure/StageManager/StageManagerLaunchCoordinator.swift`
  - **Verification**: Listens to application launch notifications, waits for window creation via `ApplicationObserving`, and multi-raises existing stage windows; tests pass.

- [ ] **Task 7: CommandDispatcher & Hotkey Integration**
  - **Files**:
    - `FlowSnap/Core/Dispatcher/CommandDispatcher.swift`
    - `FlowSnap/Core/Hotkeys/GlobalHotkeyManager.swift`
  - **Verification**: Pressing `⌃⌥P` triggers `togglePinFocusedWindow`.

- [ ] **Task 8: UI Menu Bar & Settings Integration**
  - **Files**:
    - `FlowSnap/UI/MenuBar/MenuBarViewModel.swift`
    - `FlowSnap/UI/MenuBar/MenuBarView.swift`
    - `FlowSnap/UI/Settings/SettingsView.swift`
  - **Verification**: Menu Bar displays pinned window list with unpin actions; Settings includes Stage Manager Launch Co-existence toggle.

- [ ] **Task 9: AppDependencies Wiring**
  - **Files**: `FlowSnap/App/AppDependencies.swift`
  - **Verification**: Initializes and injects `WindowPinningCoordinator` and `StageManagerLaunchCoordinator`.

---

### [Phase 5.4: Build, Lint & Verification]

- [ ] **Task 10: XcodeGen & Full Test Suite Run**
  - **Commands**:
    - `xcodegen generate`
    - `swiftlint lint --strict`
    - `xcodebuild test -scheme FlowSnap -destination 'platform=macOS'`
  - **Verification**: Zero warnings, 100% test pass rate.
