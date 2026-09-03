# Domain Baseline: Cross-Display Window Throw (US-DISP-015)

> Status: **SIGNED-OFF v1.0**  
> Version: 1.0.0  
> Sign-off Date: 2026-09-03  
> Feature Slug: `cross-display-window-throw`  
> Epic: EPIC 13 (Advanced Multi-Monitor Topology & Cross-Display Navigation)  
> Effort: `M` | Context Budget: `single-session`

---

## 1. Executive Summary

Provides system-wide keyboard shortcuts (`⌃⌥⇧→` / `⌃⌥⇧←`) to instantaneously throw the currently focused window to the next or previous connected display in spatial left-to-right topology. The window's placement is automatically adapted:

- If previously snapped: re-snaps to the equivalent `SnapTarget` on the destination display with destination window gaps and safe area applied.
- If free-floating: maintains proportional relative size and offset relative to the destination display's `visibleFrame`, clamped safely inside screen bounds.
- The mouse pointer is warped to the center of the window on the target display, and keyboard focus is immediately reinforced.
- On single-display setups, the hotkey triggers a safe, instantaneous no-op.

---

## 2. Business Rules Reference

- `BR-DISP-007`: Left-to-right display topology sorting (`frame.minX`, tie-break `frame.minY`).
- `BR-DISP-008`: Cyclic modulo display traversal (`next` and `previous`).
- `BR-DISP-009`: Proportional geometric relative frame scaling for floating windows.
- `BR-DISP-010`: Semantic snap preservation for snapped windows.
- `BR-DISP-011`: Single-display safe no-op.
- `BR-DISP-012`: Mouse cursor warping (`CGWarpMouseCursorPosition`) & focus maintenance.

---

## 3. Decisions & Assumptions Register

- `ASM-DISP-001`: Spatial left-to-right display ordering with cyclic wrap-around.
- `ASM-DISP-002`: Semantic snap preservation preferred over pure geometric scaling when window is snapped.
- `ASM-DISP-003`: Mouse cursor warps to center of window on target display with immediate keyboard focus.

---

## 4. Scope & Boundary (MoSCoW)

- **Must-Have**:
  - Global hotkeys `⌃⌥⇧→` and `⌃⌥⇧←` handled by `GlobalHotkeyManager` and `CommandDispatcher`.
  - Spatial topology computation in `DisplayNavigator`.
  - Geometric scaling via `RelativeFrameScaler` + `FrameClampingHelper`.
  - Cursor repositioning via `CGWarpMouseCursorPosition`.
  - Safe no-op when `displays.count <= 1`.
- **Won't-Have (v1.0)**:
  - Drag-and-throw mouse physics.
  - Multi-window simultaneous cross-display throw.

---

## 5. Handover Brief to System Architect (Phase 2-4)

- **Domain Models**:
  - Update `WindowCommand` enum: add `.moveToNextDisplay` and `.moveToPreviousDisplay`.
  - Update `ShortcutAction.nextDisplay` and `ShortcutAction.previousDisplay` to use these default commands and default `KeyboardShortcut` (`⌃⌥⇧→`, `⌃⌥⇧←`).
- **Core Subsystems**:
  - `DisplayNavigator`: Implement `DisplayNavigating` protocol to sort displays left-to-right and find next/previous cyclic targets.
  - `RelativeFrameScaler`: Implement pure functional scale calculation.
  - Integrate into `CommandDispatcher` or `WindowManager` to coordinate the move, scale, AX `setFrame`, cursor warp, and focus.
