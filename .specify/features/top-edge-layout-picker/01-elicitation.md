# Elicitation Interview: US-SNAP-007 Top-Edge Snap Layout Picker

## 1. Interview Summary & Confirmed Decisions

- **Elicitation Date**: 2026-08-29
- **Target User Story**: `US-SNAP-007` (Epic 7: Windows 11-Style Top-Edge Snap Layout Picker)
- **Feature Slug**: `top-edge-layout-picker`
- **Interview Mode**: Interactive Live Interview (Batched Grilling)

### Confirmed Requirements & Architectural Trade-offs

1. **Trigger Mechanism (Top-Center Zone)**:
   - **Decision**: Trigger flyout when dragging a window into the top-center zone (middle 40% of screen width, within top 24px of the screen).
   - **Rationale**: Preserves rapid corner and edge maximize snaps on top-left / top-right areas while enabling the visual picker when intentionally aiming for the top-center bezel.
   - **Assumption ID**: `ASM-TOP-001`

2. **Layout Templates in Picker**:
   - **Decision**: Include 4 standard presets:
     - Template 1: 2 Columns 50/50 (`leftHalf`, `rightHalf`)
     - Template 2: 2 Columns Asymmetric 70/30 (`leftTwoThirds`, `rightOneThird`)
     - Template 3: 3 Columns Equal 1/3 (`leftThird`, `centerThird`, `rightThird`)
     - Template 4: 4 Quarters 2x2 (`topLeft`, `topRight`, `bottomLeft`, `bottomRight`)
   - **Assumption ID**: `ASM-TOP-002`

3. **Geometric Zone Architecture**:
   - **Decision**: Strongly-typed extension of `SnapTarget` enum and pure mathematical calculation in `LayoutEngine`:
     - `.leftTwoThirds` (70% width, full height)
     - `.rightOneThird` (30% width, full height)
     - `.leftThird` (33.33% width, full height)
     - `.centerThird` (33.34% width, full height)
     - `.rightThird` (33.33% width, full height)
   - **Rationale**: Keeps `SnapEngine`, `CommandDispatcher`, `LayoutEngine`, and `SnapPreviewManager` type-safe with zero floating-point string conversions or dynamic parsing overhead.
   - **Assumption ID**: `ASM-TOP-003`

4. **Visual & Interaction Behavior**:
   - **Panel Type**: Non-activating `NSPanel` (`.floating` level, `ignoresMouseEvents = false` during drag tracking, styled with macOS Liquid Glass blur / `NSVisualEffectView`).
   - **Hover Highlighting**: Hovering over any slot highlights the slot in the picker AND projects a translucent preview frame on screen via `SnapPreviewManaging`.
   - **Release & Snap**: Releasing mouse (`leftMouseUp`) inside a slot dispatches `.snap(target, targetDisplayID)` to `CommandDispatcher`, dismisses picker, and flashes snap feedback.
   - **Dismissal on Exit**: Moving mouse cursor below or away from the picker bounds dismisses the picker smoothly and reverts to normal edge drag-to-snap.
   - **Assumption ID**: `ASM-TOP-004`
