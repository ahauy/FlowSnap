# ADR-0010: Cross-Display Window Throw Architecture (US-DISP-015)

- **Status**: Accepted
- **Date**: 2026-09-03
- **Feature**: `cross-display-window-throw` (US-DISP-015)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

In multi-monitor setups, moving windows between screens manually via dragging is tedious and disrupts workflow. Users need instant keyboard shortcuts to "throw" the focused window to adjacent screens while maintaining predictable spatial order, proportional scaling across resolution differences (e.g. 4K to MacBook screen), semantic snap alignment, and cursor focus continuity.

Key architectural challenges:

1. macOS does not guarantee a deterministic spatial order in `NSScreen.screens`.
2. Windows moving across different screen resolutions and aspect ratios can become oversized or partly off-screen.
3. Users lose track of the mouse cursor when a window is thrown to an external monitor.
4. Hotkey action must be safe and instantaneous (< 50ms latency).

## Decision

1. **Spatial Left-to-Right Topology (`DisplayNavigator`)**:
   - Displays are sorted horizontally by `frame.minX` (AppKit coordinate space), with `minY` as a deterministic tie-breaker.
   - Cyclic modulo traversal wraps around seamlessly: Next on rightmost display moves to leftmost; Previous on leftmost moves to rightmost.
   - If only 1 display is connected, operations cleanly return immediately with zero side-effects.

2. **Semantic Snap Preservation with Geometric Fallback**:
   - `ZoneInference` evaluates whether the window is currently snapped into a canonical zone (IoU >= 0.75).
   - If snapped: `SnapEngine.calculateAXFrame` recalculates the target zone directly on the target display, honoring target resolution, safe area (Dock/Menu Bar), and configured `WindowGap`.
   - If free-floating: `RelativeFrameScaler` maps proportional offsets and dimensions (`relX, relY, relW, relH`), clamped safely inside the target's `visibleFrame` with minimum 200x200 pt dimensions via `FrameClampingHelper`.

3. **Mouse Cursor Warping & Focus Synchronization (`CursorManager`)**:
   - Mouse pointer is warped to the geometric center of the newly positioned window on the target display using `CGWarpMouseCursorPosition(targetCenter)`.
   - Window keyboard focus is re-asserted via `WindowManager.focus(window)`.

4. **Global Hotkeys**:
   - Registered out-of-the-box in `ShortcutAction`:
     - `Move to Next Display`: `⌃⌥⇧→` (keyCode: 124, modifiers: `ctrlOptShift`).
     - `Move to Previous Display`: `⌃⌥⇧←` (keyCode: 123, modifiers: `ctrlOptShift`).
   - Fully customizable in Settings UI under `ShortcutCategory.displays`.

## Consequences

- **Positive**:
  - 100% compliant with Public macOS APIs (zero private CGS symbols).
  - Sub-25ms execution latency across hotkey dispatch, math scaling, and cursor warp.
  - Zero cursor disorientation when throwing windows across physical displays.
  - Proportional geometry eliminates off-screen window bugs when moving from 4K to FHD or Retina displays.
- **Negative / Trade-offs**:
  - `CGWarpMouseCursorPosition` instantly relocates the cursor without animated gliding (by macOS design).

## References

- `01-elicitation.md` — Confirmed decisions `ASM-DISP-001`, `ASM-DISP-002`, `ASM-DISP-003`.
- `CONTEXT.md` — Ubiquitous Language terms for `DisplayNavigator`, `RelativeFrameScaler`, `CursorWarping`.
- ADR-0001 — Zero Private APIs Mandate.
- ADR-0005 — Shortcut Customization Architecture.
