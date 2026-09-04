# Elicitation: Multi-Window T-Junction & Crosshair Divider Resize

- **Date**: 2026-09-04
- **Feature Slug**: `cross-junction-divider-resize`
- **Protocol Depth**: Bounded Task (Interactive Customer Interview completed)

---

## 1. Business Value & Problem Statement

- **Problem & Pain Point**: In 3-window (T-junction / Master-Stack) or 4-window (2x2 Cross junction) layouts, users currently must perform multiple separate drag operations (first vertical, then horizontal) to resize adjacent windows.
- **Goal**: Provide a single unified 4-way drag handle at the intersection point where multiple dividers meet, allowing instant simultaneous 2D resizing across all participating windows in a single gesture.
- **Success Metrics**:
  - Drag latency < 16ms (60–120 FPS continuous update).
  - Number of drag interactions reduced from 2 to 1 for 3- and 4-window layouts.
  - Zero window overlap and zero layout desynchronization on mouseUp.

---

## 2. Interactive Interview Outcomes

### Pillar: UX & Visual Affordance

- **Q1: Hit-Testing & Visual Affordance at Junctions**
  - **Decision**: Show crosshair cursor (`NSCursor.crosshair` / `┼`) AND an illuminated glowing accent handle pill at the junction point with a hit detection radius of $\pm 14\,\text{pt}$.
  - **Traceability**: `ASM-CJR-001` (Visual junction handle & cursor affordance).

### Pillar: Business Rules & Clamping

- **Q2: Clamping Mechanics Under Window Minimum Size**
  - **Decision**: Decoupled independent-axis clamping. If any participating window hits its horizontal minimum width (`minSize.width`), horizontal resizing clamps while vertical resizing continues smoothly along the Y-axis (and vice versa).
  - **Traceability**: `ASM-CJR-002` (Independent axis clamping).

### Pillar: Interaction Priority & State Machine

- **Q3: Hit-Test Priority Between 4-Way Junction and 1D Dividers**
  - **Decision**: When pointer is within the $\pm 14\,\text{pt}$ circular radius of the intersection point, 4-way crosshair drag takes strict priority. When the pointer moves outside the radius along either seam, tracking seamlessly falls back to 1D vertical (`resizeLeftRight`) or horizontal (`resizeUpDown`) divider dragging.
  - **Traceability**: `ASM-CJR-003` (Proximity priority for cross junctions).

---

## 3. Explicit Assumptions & Decisions Register

| ID            | Statement                                                                                                               | Status    | Confirmed By   |
| ------------- | ----------------------------------------------------------------------------------------------------------------------- | --------- | -------------- |
| `ASM-CJR-001` | Junctions render an illuminated accent handle pill and display `.crosshair` cursor when hovered within $14\,\text{pt}$. | Confirmed | User interview |
| `ASM-CJR-002` | Window minimum size constraints are clamped independently per axis during 2D crosshair drag.                            | Confirmed | User interview |
| `ASM-CJR-003` | Proximity within $14\,\text{pt}$ prioritizes 2D junction drag over 1D edge divider drag.                                | Confirmed | User interview |
