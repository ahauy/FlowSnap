# Changelog: Adaptive Multi-Window Divider Resize (US-SNAP-009)

- v0.1-draft — 2026-08-28 — Feature folder created by intake-classifier. Classified as Bounded Task under EPIC 08: Adaptive Multi-Window Resize (Shared Collinear Divider) & Gaps.
- v0.2-draft — 2026-08-29 — Stage 1–7 of BA Pipeline completed. User stories, domain models (`LayoutGraph`, `CollinearEdge`, `LayoutNode`), risk register, and SRS compiled. Passed IEEE 29148 specification validation.
- v1.0 — 2026-08-29 — Baseline approved and signed-off at Confirmation Gate 1. Handed over to Speckit technical planning (`baseline.md`, `spec.md`, `plan.md`, `tasks.md`, `test-plan.md`).
- v1.1 — 2026-08-30 — Phase 5 TDD implementation completed. Built `CollinearEdgeDetector`, `LiveResizeThrottler`, `AdaptiveDividerCoordinator`, and `AdaptiveDividerOverlayPanel`. Initial suite of 143 tests passing.
- v1.2 — 2026-08-31 — Defect Remediation & Production Stabilization: Resolved 4 critical defects:
  1. **Event Pass-Through**: Configured `AdaptiveDividerOverlayPanel.ignoresMouseEvents = true` and routed mouse interaction through global `NSEvent` monitors in `AdaptiveDividerCoordinator`, ensuring transparent native click-through and app focus for underlying windows.
  2. **Shrink-First AX Ordering**: Implemented 2-phase setFrame ordering in `AdaptiveDividerCoordinator` and `AXAccessibilityService` (moving and shrinking contracting windows before expanding expanding windows) to eliminate macOS WindowServer collision clamping and live resize stutter.
  3. **Hard Seam Clamping & Dynamic Floors**: Hardened `seamBounds` with invariant boundary locking (`origin...origin`), dynamic `floorWidth`/`floorHeight` calculation ($380\times 260\,\text{pt}$ safe floors while preserving pre-existing narrow panes like 80/20 splits), and strict drag coordinate clamping ensuring zero window overlap under extreme cursor yanks (-1000px / +2000px).
  4. **AX Coordinate Matching & Multi-Window Resolution**: Enhanced `AXAccessibilityService.windowElement(for:)` with `CoordinateTransformer` AppKit-to-AX coordinate space transformation and fuzzy bounding box matching ($\Delta < 30\,\text{pt}$) to correctly resolve AX window handles for multi-window processes (same PID).
  5. Expanded test coverage to 175 tests in 29 suites with 100% pass rate.
- v1.3 — 2026-08-31 — Divider Drag Stability Patch (7 defects resolved):
  1. **BUG-01 Dual-trigger mouseDown**: Added `guard !isResizing` in `handleMouseDown` to prevent simultaneous overlay callback + global `downMonitor` from double-initializing `initialWindows`, which corrupted Escape-to-cancel restore.
  2. **BUG-02 Horizontal drag drift**: Added `await refreshWindowsIfNeeded()` call immediately after `isResizing = false` in `handleMouseUp` so the next drag session reads actual AX frames, eliminating X-axis positional drift on repeated horizontal divider drags.
  3. **BUG-03 Display-crossing instability**: Introduced `dragContainer: CGRect?` locked at `mouseDown` and used throughout `handleMouseDragged` and `handleMouseUp`, preventing multi-monitor cursor drift from changing the resize container mid-session.
  4. **BUG-04 Final snap visual jump**: Changed `handleMouseUp` `targetCoordinate` from raw `point.x/y` to `divider.coordinate` (already clamped by `seamBounds`) eliminating 1-2pt jump between live preview and committed frame on mouseUp.
  5. **BUG-06 convertToScreen negative-offset display**: Replaced manual `localPoint + containerFrame.minX/Y` with `window?.convertPoint(toScreen:)` in `AdaptiveDividerOverlayView`, with safe fallback for pre-window unit test context.
  6. **BUG-07 Phantom hit areas post-stop**: Added `overlayView.updateState(... dividers: [])` calls in both `stop()` and `endSession()` so divider hit areas are cleared before `hide()`.
  7. **BUG-08 isShrinking area heuristic**: Replaced `width * height` area comparison with dimension-specific check (`width` for vertical dividers, `height` for horizontal) ensuring correct 2-phase AX ordering for extreme aspect-ratio windows.
  - `dragContainer` cleared in `stop()`, `endSession()`, and `cancelResize()` to prevent stale state across sessions.
