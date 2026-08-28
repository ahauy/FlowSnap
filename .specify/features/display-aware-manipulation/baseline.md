# Domain Decision Baseline: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0  
**Feature Slug**: `display-aware-manipulation`  
**Date**: 2026-08-28

---

## 1. Executive Summary

FlowSnap requires robust multi-monitor support to correctly position and resize windows across heterogeneous display arrangements (horizontal side-by-side, vertical stacking, diagonal placement, and mixed Retina 1x vs 2x scaling).

The core technical challenge is bridging the two opposing global coordinate systems on macOS:

- **AppKit (`NSScreen`)**: Origin `(0, 0)` at bottom-left of the Primary Screen; Y coordinates grow upward.
- **Accessibility API (`AXUIElement`)**: Origin `(0, 0)` at top-left of the Primary Screen; Y coordinates grow downward.

This baseline establishes:

1. **Target Display Resolution**: When windows straddle displays, the display with maximum intersection area is selected (with cursor fallback).
2. **Deterministic Coordinate Inversion**: $Y_{AX} = H_{Primary} - (Y_{AppKit} + Height)$, implemented as a pure functional involution in `CoordinateTransformer` with sub-pixel floating point fidelity.
3. **Screen Reconfiguration Observation**: Reactive, non-blocking cache updates on `NSApplication.didChangeScreenParametersNotification`.
4. **Mirrored Display Coalescing**: Filters mirrored screens to the primary active mirror master.
5. **Cross-Display Sequential Navigation**: Provides `nextDisplay(after:)` with cyclic wrap-around for multi-monitor setups and a single-screen `nil` guard.

---

## 2. Settled Elicitation & Grilling Decisions

| Item                                      | Decision                                    | Rationale                                                                                                                                        |
| :---------------------------------------- | :------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------- |
| **Q1: Straddling Window Target Display**  | **Option A (Maximum Overlap Area)**         | Selects the screen where the majority of the window is placed. Falls back to cursor position if window is offscreen.                             |
| **Q2: Coordinate Inversion Architecture** | **Option A (Pure Functional Math)**         | Stateless, pure `CoordinateTransformer` with static methods taking `primaryScreenHeight`. Decoupled from system singletons for 100% testability. |
| **Q3: Screen Disconnect Policy**          | **Option A (Passive Reactive Update)**      | Update internal `[Display]` state upon notification without force-moving windows; snap layout recalculates on next snap command.                 |
| **Q4: Menu Bar & Dock Isolation**         | **Strict `visibleFrame` Isolation**         | Snap zones are computed against `display.visibleFrame` for each screen, eliminating Dock/Menu Bar overlap.                                       |
| **Q5: Mirrored Displays**                 | **Filter to Primary/Active Mirror Master**  | Treats mirrored displays as one logical display to avoid redundant snap targets.                                                                 |
| **Q6: Cross-Display Navigation**          | **Support Relative Zone Migration**         | Adds `nextDisplay(after:)` on `DisplayManaging` to enable moving windows between screens while preserving layout zones.                          |
| **Q7: Coordinate Precision**              | **Sub-pixel Integrity (Exact `CGFloat`)**   | Preserves floating-point points without premature rounding truncation.                                                                           |
| **Q8: Single Display Guard**              | **Cyclic Wrap-around with 1-Display Guard** | Cycles $1 \to 2 \to 1$ for $\ge 2$ displays; returns `nil` for single monitor.                                                                   |

---

## 3. Core Business Rules

- **BR-DISP-001 (Primary Reference)**: The screen with AppKit `frame.origin == .zero` is the Primary Display. Its total frame height ($H_{Primary}$) is the anchor for all global AX inversions.
- **BR-DISP-002 (Target Display Selection)**: Target display is determined by `argmax(area(CGRectIntersection(windowFrame, display.frame)))`. If zero, fallback to cursor display, then Primary.
- **BR-DISP-003 (Involution Invariant)**: Applying `toAppKit(toAX(rect, H), H) == rect` holds for all valid rectangles with zero floating-point drift.
- **BR-DISP-004 (Reactive Screen Update)**: `DisplayManager` listens to `didChangeScreenParametersNotification` to update display topologies asynchronously.
- **BR-DISP-005 (Mirrored Screen Coalescing)**: Mirrored secondary displays are coalesced into the active primary mirror master.
- **BR-DISP-006 (Cyclic Display Navigation)**: For $\ge 2$ displays, `nextDisplay(after:)` cycles through displays in index order ($0 \to 1 \dots \to 0$). For a single display, returns `nil`.
- **BR-DISP-007 (Sub-pixel Precision)**: All coordinate transformations preserve exact `CGFloat` points without premature rounding or truncation.

---

## 4. Scope Lock (MoSCoW)

- **Must-Have (P0)**:
  - `Display` model with `isPrimary: Bool`.
  - `CoordinateTransformer` pure math utility with bidirectional conversions.
  - `DisplayManaging` protocol and `DisplayManager` implementation.
  - Target display resolution by maximum intersection area.
  - Unit test suite verifying multi-monitor topologies (horizontal, vertical, diagonal, negative origins).
  - Cyclic display navigation (`nextDisplay(after:)`).
- **Won't-Have**:
  - Private macOS APIs for Spaces manipulation.
  - Aggressive automatic window relocation upon monitor disconnect.

---

## 5. Exit Criteria & Traceability

All requirements are verified against IEEE 29148 standards in [validation-report.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/display-aware-manipulation/validation-report.md).
Upon user sign-off at **Confirmation Gate 1**, this baseline will be marked `SIGNED-OFF v1.0`.
