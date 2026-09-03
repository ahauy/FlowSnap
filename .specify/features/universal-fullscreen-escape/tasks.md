# Tasks: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-018)

- **Feature**: `universal-fullscreen-escape`
- **Story ID**: `US-WORK-018`
- **Status**: Completed (Phase 5)

---

## Task Decomposition & Dependency Ordering

### [Phase 5.1: Domain Entities & Protocols]

- [x] **Task 1: Domain Entities**
  - **Files**:
    - `FlowSnap/Domain/Window/FullScreenEscapeTier.swift`
    - `FlowSnap/Domain/Window/FullScreenEscapeResult.swift`
  - **Verification**: Types compile, are `Sendable`, `Equatable`, `Codable`.

- [x] **Task 2: Protocol Seams & CGEvent Poster**
  - **Files**:
    - `FlowSnap/Core/Window/FullScreenEscapeCoordinating.swift`
    - `FlowSnap/Infrastructure/Accessibility/CGEventPosting.swift`
  - **Verification**: Protocols expose clean public interfaces; `SystemCGEventPoster` implements `CGEventPosting` with public `CGEvent` APIs.

### [Phase 5.2: Test Doubles & TDD Red Suite]

- [x] **Task 3: Test Plan & Test Mocks**
  - **Files**:
    - `.specify/features/universal-fullscreen-escape/test-plan.md`
    - `FlowSnapTests/Mocks/MockCGEventPoster.swift`
    - `FlowSnapTests/Mocks/MockFullScreenEscapeCoordinator.swift`
    - `FlowSnapTests/Infrastructure/FullScreenEscapeCoordinatorTests.swift`
  - **Verification**: Test cases for Tier 0, Tier 1, Tier 2, adaptive early exit, and timeout. (Failing Red tests).

### [Phase 5.3: Implementation & Green Suite]

- [x] **Task 4: FullScreenEscapeCoordinator Implementation**
  - **Files**:
    - `FlowSnap/Infrastructure/Accessibility/FullScreenEscapeCoordinator.swift`
  - **Verification**: Implements 3-tier fallback and adaptive polling loop; all unit tests pass (Green).

- [x] **Task 5: Core & Infrastructure Integration**
  - **Files**:
    - `FlowSnap/Infrastructure/Accessibility/AXAccessibilityService.swift`
    - `FlowSnap/Core/Window/WindowManager.swift`
  - **Verification**: `WindowManager.move` uses adaptive escape instead of fixed 700ms sleep.

### [Phase 5.4: Build, Lint & Verification]

- [x] **Task 6: XcodeGen & Test Suite Execution**
  - **Commands**:
    - `xcodegen generate`
    - `xcodebuild test -scheme FlowSnap -destination 'platform=macOS'`
  - **Verification**: Zero compile errors, zero test failures (392/392 passed).
