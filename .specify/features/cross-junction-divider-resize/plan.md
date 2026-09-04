# Technical Plan: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature**: `cross-junction-divider-resize`
- **Protocol**: Bounded Task

---

## 1. Architecture & Seam Discipline

We extend the existing Adaptive Divider subsystem following Ousterhout Deep Module principles:

1. **Domain & Core Geometry Layer**:
   - [`CrossJunction.swift`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Layout/CrossJunction.swift): Pure immutable value object representing intersection point, hit radius, and participating IDs.
   - [`CollinearEdgeDetector.swift`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/CollinearEdgeDetector.swift): Adds `detectJunctions(...)`, `hitTestJunction(...)`, and `compute2DResizedFrames(...)`. Reuses existing 1D vertical and horizontal frame calculation algorithms without code duplication.
2. **Presentation / Overlay Layer**:
   - [`AdaptiveDividerOverlayPanel.swift`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/UI/Divider/AdaptiveDividerOverlayPanel.swift): Renders a circular illuminated handle pill at the active junction point when hovered or dragged.
3. **Coordination & Event Handling Layer**:
   - [`AdaptiveDividerCoordinator.swift`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/AdaptiveDividerCoordinator.swift):
     - Maintains `activeJunction: CrossJunction?` and `hoveredJunction: CrossJunction?`.
     - Hit-testing checks junctions first (within 14pt radius).
     - Hover swaps cursor to `NSCursor.crosshair`.
     - `handleMouseDown` locks `activeJunction` and caches all participating windows' AX elements.
     - `scheduleDragTask` dispatches 2D updates via `compute2DResizedFrames`.
     - `cancelResize` restores original frames.

---

## 2. Testing Strategy (TDD)

1. Unit tests for `detectJunctions` on 3-window T-junctions and 4-window cross junctions.
2. Unit tests for `compute2DResizedFrames` verifying decoupled clamping.
3. Integration tests for `AdaptiveDividerCoordinator` verifying crosshair cursor, live 2D drag, and Escape cancellation.
