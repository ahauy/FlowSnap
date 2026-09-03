# Spec: Cross-Display Window Throw (US-DISP-015)

## Requirements Traceability

- **`REQ-DISP-015-001` (Global Hotkeys)**:
  - System must listen for `⌃⌥⇧→` (`moveToNextDisplay`) and `⌃⌥⇧←` (`moveToPreviousDisplay`).
  - Derived from: `BR-DISP-008`, `ASM-DISP-001`.

- **`REQ-DISP-015-002` (Topology Resolution)**:
  - System must sort active displays horizontally from left to right (`frame.minX`, tie-break `frame.minY`).
  - Next/Previous display must be computed with cyclic modulo wrap-around.
  - Derived from: `BR-DISP-007`, `BR-DISP-008`, `ASM-DISP-001`.

- **`REQ-DISP-015-003` (Proportional Frame Scaling)**:
  - For free-floating windows, position and size relative to source `visibleFrame` must be mapped proportionally to target `visibleFrame`.
  - Must apply `FrameClampingHelper` to keep window 100% visible and obey minimum size constraints (>= 200x200 pt).
  - Derived from: `BR-DISP-009`, `ASM-DISP-002`.

- **`REQ-DISP-015-004` (Semantic Snap Preservation)**:
  - For windows previously placed in a recognized `SnapTarget`, the window must be re-snapped using `SnapEngine` with target display bounds and active `WindowGap`.
  - Derived from: `BR-DISP-010`, `ASM-DISP-002`.

- **`REQ-DISP-015-005` (Cursor Warping & Focus)**:
  - Mouse pointer must be warped to the geometric center of the new window frame (`CGWarpMouseCursorPosition`).
  - Active accessibility focus must be re-asserted on the window.
  - Derived from: `BR-DISP-012`, `ASM-DISP-003`.

- **`REQ-DISP-015-006` (Single Display Safe No-Op)**:
  - If fewer than 2 displays are active, the command must immediately no-op.
  - Derived from: `BR-DISP-011`, `ASM-DISP-001`.

---

## User Stories & Scenarios

### US-DISP-015-01: Throwing Snapped Window to Next Display

- **Given**: A multi-monitor setup with Display A (Laptop, 1512x982) and Display B (External 4K, 3840x2160), with an active code editor window snapped to `Left Half` on Display A.
- **When**: The user presses `⌃⌥⇧→` (`Move to Next Display`).
- **Then**:
  - The window is moved to Display B and snapped to `Left Half` of Display B's visible area, accounting for Display B's dock/menubar and active window gaps.
  - The mouse cursor is warped to the center of the window on Display B.
  - Keyboard focus remains on the editor window.

### US-DISP-015-02: Throwing Free-Floating Window to Next Display

- **Given**: A multi-monitor setup with Display A (1920x1080) and Display B (2560x1440), with an active free-floating utility window occupying `[x: 10%, y: 20%, w: 40%, h: 50%]` of Display A.
- **When**: The user presses `⌃⌥⇧→`.
- **Then**:
  - The window is repositioned on Display B at approximately `[x: 10%, y: 20%, w: 40%, h: 50%]` of Display B's `visibleFrame`.
  - The window is clamped to remain fully within Display B's visible boundaries.
  - Mouse cursor is warped to the window center on Display B.

### US-DISP-015-03: Cyclic Wrap-Around

- **Given**: Two connected displays: Display 0 (left) and Display 1 (right). The active window is on Display 1.
- **When**: The user presses `⌃⌥⇧→`.
- **Then**: The window wraps around and appears on Display 0.
- **When**: The user presses `⌃⌥⇧←` from Display 0.
- **Then**: The window wraps around and appears on Display 1.

### US-DISP-015-04: Single Display Safe No-Op

- **Given**: Only 1 display is connected (built-in MacBook screen).
- **When**: The user presses `⌃⌥⇧→` or `⌃⌥⇧←`.
- **Then**: Nothing happens, the window does not move, the cursor does not move, and no error sound/alert occurs.
