# Technical Specification: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature**: `cross-junction-divider-resize`
- **Status**: Draft -> Ready for Implementation
- **Author**: Antigravity (System Architect)

---

## 1. Executive Summary

This feature extends FlowSnap's Adaptive Divider subsystem to detect multi-window intersection junctions (T-junctions and 2x2 Cross junctions). When users hover near an intersection ($\le 14\,\text{pt}$), the system displays a crosshair cursor (`NSCursor.crosshair`) and illuminates an interactive 2D handle pill. Dragging the handle resizes all participating windows (3 or 4) simultaneously in 2D with decoupled per-axis clamping and atomic cancellation via `Escape`.

---

## 2. Functional Requirements

- **FR-CJR-001 (Junction Topology Detection)**:
  - `CollinearEdgeDetector` shall identify intersections between any pair of vertical and horizontal collinear edges where the vertical divider's coordinate falls within the horizontal divider's span ($\pm 8\,\text{pt}$) and vice versa.
  - Derived from: `BR-CJR-001`.
- **FR-CJR-002 (Hit-Testing & Visual Affordance)**:
  - When the cursor point is within $14\,\text{pt}$ Euclidean distance of a junction, `AdaptiveDividerCoordinator` shall prioritize the junction over 1D dividers, switch the cursor to `NSCursor.crosshair`, and instruct `AdaptiveDividerOverlayPanel` to render an illuminated junction handle pill.
  - Derived from: `BR-CJR-002`, `BR-CJR-003`, `ASM-CJR-001`, `ASM-CJR-003`.
- **FR-CJR-003 (2D Simultaneous Resize Computation)**:
  - `CollinearEdgeDetector.compute2DResizedFrames(junction:targetPoint:windows:containerFrame:gap:)` shall calculate frame updates across all participating windows for both X and Y coordinates.
  - Derived from: `BR-CJR-004`.
- **FR-CJR-004 (Decoupled Clamping)**:
  - Clamping for window minimum size constraints (`minSize`) shall be computed independently per axis.
  - Derived from: `BR-CJR-004`, `ASM-CJR-002`.
- **FR-CJR-005 (Live Drag Synchronization)**:
  - Drag events shall be coalesced at 120Hz ProMotion rates. AXUIElement references for all participating windows shall be cached at `mouseDown`.
  - Derived from: `BR-CJR-004`, `BR-ADR-011`.
- **FR-CJR-006 (Escape Key Cancellation)**:
  - Pressing `Escape` shall immediately restore the original window frames captured at `mouseDown`.
  - Derived from: `BR-CJR-005`.

---

## 3. Non-Functional Requirements (NFR)

- **Performance**: Overlay rendering $\le 8\,\text{ms}$ (120 FPS). Frame computation $\le 1\,\text{ms}$.
- **Accuracy**: Zero pixel overlap or clipping across participating window boundaries.
- **Resource Efficiency**: CPU usage $\sim 0.0\%$ during idle hover tracking.
