# Implementation Tasks: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature**: `cross-junction-divider-resize`
- **Protocol**: Bounded Task

---

## Task Sequencing

- [ ] **Task 1: Domain & Geometry Models**
  - [ ] 1.1 Create `FlowSnap/Domain/Layout/CrossJunction.swift` with `CrossJunction` struct and tests.
  - [ ] 1.2 Extend `CollinearEdgeDetecting` protocol in `FlowSnap/Core/Layout/CollinearEdgeDetecting.swift` with `detectJunctions`, `hitTestJunction`, and `compute2DResizedFrames`.
  - [ ] 1.3 Implement junction detection & 2D resize calculation in `FlowSnap/Core/Layout/CollinearEdgeDetector.swift`.
  - [ ] 1.4 Write unit tests in `FlowSnapTests/Core/CollinearEdgeDetectorTests.swift`.

- [ ] **Task 2: UI Visual Affordance**
  - [ ] 2.1 Extend `AdaptiveDividerOverlayPanel` and `AdaptiveDividerOverlayView` to draw glowing junction handle pill.
  - [ ] 2.2 Add unit tests in `FlowSnapTests/UI/AdaptiveDividerOverlayPanelTests.swift`.

- [ ] **Task 3: Event Coordination & 2D Drag**
  - [ ] 3.1 Update `AdaptiveDividerCoordinator.swift` to hit-test junctions, switch to `.crosshair` cursor, and perform live 2D drag.
  - [ ] 3.2 Update `AdaptiveDividerCoordinatorTests.swift` with end-to-end tests for T-junction 4-way drag and Escape cancellation.

- [ ] **Task 4: Quality Gate, Documentation & Delivery**
  - [ ] 4.1 Update project roadmap and technical documentation (`docs/features/`).
  - [ ] 4.2 Run full test suite and verify build.
