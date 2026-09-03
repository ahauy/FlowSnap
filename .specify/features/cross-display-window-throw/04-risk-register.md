# 04 — Risk Register & Contradiction Scan (Stage 5) — cross-display-window-throw

## Risk Analysis

| Risk ID         | Title                                               | Severity | Likelihood | Impact                                        | Mitigation Strategy                                                                                                                 |
| :-------------- | :-------------------------------------------------- | :------- | :--------- | :-------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------- |
| `RISK-DISP-001` | Window Minimum Size Disparity Across Resolutions    | High     | Med        | Target window overflows target display bounds | Clamping via `FrameClampingHelper`: ensure target frame fits within `targetDisplay.visibleFrame`, adjusting width/height and origin |
| `RISK-DISP-002` | Non-Linear Display Arrangement (Vertical / L-Shape) | Med      | Low        | Disorienting "Next" order if sorted naively   | Deterministic 2D ordering: Primary sort on `minX` (left to right), secondary tie-breaker on `minY` (top to bottom)                  |
| `RISK-DISP-003` | Off-screen or Ambiguous Window Frame Source Display | Med      | Low        | Incorrect target display calculated           | Use `DisplayManaging.display(for:cursorPoint:)` with max-IoU intersection, fallback to cursor display, then primary display         |
| `RISK-DISP-004` | Hotkey Latency Overhead                             | Low      | Low        | Perceived lag exceeding 50ms budget           | Pure geometric calculation with zero blocking I/O; single atomic AX call + direct CoreGraphics warp (< 25ms total execution)        |

---

## Contradiction & Deadlock Check

- **Cyclic navigation vs Single screen**: Cleanly short-circuited when `displays.count <= 1` (`BR-DISP-011`). Zero loop or division-by-zero risk.
- **Coordinate Systems**: AppKit (bottom-left origin) vs Accessibility/CoreGraphics (top-left origin). Handled uniformly via `CoordinateTransformer` and `NSScreen.screens` coordinate inversion anchor.
- **Backward Compatibility**: Existing `ShortcutAction.nextDisplay` and `ShortcutAction.previousDisplay` already exist in `ShortcutAction.swift`; this implementation wires their default commands and keyboard shortcuts without breaking existing stored preferences.

---

## Scope Lock (MoSCoW)

- **Must-Have**:
  - Global hotkeys `⌃⌥⇧→` (Next Display) and `⌃⌥⇧←` (Previous Display).
  - Spatial left-to-right display topology sorting with cyclic wrap-around.
  - Proportional relative frame scaling between source and target display visible frames.
  - Re-snap preservation for recognized snap targets (honoring target display gaps).
  - Cursor warping to target window center point (`CGWarpMouseCursorPosition`).
  - Safe no-op on single-display setups.
- **Should-Have**:
  - Configurable hotkeys in Settings UI (`ShortcutAction.nextDisplay`, `ShortcutAction.previousDisplay`).
- **Won't-Have (v1.0 of US-DISP-015)**:
  - Drag-and-throw gesture with physics momentum (future v2.0+).
  - Display arrangement reordering UI within FlowSnap (handled by macOS System Settings).