- v1.4 — 2026-08-31 — Fast-Drag Performance Patch (4 bottlenecks resolved):
  1. **PERF-01 Work-loop scheduler**: Rewrote `scheduleDragTask` from a fire-and-forget Task to a work-loop that keeps `isDragScheduled = true` until `pendingDragPoint` is fully drained. Eliminates unbounded concurrent `handleMouseDragged` Tasks during 120Hz fast drags; only one AX call chain runs at a time.
  2. **PERF-02 Sync resolveGap**: Removed spurious `async` from `resolveGap()` — `preferencesStore.windowGap` is a `@MainActor @AppStorage` property and never performs real async work. Introduced `dragGap: CGFloat` cached at `mouseDown`; hover path retains a direct sync call.
  3. **PERF-03 Cache primaryScreenHeight**: Added `dragPrimaryHeight: CGFloat` cached at `mouseDown` via a single `await displayManager.primaryScreenHeight`. Removes per-event DisplayManager IPC inside the `applyResizedFrames` AX loop (previously called once per drag event × window count).
  4. **PERF-04 Batch registry updates**: Separated `windowRegistry.update()` calls from the AX write loop in `applyResizedFrames`. All AX writes complete first (preserving shrink-first 2-phase ordering), then a single batch pass updates the registry — reduces actor hops from O(N) interleaved to O(N) sequential post-AX.
  - Both `dragGap` and `dragPrimaryHeight` cleared in `stop()`, `endSession()`, and `cancelResize()`.
- v1.5 — 2026-08-31 — Boundary Attachment & Ultra-Smooth Drag Patch (5 critical remediations):
  1. **Seam Tolerance Hardening (`effectiveTolerance`)**: In `CollinearEdgeDetector.seamPair`, hardened the proximity check to `max(tolerance, gap + 6.0)` and updated coordinator detection tolerances (`max(gap + 12.0, 16.0)` for cached dividers and `max(gap + 16.0, 24.0)` during live drags), ensuring divider lines NEVER detach or vanish when windows hit minimum size limits or render with sub-pixel offsets.
  2. **Monotonic Minimum-Size Retention**: Made `activeMinSizes` strictly monotonic during active drag sessions (only expanding or maintaining discovered minSizes) and removed mid-drag clearing, completely eliminating window overlap and boundary oscillation when an app enforces an internal minimum size (e.g., Xcode, Chrome, Slack).
  3. **Shrink-Only AX Readback**: Optimized `applyResizedFrames` to only invoke `syncActualWindowFrame` on shrinking windows (as expanding windows never violate minimum size floors), eliminating ~50% of synchronous AX attribute read IPC overhead per frame.
  4. **AX Write Optimization**: Streamlined `AXAccessibilityService.setFrame` to eliminate redundant `kAXPositionAttribute` copy-attribute queries before setting frames, saving an additional AX IPC round-trip per window on every live drag tick.
  5. **Resilient Window Filtering**: Updated `filterWindows(for:)` to use `initialWindows` during active resize sessions, ensuring windows are never erroneously dropped if their frames temporarily shift near screen edges.
  - Expanded test suite to 187 passing unit tests in 29 suites with 100% pass rate.
