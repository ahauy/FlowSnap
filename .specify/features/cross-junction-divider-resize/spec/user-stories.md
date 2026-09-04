# User Stories: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature**: `cross-junction-divider-resize`
- **Protocol**: Bounded Task

---

### User Story: `US-CJR-001` — Junction Detection & Visual Crosshair Affordance

- **As a** user arranging 3 or 4 tiled windows on screen,
- **I want** a responsive crosshair cursor (`┼`) and glowing intersection handle to appear when hovering near the junction where dividers meet,
- **So that** I instantly recognize I can resize all adjacent windows simultaneously in 2D.

#### Scenarios:

- **Scenario 1 (Happy Path - T-Junction)**:
  - **Given** 3 windows tiled in Master-Stack layout (1 left full-height, 2 right half-height) sharing a T-junction at $(720, 450)$,
  - **When** the user moves the mouse within $14\,\text{pt}$ of $(720, 450)$,
  - **Then** the cursor switches to `NSCursor.crosshair` and a circular glowing handle pill illuminates at the junction point.
- **Scenario 2 (Happy Path - 4-Window Cross Junction)**:
  - **Given** 4 windows tiled in a 2x2 grid sharing an intersection at $(720, 450)$,
  - **When** the user hovers within $14\,\text{pt}$ of the intersection,
  - **Then** the 2D crosshair handle illuminates.
- **Scenario 3 (Edge Case - Moving away along seam)**:
  - **Given** the pointer is hovering on a junction handle,
  - **When** the user moves the pointer $25\,\text{pt}$ upwards along the vertical seam,
  - **Then** the cursor transitions smoothly to `NSCursor.resizeLeftRight` and the 1D divider line remains active.

---

### User Story: `US-CJR-002` — Simultaneous 4-Way 2D Live Resize

- **As a** user dragging an intersection handle,
- **I want** all 3 or 4 participating windows to resize their widths and heights concurrently in real time,
- **So that** I can rebalance the entire multi-window layout in a single gesture without multiple sequential adjustments.

#### Scenarios:

- **Scenario 1 (Happy Path - Diagonal Drag)**:
  - **Given** an active drag initiated on a T-junction at $(720, 450)$,
  - **When** the user drags to $(800, 500)$,
  - **Then** the left window's width expands to $800\,\text{pt}$, the top-right window's origin moves to $X=800, Y=500$, and the bottom-right window's origin moves to $X=800$ with height $500\,\text{pt}$.
- **Scenario 2 (Edge Case - Independent Axis Clamping)**:
  - **Given** the left window reaches its maximum allowable width or the right window reaches `minSize.width`,
  - **When** the user drags further horizontally while continuing to move vertically,
  - **Then** the horizontal coordinate clamps while vertical height reallocation between top and bottom windows continues tracking smoothly.

---

### User Story: `US-CJR-003` — Atomic Cancellation via Escape Key

- **As a** user performing a 2D crosshair drag,
- **I want** pressing `Escape` to immediately restore all windows to their pre-drag frames,
- **So that** I can abort an unintended layout change with zero risk of leaving windows in an inconsistent state.

#### Scenarios:

- **Scenario 1 (Cancel Drag)**:
  - **Given** an active 2D crosshair drag has displaced 3 windows by $(+100, +80)\,\text{pt}$,
  - **When** the user presses `⎋ Escape` before releasing the mouse,
  - **Then** all 3 windows immediately revert to their exact initial frames and the overlay dismisses.
