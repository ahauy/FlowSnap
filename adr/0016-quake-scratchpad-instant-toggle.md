# ADR-0016: Quake-Style Quick Scratchpad & Instant Window Toggle Architecture (US-SNAP-022)

- **Status**: Accepted
- **Date**: 2026-09-04
- **Feature**: `quake-scratchpad-instant-toggle` (US-SNAP-022)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

Power users (developers, researchers, writers) frequently require instantaneous, temporary access to a secondary utility window (such as a terminal like iTerm2, quick notes, calculator, or reference browser) while working full-screen or tiled in a primary application (e.g. Brave, VS Code).

On macOS, invoking secondary applications typically disrupts the user's workspace:

1. macOS may switch Desktop Spaces unexpectedly if the app was opened on another Space.
2. Tiling or window management requires manually resizing or rearranging windows, shrinking the primary working application.
3. Once the brief query or command is completed, closing or hiding the utility window requires awkward manual mouse clicks or multiple Command-Tab cycles to return focus to the previous application.

Technical challenges on macOS:

1. Zero Private APIs: The mechanism must not use undocumented CoreGraphics or SkyLight private APIs (`CGSSetWindowLevel`, `SLS...`).
2. Multi-window collision: If the utility app has multiple windows (e.g. Chrome or Terminal with 3 tabs in separate windows), calling `NSRunningApplication.hide()` hides ALL windows of that app, disturbing unrelated tasks.
3. Sub-50ms latency budget: The summon and dismiss transition must feel instantaneous.
4. Input focus return: Focus must return cleanly to the previous application and window without race conditions.

## Decision

1. **Explicit Scratchpad Registration (`ScratchpadRecord` & `ScratchpadCoordinating`)**:
   - The user can assign any currently focused window as the designated Scratchpad via global hotkey (`⌃⌥Space`) or from the Menu Bar.
   - FlowSnap records a `ScratchpadRecord` storing `CGWindowID`, `pid`, `bundleID`, `appName`, and `windowTitle`.

2. **Instant Summon with Pre-Summon Focus Snapshot (`< 50ms`)**:
   - When the user presses `⌥Space` (`ShortcutAction.toggleScratchpad`), `ScratchpadCoordinator` snapshots the currently active application and window (`PreSummonFocus`).
   - The coordinator raises the Scratchpad window via `kAXRaiseAction` (`AccessibilityServing.raise`) and activates the owning process via `activate(options: .activateIgnoringOtherApps)`.
   - The background application is never resized, preserving 100% of its geometry (Zero-Shrink).

3. **Hybrid Dismiss Mechanism (`ASM-SCRATCH-001`)**:
   - When dismiss is triggered:
     - If the Scratchpad app owns only 1 window: `ScratchpadCoordinator` calls `NSRunningApplication.hide()` to cleanly hide the process.
     - If the Scratchpad app owns ≥ 2 windows: `ScratchpadCoordinator` does NOT hide the application process; instead, it lowers the Scratchpad layer, deactivates it, and reactivates the application saved in `PreSummonFocus`.

4. **Dual Dismiss Triggers (ESC & Click-Outside Blur) (`ASM-SCRATCH-002`)**:
   - **ESC Key**: Intercepted conditionally only while the Scratchpad is active and focused (`dismissOnEsc == true`).
   - **Click-Outside Blur**: When `PreferencesStore.scratchpadDismissOnBlur == true`, an `NSEvent` global monitor detects mouse clicks outside the Scratchpad's frame and triggers dismiss.

5. **Safe Lifecycle Detach (`ASM-SCRATCH-003`)**:
   - Observes `NSWorkspace.didTerminateApplicationNotification` to automatically detach the Scratchpad if the process quits.
   - Automatically purges the record if an AX call returns `kAXErrorInvalidUIElement`.

## Consequences

- **Positive**:
  - Quake-style instant summon and dismiss experience for any macOS app.
  - Zero disruption to background applications (100% Zero-Shrink).
  - Clean focus restoration in `< 50ms`.
  - Protection against unintended hiding of multi-window applications.
  - 100% Public APIs, fully compatible with macOS Sonoma (14+) and Sequoia (15+).
- **Negative / Trade-offs**:
  - Requires Accessibility permissions (`AXIsProcessTrusted() == true`), standard for FlowSnap.
  - Does not draw custom slide-down animations across other third-party windows to avoid visual stutter without private APIs.

## References

- `01-elicitation.md` — Confirmed decisions `ASM-SCRATCH-001`, `ASM-SCRATCH-002`, `ASM-SCRATCH-003`.
- `CONTEXT.md` — Ubiquitous Language terms `ScratchpadCoordinating`, `ScratchpadCoordinator`, `ScratchpadRecord`, `ScratchpadState`, `PreSummonFocus`.
- `ADR-0015` — Universal Always-On-Top Window Pinning & Stage Manager Launch Co-existence Architecture.
