# Feature: Cross-Junction & T-Junction 2D Divider Resize (US-SNAP-023)

- **Feature Slug**: `cross-junction-divider-resize`
- **Epic**: `EPIC 08: Adaptive Multi-Window Resize (Shared Collinear Divider) & Gaps`
- **Sprint**: Sprint 2
- **Status**: Completed & Verified (`441/441` tests passing across 69 suites)
- **Specifications**: [baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-junction-divider-resize/baseline.md) | [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-junction-divider-resize/spec.md) | [plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-junction-divider-resize/plan.md) | [tasks.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-junction-divider-resize/tasks.md) | [test-plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-junction-divider-resize/test-plan.md)

---

## 1. Overview & Business Value

In traditional multi-window layouts with 3 or more tiled applications (e.g. Master-Stack: 1 large left window, 2 stacked right windows, or 2x2 grid layout), adjusting the proportions between all three windows historically required dragging the vertical divider, releasing the mouse, locating the horizontal divider, and performing a second drag operation.

`US-SNAP-023` introduces **Solution 1: 4-Way Crosshair / T-Junction 2D Drag Handle (`┼`)**. When two orthogonal collinear dividers intersect (forming a 3-window T-junction or a 4-window Cross-junction), FlowSnap renders an illuminated, glowing junction handle at the intersection point. Hovering within a $14\,\text{pt}$ hit radius swaps the cursor to `NSCursor.crosshair`. Dragging this handle initiates a synchronized 2D drag that simultaneously resizes all participating windows along both X and Y axes in a single fluid gesture.

### Key Capabilities:

1. **Intersection Junction Detection ([`CrossJunction`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Layout/CrossJunction.swift))**: Detects where a vertical collinear edge and a horizontal collinear edge meet within a bounding tolerance box.
2. **Radial Hit-Testing & Seam Priority ([`CollinearEdgeDetecting`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/CollinearEdgeDetecting.swift))**: A $14\,\text{pt}$ radial capture area prioritizes 2D junction dragging over 1D edge divider dragging. Moving the pointer outside this radius seamlessly falls back to standard 1D horizontal or vertical divider resizing.
3. **Decoupled Per-Axis Clamping ([`CollinearEdgeDetector`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/CollinearEdgeDetector.swift))**: If any participating window hits its `minSize` constraint along one axis (e.g., width limit on X), horizontal motion halts while vertical resizing along Y continues smoothly without freezing or locking up the mouse interaction.
4. **Visual Affordance & Glowing Accent Handle ([`AdaptiveDividerOverlayPanel`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/UI/Divider/AdaptiveDividerOverlayPanel.swift))**: Renders an outer translucent glowing halo (accent color with 25% opacity) and an inner crisp circular dot ($7\,\text{pt}$ diameter), providing clear visual feedback without screen clutter or visual noise.
5. **Atomic Cancellation & Reversion ([`AdaptiveDividerCoordinator`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/AdaptiveDividerCoordinator.swift))**: Pressing `⎋` (Escape) during a 2D drag immediately restores all participating windows to their exact starting frames.

---

## 2. Tutorial: Using 2D Junction Resizing

### Step 1: Create a 3-Window or 4-Window Tiled Layout

Snap three resizable applications onto your screen:

- Window 1 (e.g. VS Code): Left Half
- Window 2 (e.g. Terminal): Top-Right Quarter
- Window 3 (e.g. Browser): Bottom-Right Quarter

### Step 2: Hover at the Intersection Point

1. Move your mouse pointer to the point where the central vertical seam meets the horizontal dividing line between the two right windows.
2. The cursor changes to a precision crosshair (`✛` `NSCursor.crosshair`).
3. An illuminated circular handle appears at the intersection point with an accent glow.

### Step 3: Drag in Any Direction (2D Free Drag)

1. Click and drag diagonally up-left, down-right, or in any arbitrary direction.
2. Observe all 3 windows resizing simultaneously in real time:
   - Moving right expands the left window and narrows both right windows.
   - Moving up expands the bottom-right window and shrinks the top-right window.
3. Release the mouse button to commit the new layout.

### Step 4: Cancelling Mid-Drag

Press `⎋` (Escape) at any point before releasing the mouse button to immediately revert all 3 windows to their original dimensions.

---

## 3. How-To Guides

### How-To 1: Detect Junctions from Collinear Dividers

```swift
import FlowSnap

let detector = CollinearEdgeDetector()
let dividers = detector.detectDividers(in: windows, containerFrame: screenFrame, gap: 8.0, tolerance: 16.0)
let junctions = detector.detectJunctions(in: dividers, tolerance: 16.0)

for junction in junctions {
    print("Detected junction at \(junction.point) with \(junction.participatingWindowIDs.count) participating windows")
}
```

### How-To 2: Compute Synchronized 2D Resized Frames

```swift
if let junction = detector.hitTestJunction(at: mousePoint, in: junctions) {
    let resizedFrames = detector.compute2DResizedFrames(
        for: junction,
        targetPoint: mousePoint,
        in: dividers,
        windows: windows,
        containerFrame: screenFrame,
        gap: 8.0
    )
    // Apply frames using 2-phase shrink-first ordering
}
```

---

## 4. Architecture & Design Principles

```
┌────────────────────────────────────────────────────────┐
│               AdaptiveDividerCoordinator               │
│                                                        │
│  [Mouse Moved] ──► detectDividers & detectJunctions   │
│                          │                             │
│                  hitTestJunction?                      │
│                  ├── YES ──► NSCursor.crosshair        │
│                  │           Show Glowing Handle       │
│                  └── NO  ──► NSCursor.resizeLeftRight  │
│                              Show 1D Divider Line      │
└──────────────────────────┬─────────────────────────────┘
                           │ [Mouse Dragged]
                           ▼
┌────────────────────────────────────────────────────────┐
│       CollinearEdgeDetector.compute2DResizedFrames     │
│                                                        │
│  Vertical Sub-Resize (X)   Horizontal Sub-Resize (Y)   │
│  ├── Clamped to MinWidth   ├── Clamped to MinHeight    │
│  └── Dispatches X & Width  └── Dispatches Y & Height   │
│                                                        │
│             Merged Decoupled 2D Frames                 │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│           AdaptiveDividerOverlayPanel                  │
│       Renders glowing halo & white central dot         │
│           at clamped (X, Y) seam position              │
└────────────────────────────────────────────────────────┘
```

### Decoupled Per-Axis Clamping Formula

Instead of introducing rigid multi-variable constraint solvers, FlowSnap evaluates:
$$\text{Frame}_i = \left( \text{Origin}_i^X, \text{Origin}_i^Y, \text{Width}_i, \text{Height}_i \right)$$
where $(\text{Origin}_i^X, \text{Width}_i)$ are produced by `computeResizedFrames(vDivider, targetCoordinate: point.x)` and $(\text{Origin}_i^Y, \text{Height}_i)$ are produced by `computeResizedFrames(hDivider, targetCoordinate: point.y)`.

Because each orthogonal axis enforces independent boundary clamping, reaching the minimum width on X immediately arrests horizontal displacement while vertical height reallocation along Y continues with zero hindrance or axis lockup.

---

## 5. Verification & Test Evidence

- **Unit Tests**:
  - `CollinearEdgeDetectorTests`: 16/16 passed
  - `AdaptiveDividerCoordinatorTests`: 30/30 passed
- **Full Test Suite**: 441/441 tests across 69 suites passed (0 failures).