- v1.6 — 2026-08-31 — Selective Click Capture & Native macOS Edge Shielding Patch:
  1. **Selective Click Capture (`ignoresMouseEvents = false` + `hitTest`)**: Enabled mouse event processing on `AdaptiveDividerOverlayPanel` with selective hit testing in `AdaptiveDividerOverlayView`. When mouse is within the $\pm 9\,\text{pt}$ divider seam, the overlay captures the click $100\%$, shielding the underlying window's native $4-6\,\text{pt}$ resize border and completely preventing macOS native resize conflicts. Clicks outside the seam return `nil` and pass through naturally.
  2. **18pt Capture Seam Thickness**: Increased `seamThickness` and `captureWidth` to $18.0\,\text{pt}$ (`max(18.0, gap + 16.0)`), completely covering macOS native window borders on both sides of any divider.
  3. **Instant Native Cursor Feedback**: Connected `resetCursorRects()`, `cursorUpdate()`, and coordinator `setCursor` to dynamically switch the hardware cursor to `.resizeLeftRight` (vertical) or `.resizeUpDown` (horizontal) the instant the pointer enters the divider zone, and back to `.arrow` when leaving.
  - Test suite passing: 187 tests in 29 suites with 100% pass rate.
- v1.7 — 2026-08-31 — Z-Order Window Occlusion Filtering Patch:
  1. **Z-Order Occlusion Filtering**: Implemented multi-window occlusion detection in `CollinearEdgeDetector.detect` and `seamPair`. Windows positioned higher in the front-to-back stacking order (index $k < \max(i, j)$) that cross or cover background seam coordinates dynamically clip the visible divider span or completely discard occluded seams.
  2. **Stacking Order Preservation**: Updated `AdaptiveDividerCoordinator.refreshWindowsIfNeeded` to prioritize live WindowServer stacking order from `accessibilityService.allVisibleManagedWindows()`, ensuring foreground windows (floating dialogs, picture-in-picture, unmanaged windows) always shield dividers from hover highlighting and click capture.
  - Expanded test suite to 188 passing unit tests in 29 suites with 100% pass rate.
- v1.8 — 2026-08-31 — Clean-Workspace Idle State & Click-Through Restoration:
  1. **Idle overlay fully retired (`restingAlpha` 0.22 → 0.0)**: leaving the pointer off a seam now
     shows *nothing* on screen. `show(containerFrame:…)` early-returns to `hide(animated:)` unless
     `activeDivider != nil || isDragging`, so a resting presentation can no longer be requested.
     `update(…)` keeps the conditional target alpha for the drag→release fade.
  2. **`endSession()` no longer re-presents resting outlines**: the post-drag branch that called
     `show(activeDivider: nil)` was replaced with a single `hide(animated: true)`, so the seam fades
     out once the drag commits instead of lingering at low alpha.
  3. **Hover-gated presentation**: `handleMouseMoved(to:)` presents only when `detector.hitTestDivider`
     returns a seam (`if let activeDivider = hovered`), rather than whenever the display has any
     dividers — the panel is now invisible for the whole time the pointer is away from a seam.
  4. **Click-through restored (`ignoresMouseEvents` false → true)**: reverting the v1.6 "Selective
     Click Capture" experiment. With the panel accepting hits, a click inside the 18pt seam reached
     the overlay but the underlying window never received its own mouse-down, so apps whose custom
     title bar / toolbar buttons sit near the seam (Chrome tabs, Xcode navigator toggles) stopped
     responding. Seam hit-testing, drag start and cursor shape are owned by the coordinator's global
     `NSEvent` monitors (`.mouseMoved` / `.leftMouseDown` / `.leftMouseDragged` / `.leftMouseUp`),
     which need no window-level event delivery; `AdaptiveDividerOverlayView.hitTest`,
     `resetCursorRects()` and `cursorUpdate(with:)` remain in place but are dormant while the panel
     is click-through.
  5. **Test alignment**: `AdaptiveDividerOverlayPanelTests` still asserted the v1.6 contract and
     failed against this behaviour. Updated 3 tests — initialization now expects
     `ignoresMouseEvents == true`; the idle case expects `isOverlayVisible == false`; the former
     "persistent resting outline at 0.22" suite became "overlay is fully hidden when idle and opaque
     on hover or drag" (`restingAlpha == 0.0`, hover → visible, drag → alpha 1.0).
     `AdaptiveDividerCoordinatorTests` were updated alongside the hover/endSession branches.
  - Full suite: 261 tests in 35 suites, 100% pass rate.
