# Implementation Tasks: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

## Task Breakdown & Dependency Sequence

- [x] **TASK-001 (Domain Contracts & Models)**
  - **Files**: `FlowSnap/Domain/Layout/SnapDetectionResult.swift`, `FlowSnap/Domain/Layout/SnapDetecting.swift`, `FlowSnap/Domain/Layout/MouseDragTracking.swift`, `FlowSnap/Domain/Layout/SnapPreviewManaging.swift`
  - **Description**: Define pure domain value types and service protocols for edge detection, mouse tracking, and preview management.
  - **Dependencies**: None.

- [x] **TASK-002 (Core Snap Zone Geometry — SnapDetector)**
  - **Files**: `FlowSnap/Core/Layout/SnapDetector.swift`, `FlowSnapTests/Core/SnapDetectorTests.swift`
  - **Description**: Implement mathematical edge detection dividing display bounds into 8 canonical snap targets (Left, Right, Maximize, Bottom, 4 Corners) with 4px threshold and multi-monitor adjacent boundary checks. Write unit tests covering all zones.
  - **Dependencies**: TASK-001.

- [x] **TASK-003 (Infrastructure Mouse Drag Tracking — MouseDragTracker)**
  - **Files**: `FlowSnap/Infrastructure/macOS/MouseDragTracker.swift`, `FlowSnapTests/Infrastructure/MouseDragTrackerTests.swift`
  - **Description**: Implement `MouseDragTracker` listening to `NSEvent.addGlobalMonitorForEvents` for `.leftMouseDragged` and `.leftMouseUp` with 60fps (~16ms) throttling and safe cancellation.
  - **Dependencies**: TASK-001.

- [x] **TASK-004 (UI HUD Snap Preview Overlay — SnapPreviewPanel & SnapPreviewView)**
  - **Files**: `FlowSnap/UI/SnapPreview/SnapPreviewPanel.swift`, `FlowSnap/UI/SnapPreview/SnapPreviewView.swift`, `FlowSnap/UI/SnapPreview/SnapPreviewManager.swift`
  - **Description**: Upgrade `SnapPreviewPanel` to a floating non-activating panel rendering `SnapPreviewView` with Liquid Glass (`NSVisualEffectView` .hudWindow material / SwiftUI), 10px corner radius, 1.5px accent stroke, smooth frame morphing, and 150ms fade transitions.
  - **Dependencies**: TASK-001.

- [x] **TASK-005 (Core Coordinator & App Integration — DragToSnapCoordinator)**
  - **Files**: `FlowSnap/Core/Layout/DragToSnapCoordinator.swift`, `FlowSnap/App/AppDependencies.swift`, `FlowSnap/App/AppDelegate.swift`
  - **Description**: Implement `DragToSnapCoordinator` managing the dwell timer state machine (100ms outer vs 250ms internal adjacent), wiring `MouseDragTracker`, `SnapDetector`, `SnapPreviewManager`, and `SnapEngine` together in `AppDependencies`.
  - **Dependencies**: TASK-002, TASK-003, TASK-004.

- [x] **TASK-006 (Integration Tests & FlowSnapLab Verification)**
  - **Files**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`, `FlowSnapLab/FlowSnapLabApp.swift`
  - **Description**: Write end-to-end integration tests for the drag-to-snap lifecycle and add interactive preview controls in `FlowSnapLab`.
  - **Dependencies**: TASK-005.
