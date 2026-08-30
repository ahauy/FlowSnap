# Intake Classification: US-SNAP-009

- **Feature Slug**: `adaptive-divider-resize`
- **User Story**: `US-SNAP-009: Kéo Đường Phân cách Chung Đa Cửa sổ (Adaptive Multi-Window Divider Resize)`
- **Epic**: `EPIC 08: Adaptive Multi-Window Resize (Shared Collinear Divider) & Gaps`
- **Sprint**: Sprint 2
- **Complexity**: Effort L / multi-session
- **Routing**: Full Feature BA Pipeline (Stages 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8).
- **Primary Tech**: Swift 6.0, CoreGraphics pure math, Binary Space Partitioning (`LayoutGraph`, `LayoutNode`), AppKit (`NSCursor`), macOS Accessibility (`AXUIElement`), Swift Testing (`@Test`)
- **Depends-on**: `US-SNAP-008` = `[x]` -> gate CLEAR
- **Blocks**: `US-SNAP-010` (settings-shortcut-customization)

## Measurable Signals

| Signal | Value | Class Weight |
| :--- | :--- | :--- |
| New domain concepts | 4 (`LayoutGraph`, `LayoutNode`, `CollinearEdge`, `LiveResizeThrottler`) | High |
| Files touched / added (est.) | 12-16 (Domain/Layout, Core/Layout, Core/Window, Tests, Docs) | High |
| Cross-layer seams crossed | Pure spatial math + AX infrastructure + AppKit cursor/mouse | High |
| Public API contract additions | `CollinearEdgeDetector`, `LayoutGraph`, `AdaptiveDividerCoordinator` | High |
| Performance & concurrency constraints | 60fps live dragging, AX rate limiting, main-actor concurrency | High |
| Edge-case complexity | T-junction collinear edges, 4-window cross junctions, minSize clamping | High |
| Reversibility | Pure geometric modular components, fully unit-testable | High |

**Classification: Full Feature / Epic Slice**

## Scope Anchor (from roadmap AC)

1. Spatial Graph & Tree Representation (`LayoutGraph`, `LayoutNode`) tracking spatial adjacency between managed windows in the active layout.
2. Collinear Edge Detection (`CollinearEdgeDetector`): Identifies shared vertical and horizontal partition boundaries across 2, 3 (T-junction), or 4 (cross-junction) adjacent windows with customizable hit tolerance.
3. Cursor Transformation: Switches to `NSCursor.resizeLeftRight` for vertical dividers and `NSCursor.resizeUpDown` for horizontal dividers upon mouse hover.
4. Simultaneous Multi-Window Live Resizing: Dragging a shared divider resizes all adjacent windows whose edges lie along that collinear line in unison.
5. Minimum Size (`minSize`) Boundary Clamping: Enforces minimum dimensions per window (e.g. 200x150 default or application-specific) to prevent window collapse or clipping.
6. 60fps Live Resize Throttling (`LiveResizeThrottler`): Smoothly paces AX API calls at ~16.6ms intervals during mouse drag to eliminate system stutter.

## Explicitly Out of Scope

- Saving custom divider ratios to cloud / workspaces persistence (deferred to Workspace Persistence EPIC).
- Snapping to arbitrary freeform floating windows not part of a recognized spatial partition.
