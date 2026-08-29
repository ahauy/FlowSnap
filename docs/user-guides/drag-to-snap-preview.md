# User Guide: Drag-to-Snap & HUD Snap Preview (US-SNAP-006)

Welcome to the **FlowSnap Drag-to-Snap & HUD Snap Preview Guide**! This guide explains how to snap windows on macOS simply by dragging them to screen edges or corners, and how the translucent Liquid Glass preview overlay guides your layout in real-time.

---

## 1. Overview & Drag-to-Snap Experience

FlowSnap enables effortless, mouse-driven window snapping. Simply grab a window's title bar and drag it towards any screen boundary. When your cursor reaches the edge zone ($\le 4\text{px}$ from the display border), FlowSnap automatically projects a translucent Liquid Glass preview overlay showing exactly where the window will snap.

Releasing your mouse (`leftMouseUp`) snaps the window into place instantly.

---

## 2. Supported Snap Zones & Gestures

### 2.1 Snapping Halves (Left & Right)

Drag any window to the **left** or **right** edge of your screen. A half-screen preview appears with smooth macOS accent lighting:

![Drag to Snap Left Half Preview](images/drag-to-snap-preview/01_drag_to_snap_left_half.png)

- **Left Edge**: Snaps window to 50% left of the active display.
- **Right Edge**: Snaps window to 50% right of the active display.

---

### 2.2 Maximizing (Top Edge)

Drag a window to the **top edge** of your screen. The HUD preview expands across the full visible screen area:

![Drag to Snap Maximize Preview](images/drag-to-snap-preview/02_drag_to_snap_maximize.png)

- **Top Edge**: Expands the window to fill 100% of the visible display area (respecting Menu Bar and Dock).

---

### 2.3 Snapping Quarters (4 Corners)

Drag a window into any of the **four corners** (top-left, top-right, bottom-left, bottom-right). A 25% quadrant preview appears:

![Drag to Snap Top Right Corner Preview](images/drag-to-snap-preview/03_drag_to_snap_top_right.png)

- **Top-Left Corner**: Snaps window to the top-left quarter.
- **Top-Right Corner**: Snaps window to the top-right quarter.
- **Bottom-Left Corner**: Snaps window to the bottom-left quarter.
- **Bottom-Right Corner**: Snaps window to the bottom-right quarter.

---

## 3. Multi-Monitor Intelligence: Smooth Screen Crossing

When using multiple monitors side-by-side, dragging a window from one screen to another should feel natural and friction-free.

FlowSnap automatically differentiates between:

1. **Outer Screen Boundaries** (touching empty space): Triggers preview quickly after **100ms** dwell.
2. **Internal Adjacent Borders** (touching another display): Requires a deliberate **250ms** dwell to activate snapping. Moving at normal cursor speed allows your window to pass seamlessly across screens without unintended snapping.

---

## 4. Cancelling a Snap Gesture

If you decide not to snap:

- Simply drag your cursor **$> 20\text{px}$ away** from the screen edge back towards the center of your screen.
- The preview overlay automatically fades out with a 150ms animation, and releasing the mouse leaves the window at its manual drag position.
