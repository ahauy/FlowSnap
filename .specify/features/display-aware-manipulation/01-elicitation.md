# Elicitation Record: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Date**: 2026-08-28
- **Feature Slug**: `display-aware-manipulation`
- **Protocol Depth**: Bounded Task (Interactive Grilling Interview conducted, Stage 3 gap-analysis skipped)

---

## Stage 1 — Business Value

- **Problem & Pain Point**:
  In a multi-monitor macOS setup (e.g., MacBook screen + external 4K or ultra-wide displays arranged side-by-side or stacked), windows frequently overlap boundaries. Crucially, macOS uses two opposing coordinate systems:
  1. **AppKit (`NSScreen`)**: Origin `(0,0)` at bottom-left of the Primary screen; Y coordinates increase upward.
  2. **Accessibility API (`AXUIElement`)**: Global origin `(0,0)` at top-left of the Primary screen; Y coordinates increase downward.
     Without rigorous coordinate inversion and target display resolution, windows snap onto the wrong monitor, appear misplaced, or disappear entirely into negative coordinates.
- **Target Personas**:
  - Persona A (Hải): Senior Software Engineer with MacBook Pro + two 4K external monitors.
  - Persona B (Trang): Designer with 34" curved ultrawide + laptop Retina screen.
- **Success Metrics**:
  - 100% precision in coordinate inversion across arbitrary display arrangements (horizontal, vertical, diagonal).
  - Target display selection correctly picks the display with maximum overlap area even when windows cross display borders.
  - Display reconnection / layout changes are observed reactively without freezing the main thread or crashing.

---

## Pillar 1 — Target Display Resolution (Overlapping / Straddling Windows)

**Q1: Multi-monitor display resolution policy**

- **Decision**: **Option A — Maximum Intersection Area** (Confirmed by User).
  When a window straddles across multiple screens, the target display is the one with the maximum intersection area (`CGRectIntersection(windowFrame, displayFrame)`). If the window is completely off-screen or has zero intersection area with all displays, fallback to the display containing the current mouse cursor location.

---

## Pillar 2 — Coordinate Inversion Architecture

**Q2: Coordinate transformation design**

- **Decision**: **Option A — Pure Functional Bidirectional Math** (Confirmed by User).
  `CoordinateTransformer` is a pure, stateless struct with static methods:
  - `toAX(rect:fromPrimaryScreenHeight:) -> CGRect`
  - `toAppKit(rect:fromPrimaryScreenHeight:) -> CGRect`
  - `toAX(point:fromPrimaryScreenHeight:) -> CGPoint`
  - `toAppKit(point:fromPrimaryScreenHeight:) -> CGPoint`
    Zero dependencies on system singletons (`NSScreen.screens`), fully deterministic and testable.
    A mockable `DisplayManaging` protocol abstracts display enumeration and screen change notifications.

---

## Pillar 3 — Display Reconfiguration & Notification Lifecycle

**Q3: Screen disconnection & resolution change behavior**

- **Decision**: **Option A — Passive Reactive Update** (Confirmed by User).
  Listen to `NSApplication.didChangeScreenParametersNotification` to update the active `[Display]` list and refresh primary screen dimensions. Do not aggressively force-move windows on disconnect; allow macOS WindowServer to manage repositioning, and apply FlowSnap layout calculations cleanly whenever the user issues the next snap/restore command.

---

## Pillar 4 — Grilling Session: Edge Cases & Multi-Monitor Topologies

**Q4: Menu Bar & Dock variations per screen**

- **Decision**: **Strict `visibleFrame` Isolation** (Confirmed by User).
  Snap zones are strictly calculated against each display's individual `visibleFrame`, guaranteeing zero overlap with local Dock or Menu Bar regardless of whether macOS "Displays have separate Spaces" is enabled or disabled.

**Q5: Mirrored Displays Handling (`CGDisplayIsInMirrorSet`)**

- **Decision**: **Filter to Primary/Active Mirror Master** (Confirmed by User).
  Treat mirrored displays as a single logical `Display` using the master screen's geometry to prevent duplicate or conflicting snap targets.

**Q6: Relative Zone Migration (`nextDisplay`)**

- **Decision**: **Support Relative Zone Migration** (Confirmed by User).
  Provide `nextDisplay(after:)` on `DisplayManaging` to allow moving windows across displays while preserving their normalized layout zone (e.g. left half on Screen 1 moves to left half on Screen 2).

**Q7: Sub-pixel Coordinate Precision**

- **Decision**: **Sub-pixel Integrity (Exact `CGFloat`)** (Confirmed by User).
  Preserve exact floating-point values without premature rounding or integral truncation. Let macOS CoreGraphics/Quartz handle sub-pixel rendering.

**Q8: Single Display & Cyclic Wrap-around**

- **Decision**: **Cyclic Wrap-around with Single Display Guard** (Confirmed by User).
  For $\ge 2$ displays, `nextDisplay` cycles $1 \to 2 \to \dots \to N \to 1$. If only 1 display is connected, return `nil` (no-op) to prevent redundant recalculation.

---

## Assumptions Confirmed

- **ASM-DISP-001**: Primary display in macOS is always defined by the screen whose AppKit origin is `(0, 0)`. Its full height $H_{Primary}$ serves as the universal reference for global AX coordinate inversion:
  $$Y_{AX} = H_{Primary} - (Y_{AppKit} + Height)$$
- **ASM-DISP-002**: All AppKit and AX coordinates are expressed in points (logical points), regardless of display Retina scale factor (1x vs 2x). Scale factor is preserved in `Display` for UI rendering and HUD overlays.
- **ASM-DISP-003**: The target display for a window with positive intersection area is `argmax(area(CGRectIntersection(window.frame, display.frame)))`.
- **ASM-DISP-004**: If intersection area across all displays is zero (e.g. window dragged entirely off-screen or display disconnected), the target display falls back to the display containing the current mouse cursor. If cursor is also outside known bounds, default to the Primary display.
- **ASM-DISP-005**: `DisplayManager` is actor-isolated or `@MainActor` to safely observe AppKit notifications and query `NSScreen.screens`.
- **ASM-DISP-006**: Mirrored screens are coalesced into a single logical `Display` using the active mirror master.
- **ASM-DISP-007**: When moving a window to an adjacent display (`nextDisplay`), the window's current layout zone is mapped to the new display's `visibleFrame`. If only 1 display is connected, `nextDisplay` returns `nil`.
- **ASM-DISP-008**: All calculations preserve exact `CGFloat` points without premature `floor`/`ceil` truncation.

---

## Open Questions

- None. All 8 design branches resolved and user-confirmed.
