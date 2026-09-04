# Tasks: Quake-Style Quick Scratchpad & Instant Window Toggle (US-SNAP-022)

- **Feature**: `quake-scratchpad-instant-toggle`
- **Story ID**: `US-SNAP-022`
- **Status**: Ready for Implementation (Phase 5)

---

## Task Decomposition & Dependency Ordering

### [Phase 5.1: Domain & Contracts]

- [ ] **Task 1: Domain Entities & Protocols**
  - **Files**:
    - `FlowSnap/Domain/Scratchpad/ScratchpadRecord.swift`
    - `FlowSnap/Domain/Scratchpad/ScratchpadState.swift`
    - `FlowSnap/Domain/Scratchpad/PreSummonFocus.swift`
    - `FlowSnap/Domain/Scratchpad/ScratchpadCoordinating.swift`
  - **Verification**: Swift 6 clean compilation of Sendable models and `@MainActor` protocol.

- [ ] **Task 2: Action & Preferences Contracts**
  - **Files**:
    - `FlowSnap/Domain/Shortcut/ShortcutAction.swift` (add `.toggleScratchpad` and `.assignScratchpad`)
    - `FlowSnap/Core/Storage/PreferencesStore.swift` (add `scratchpadDismissOnBlur`, `scratchpadDismissOnEsc`)
  - **Verification**: Action enum and storage keys exposed without build issues.

---

### [Phase 5.2: Test Doubles & TDD Red Suite]

- [ ] **Task 3: Test Plan & Test Doubles**
  - **Files**:
    - `.specify/features/quake-scratchpad-instant-toggle/test-plan.md`
    - `FlowSnapTests/Mocks/MockScratchpadCoordinator.swift`
  - **Verification**: Mock double implements `ScratchpadCoordinating` capturing invocations.

- [ ] **Task 4: Write Failing Unit Tests (Red)**
  - **Files**:
    - `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`
  - **Verification**: Comprehensive tests assert assignment, summon (< 50ms), hybrid dismiss, focus restoration, ESC / blur events, and termination cleanup; fail before implementation (Red).

---

### [Phase 5.3: Core & Infrastructure Implementation (Green Suite)]

- [ ] **Task 5: ScratchpadCoordinator Implementation**
  - **Files**:
    - `FlowSnap/Core/Scratchpad/ScratchpadCoordinator.swift`
  - **Verification**: Implements `ScratchpadCoordinating`, manages state machine, hybrid dismiss, focus restoration, event monitors for ESC and blur, observes `NSWorkspace.didTerminateApplicationNotification`; unit tests pass (Green).

- [ ] **Task 6: CommandDispatcher & Hotkey Integration**
  - **Files**:
    - `FlowSnap/Core/Dispatcher/CommandDispatcher.swift`
    - `FlowSnap/Core/Hotkeys/GlobalHotkeyManager.swift`
  - **Verification**: `⌥Space` and `⌃⌥Space` dispatch to `ScratchpadCoordinator`.

- [ ] **Task 7: UI Menu Bar & Settings Integration**
  - **Files**:
    - `FlowSnap/UI/MenuBar/MenuBarViewModel.swift`
    - `FlowSnap/UI/MenuBar/MenuBarView.swift`
    - `FlowSnap/UI/Settings/SettingsView.swift`
  - **Verification**: Menu Bar reflects Scratchpad status with action buttons; Settings provides configuration toggles.

- [ ] **Task 8: AppDependencies Wiring**
  - **Files**:
    - `FlowSnap/App/AppDependencies.swift`
  - **Verification**: Coordinator initialized and injected into dependencies container.

---

### [Phase 5.4: Build, Lint & Verification]

- [ ] **Task 9: XcodeGen & Full Test Suite Run**
  - **Commands**:
    - `xcodegen generate`
    - `swiftlint lint --strict`
    - `xcodebuild test -scheme FlowSnap -destination 'platform=macOS'`
  - **Verification**: Zero warnings, 100% test pass rate.
