# Tasks: Stage Manager Multi-Window Auto-Grouping (US-WORK-017)

- **Feature**: `stage-manager-auto-grouping`
- **Story ID**: `US-WORK-017`
- **Status**: Completed (Phase 5)

---

## Task Decomposition & Dependency Ordering

### [Phase 5.1: Domain & Protocol Seams]

- [x] **Task 1: StageManagerDetecting Protocol**
  - **Files**: `FlowSnap/Domain/StageManager/StageManagerDetecting.swift`
  - **Verification**: Clean Sendable protocol compiling with zero warnings.

- [x] **Task 2: AccessibilityServing Raise Protocol Extension**
  - **Files**: `FlowSnap/Infrastructure/Accessibility/AccessibilityService.swift`
  - **Verification**: Declares `raise(element: AXUIElement) -> Bool` and `raise(window: ManagedWindow) -> Bool`.

### [Phase 5.2: Test Doubles & TDD Red Suite]

- [x] **Task 3: Test Plan & Test Doubles**
  - **Files**:
    - `.specify/features/stage-manager-auto-grouping/test-plan.md`
    - `FlowSnapTests/Mocks/MockStageManagerDetector.swift`
    - `FlowSnapTests/Mocks/MockAccessibilityService.swift`
  - **Verification**: Test mocks record `raise` calls and allow simulating `isStageManagerEnabled = true/false`.

- [x] **Task 4: Write Failing Unit Tests (Red)**
  - **Files**:
    - `FlowSnapTests/Infrastructure/StageManagerDetectorTests.swift`
    - `FlowSnapTests/Core/WorkspaceManagerStageManagerTests.swift`
  - **Verification**: Tests fail as expected before implementation (Red).

### [Phase 5.3: Implementation & Green Suite]

- [x] **Task 5: StageManagerDetector Implementation**
  - **Files**: `FlowSnap/Infrastructure/StageManager/StageManagerDetector.swift`
  - **Verification**: Reads `GloballyEnabled` from `com.apple.WindowManager` via CFPreferences; tests pass.

- [x] **Task 6: AXAccessibilityService Raise Implementation**
  - **Files**: `FlowSnap/Infrastructure/Accessibility/AXAccessibilityService.swift`
  - **Verification**: Dispatches `kAXRaiseAction` on window element via `AXUIElementPerformAction`.

- [x] **Task 7: WorkspaceManager Smart Stage Coordination**
  - **Files**:
    - `FlowSnap/Core/Workspace/WorkspaceManager.swift`
    - `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift`
  - **Verification**: Restores anchor app with reveal, secondary apps with raise only, and locks anchor focus. All tests pass (Green).

- [x] **Task 8: AppDependencies Wiring**
  - **Files**: `FlowSnap/App/AppDependencies.swift`
  - **Verification**: Container provides `stageManagerDetector` to `workspaceManager`.

### [Phase 5.4: Build, Lint & Verification]

- [x] **Task 9: XcodeGen & Full Test Suite Run**
  - **Commands**:
    - `xcodegen generate`
    - `swiftlint lint --strict`
    - `xcodebuild test -scheme FlowSnap -destination 'platform=macOS'`
  - **Verification**: Zero warnings, 100% test pass rate (400/400 passed).
