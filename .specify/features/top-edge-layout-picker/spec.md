# Technical Specification: Top-Edge Snap Layout Picker (US-SNAP-007)

## 1. Scope & Objective

This specification defines the technical requirements and architecture for `US-SNAP-007`: the Windows 11-style Top-Edge Snap Layout Picker. When a user drags a window to the top-center edge of the active display, FlowSnap smoothly reveals a glassmorphic layout picker flyout (`SnapLayoutPickerPanel`). Hovering over individual slots in the picker highlights the slot and projects a full-screen translucent snap preview (`SnapPreviewPanel`). Releasing the mouse snaps the window directly into that layout zone.

---

## 2. Functional Requirements

- **REQ-TOP-001 (Top-Center Zone Detection)**:
  - `SnapDetector` evaluates cursor coordinates during mouse drag interactions.
  - When cursor enters the **Top-Center Zone** (defined as the middle 40% of the active display width: $x \in [0.3 \times W, 0.7 \times W]$ and within top $24\text{px}$ of `visibleFrame`), it returns `SnapDetectionResult` with target `.layoutPicker(displayID)`.
  - Dragging to the top outer edges ($x < 0.3 \times W$ or $x > 0.7 \times W$) continues to trigger direct corner or maximize snap targets.

- **REQ-TOP-002 (4 Standard Layout Templates)**:
  - The picker panel displays 4 layout template cards:
    1. **Two Columns Equal (50/50)**: Slots `[leftHalf, rightHalf]`.
    2. **Two Columns Asymmetric (70/30)**: Slots `[leftTwoThirds (70%), rightOneThird (30%)]`.
    3. **Three Columns Equal (1/3 each)**: Slots `[leftThird (33.3%), centerThird (33.4%), rightThird (33.3%)]`.
    4. **Four Quarters (2x2)**: Slots `[topLeft, topRight, bottomLeft, bottomRight]`.

- **REQ-TOP-003 (SnapTarget & LayoutEngine Mathematical Support)**:
  - `SnapTarget` enum is extended with:
    - `.leftTwoThirds` ($70\%$ width, full height)
    - `.rightOneThird` ($30\%$ width, full height)
    - `.leftThird` ($33.33\%$ width, full height)
    - `.centerThird` ($33.34\%$ width, full height)
    - `.rightThird` ($33.33\%$ width, full height)
  - `LayoutEngine.calculateFrame(for:in:)` calculates exact pixel bounds for all new targets within the target display's `visibleFrame`.

- **REQ-TOP-004 (Non-Activating Glassmorphic Picker Panel)**:
  - `SnapLayoutPickerPanel` is a customized `NSPanel` with `.borderless`, `.nonactivatingPanel`, `level = .floating + 1`, and `isOpaque = false`.
  - Styled with macOS Liquid Glass (`NSVisualEffectView` with `.hudWindow` / `.popover` material), 12px rounded corners, and a 1px subtle border.
  - Positioned centered horizontally at the top edge of the active display (immediately below the macOS Menu Bar).

- **REQ-TOP-005 (Interactive Slot Hover & Dual Preview Feedback)**:
  - As the mouse moves over the picker panel:
    - `SnapLayoutPickerManager` conducts hit-testing against the layout template slots.
    - When a slot is hovered, it activates visual highlight on the card slot AND calls `SnapPreviewManaging.showPreview(frame:displayID:)` to render the translucent preview overlay on the target display.
  - Moving between slots updates the full-screen preview smoothly.

- **REQ-TOP-006 (Mouse Release & Snap Execution)**:
  - When `leftMouseUp` occurs inside a hovered slot:
    - FlowSnap dismisses the picker panel immediately.
    - Dispatches `.snap(target, targetDisplayID)` to `CommandDispatcher`.
    - Triggers `flashSnapSuccess(frame:)` on `SnapPreviewManager`.

- **REQ-TOP-007 (Smooth Dismissal on Exit)**:
  - If the cursor moves outside the picker panel bounds without releasing:
    - The picker panel slides up and dismisses smoothly (150ms animation).
    - Any active full-screen HUD preview is dismissed.
    - Drag coordination returns to standard edge detection.

---

## 3. Non-Functional Requirements

- **NFR-TOP-001 (Performance & 60fps Rendering)**:
  - Hit-testing and slot highlight updates must execute within $< 8\text{ms}$.
  - Zero lag or jitter during continuous mouse drag.
- **NFR-TOP-002 (Thread Safety & Concurrency)**:
  - `SnapLayoutPickerManager` and `SnapLayoutPickerPanel` must execute strictly on `@MainActor`.
  - Domain models and layout calculations must be pure and `Sendable`.
- **NFR-TOP-003 (Design System & Anti-AI-Slop)**:
  - Adhere strictly to FlowSnap minimal dark/light glass design tokens: 1px hairline border, intentional blue/system accent focus fill, no exaggerated rainbow gradients.
