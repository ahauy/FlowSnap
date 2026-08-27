# Elicitation Record: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Date**: 2026-08-28
- **Feature Slug**: `core-layout-snap-engine`
- **Protocol Depth**: Bounded Task (Interactive interview conducted, Stage 3 gap-analysis skipped)

---

## Stage 1 — Business Value

- **Problem & Pain Point**:
  Window snapping on macOS requires precise geometry calculations to divide available display real estate cleanly. Without deterministic mathematics, rounding discrepancies cause 1px gaps or borders overflowing off-screen. Furthermore, when users snap windows, they frequently want to return to their free-form position; without tracking the pre-snap frame, restore functionality is impossible or unreliable.
- **Target Personas**:
  All macOS desktop users (Software Engineers, Designers, Researchers) who require immediate, pixel-perfect window placement across various display resolutions (13" Retina, FHD, 2K, 4K, portrait displays).
- **Success Metrics**:
  - Pure calculation execution time < 1ms per layout computation (zero I/O or system call overhead).
  - 100% pixel coverage without gaps or overflows across odd and even screen dimensions.
  - Zero loss of user's original window frame when chaining multiple consecutive snap actions before restoring.

---

## Pillar 1 — Geometric Calculations & Odd-Pixel Handling

**Q1: Odd-pixel screen dimension division**

- **Decision**: **Option A** (Confirmed by User).
  Round down for left/top (`floor(dimension / 2)`) and allocate the remaining pixel to right/bottom (`dimension - leftOrTop`) to prevent visible background gaps and avoid screen boundary overflow.

---

## Pillar 2 — Restore Lifecycle & State Machine

**Q2: Consecutive snap restore behavior**

- **Decision**: **Option A** (Confirmed by User).
  Restore recovers the **original pre-snap frame** (the user-positioned frame before any consecutive snap operations began). Snapping a window multiple times (e.g. Left -> Right -> Maximize) retains the initial user-positioned frame as the single restore destination until the user manually moves/resizes the window or performs a restore.

---

## Pillar 3 — Minimum Size Constraints & Edge Cases

**Q3: Minimum window size constraints**

- **Decision**: **Option A** (Confirmed by User).
  Honor the application's minimum size constraint. Anchor the window at the target zone's outer corner/edge and permit excess dimensions to extend inward toward the center of the screen, preserving usability without violating the app's internal layout constraints.

---

## Assumptions Confirmed

- **ASM-LAYOUT-001**: Available screen space is derived from `visibleFrame` (screen bounds minus macOS Menu Bar and Dock). Coordinates are evaluated in the target display's visible bounds.
- **ASM-LAYOUT-002**: Odd-pixel resolution splits allocate remainder pixels to the right or bottom half (`width - floor(width/2)`).
- **ASM-LAYOUT-003**: A window's pre-snap frame is stored in `WindowRegistry` upon the first snap action and cleared only when restored or when explicitly reset.
- **ASM-LAYOUT-004**: If an application has minimum dimensions exceeding a target snap zone, the window is anchored to the requested corner/edge and sized to `max(calculatedSize, appMinSize)`.
- **ASM-LAYOUT-005**: All calculations in `LayoutEngine` are pure functions with zero external side effects and zero dependencies on AppKit or Accessibility APIs.

---

## Open Questions

- None. All 3 elicitation questions confirmed by user (`1A, 2A, 3A`).
