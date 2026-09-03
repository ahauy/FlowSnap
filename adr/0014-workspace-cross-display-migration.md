# ADR-0014: Atomic Workspace Cross-Display Migration Architecture (US-DISP-017)

- **Status**: Accepted
- **Date**: 2026-09-04
- **Feature**: `workspace-cross-display-migration` (US-DISP-017)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

Modern macOS multi-monitor setups frequently require power users to move entire multi-window workflows (e.g. IDE on left 70% + Terminal & Browser on right 30%) between monitors (e.g., from Built-in Retina to an external 4K or ultrawide display).
Before US-DISP-017:

1. Users had to throw windows one by one across monitors using single-window throw shortcuts (`⌃⌥⇧→`). Each window had to be manually re-tiled and resized on the destination display.
2. If macOS Stage Manager was active, throwing windows individually or in quick succession broke the Stage group: WindowServer treated each activation as a stage swap, scattering the windows into the Stage Manager thumbnail strip.
3. Intermediate window overlaps caused noticeable layout jitter, and mouse cursor / divider coordinates remained stranded on the source display.

## Decision

1. **Dedicated Migration Coordinator (`WorkspaceMigrating` & `WorkspaceMigrator`)**:
   - Implements `WorkspaceMigrating` to coordinate atomic migration of the active workspace from the current display to the next/previous display in geometric topology.
   - Coordinates `WorkspaceManager`, `DisplayManaging`, `DisplayNavigating`, `WindowManaging`, `AccessibilityService`, `CursorWarping`, `StageManagerDetecting`, `PreferencesStore`, and `AdaptiveDividerCoordinator`.

2. **Source & Target Display Topology Resolution**:
   - Source display is resolved from the focused window's frame center, falling back to current cursor coordinates (`NSEvent.mouseLocation`).
   - Cyclic wrap-around navigation is handled via `DisplayNavigator.nextDisplay(after:in:)` and `DisplayNavigator.previousDisplay(before:in:)`.
   - Single-display configurations exit with a safe `.noOp(reason: .singleDisplay)`.

3. **Adaptive Move Ordering & Stage Cohesion**:
   - **Stage Manager Mode Active**: When Stage Manager is enabled and auto-grouping is on, the primary/anchor window is moved first. Secondary windows are moved with a staggered 40ms IPC delay and raised onto the stage using `kAXRaiseAction` (`AccessibilityService.raise(window:)`) without invoking `app.activate()`. Finally, the anchor window receives a final raise for keyboard focus lock.
   - **Stage Manager Mode Inactive (Standard macOS)**: FlowSnap executes a 2-phase move order: shrinking windows (`targetArea <= sourceArea`) are positioned first, followed by expanding windows. This eliminates transient overlapping and desktop congestion.

4. **Proportional Geometric Scaling (`RelativeFrameScaler`)**:
   - Window sizes and relative positions are proportionally scaled from `sourceDisplay.visibleFrame` to `targetDisplay.visibleFrame` using pure mathematical scaling. Dock and menu bar insets are respected on both displays.

5. **Ergonomic Post-Migration Cursor Warping & Divider Coordination**:
   - After window migration completes, the mouse cursor is smoothly warped to the center of the primary window on the target display via `CursorManager.warpCursor(to:)`.
   - Keyboard focus is locked onto the primary window via `WindowManager.focus(_:)`.
   - `AdaptiveDividerCoordinator.resetState()` is invoked to clear divider geometry on the source display and seamlessly re-anchor the divider overlay on the target display.

6. **Input Binding & Command Routing**:
   - Added `.migrateWorkspace(MigrationDirection)` to `WindowCommand`.
   - Bound default hotkeys `⌃⌥⇧⌘→` (Next Display) and `⌃⌥⇧⌘←` (Previous Display) via `ShortcutAction`.
   - Added quick access item to the macOS menu bar dropdown.

## Consequences

- **Positive**:
  - Entire workspaces move atomically across monitors with a single keystroke.
  - Full Stage Manager compatibility: stage grouping is maintained across displays without window scattering.
  - Zero desktop clutter or visual tearing during migration due to 2-phase ordering.
  - Seamless mouse warping keeps user attention directly on the relocated workflow.
  - Zero private APIs; 100% compliant with Apple Accessibility specifications.
- **Negative / Trade-offs**:
  - Secondary windows whose apps do not respond to `kAXRaiseAction` will move correctly to the target display, but may require manual clicking if Stage Manager detaches them.

## References

- `01-elicitation.md` — Confirmed decisions `ASM-MIG-001`, `ASM-MIG-002`, `ASM-MIG-003`.
- `CONTEXT.md` — Ubiquitous Language terms `WorkspaceMigrating`, `WorkspaceMigrator`, `MigrationDirection`, `MigrationResult`.
- `ADR-0010` — Cross-Display Window Throw Architecture.
- `ADR-0013` — Stage Manager Multi-Window Auto-Grouping Architecture.
