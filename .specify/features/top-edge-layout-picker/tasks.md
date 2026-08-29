# Implementation Tasks: Top-Edge Snap Layout Picker (US-SNAP-007)

## Task Breakdown & Dependency Sequence

- [x] **TASK-001 (Domain & SnapTarget Extensions)**
  - **Files**: `FlowSnap/Domain/Layout/SnapTarget.swift`, `FlowSnap/Domain/Layout/LayoutTemplate.swift`, `FlowSnap/Domain/Layout/LayoutSlot.swift`, `FlowSnap/Domain/Layout/SnapLayoutPickerManaging.swift`
  - **Description**: Extend `SnapTarget` with 5 new cases (`.leftTwoThirds`, `.rightOneThird`, `.leftThird`, `.centerThird`, `.rightThird`), define `LayoutTemplate` and `LayoutSlot` domain models with standard presets, and define the `SnapLayoutPickerManaging` protocol.
  - **Dependencies**: None.

- [x] **TASK-002 (Core Mathematical Layout Engine Calculations)**
  - **Files**: `FlowSnap/Core/Layout/LayoutEngine.swift`, `FlowSnapTests/Core/LayoutEngineTests.swift`
  - **Description**: Add exact geometric calculations in `LayoutEngine` for all new `SnapTarget` variants (70/30 asymmetrical and 3-column equal splits). Write unit tests covering pixel accuracy on multiple display resolutions (1440x900, 1920x1080, 4K).
  - **Dependencies**: TASK-001.

- [x] **TASK-003 (Top-Center Zone Detection in SnapDetector)**
  - **Files**: `FlowSnap/Core/Layout/SnapDetector.swift`, `FlowSnap/Domain/Layout/SnapDetectionResult.swift`, `FlowSnapTests/Core/SnapDetectorTests.swift`
  - **Description**: Add `isTopCenterZone` detection to `SnapDetector` (middle 40% width, top 24px threshold) distinguishing top-center layout picker trigger from standard top-edge maximize snap. Write unit tests for detection boundaries.
  - **Dependencies**: TASK-001.

- [x] **TASK-004 (UI Presentation — SnapLayoutPickerView & SnapLayoutPickerPanel)**
  - **Files**: `FlowSnap/UI/LayoutPicker/SnapLayoutPickerView.swift`, `FlowSnap/UI/LayoutPicker/SnapLayoutPickerPanel.swift`, `FlowSnap/UI/LayoutPicker/SnapLayoutPickerManager.swift`
  - **Description**: Build `SnapLayoutPickerView` with SwiftUI rendering 4 interactive glassmorphic cards with hover animations. Create `SnapLayoutPickerPanel` (non-activating `NSPanel` with Liquid Glass `NSVisualEffectView`), and implement `SnapLayoutPickerManager` managing panel presentation, hit-testing, and dismissing.
  - **Dependencies**: TASK-001, TASK-002.

- [x] **TASK-005 (Coordinator Integration — DragToSnapCoordinator)**
  - **Files**: `FlowSnap/Core/Layout/DragToSnapCoordinator.swift`, `FlowSnap/App/AppDependencies.swift`, `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
  - **Description**: Wire `SnapLayoutPickerManaging` into `DragToSnapCoordinator` and `AppDependencies`. Coordinate state transitions: entering top-center zone shows picker -> hovering slot shows HUD preview -> release snaps window -> moving away closes picker.
  - **Dependencies**: TASK-003, TASK-004.

- [x] **TASK-006 (Lab View & Integration Verification)**
  - **Files**: `FlowSnapLab/FlowSnapLabApp.swift`, `FlowSnapTests/UI/SnapLayoutPickerManagerTests.swift`
  - **Description**: Add interactive layout picker testing controls in `FlowSnapLab` and automated integration tests for picker lifecycle and hit-testing.
  - **Dependencies**: TASK-005.
