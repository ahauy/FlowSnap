# ADR-0015: Universal Always-On-Top Window Pinning & Stage Manager Launch Co-existence Architecture (US-SNAP-021)

- **Status**: Accepted
- **Date**: 2026-09-04
- **Feature**: `always-on-top-window-pinning` (US-SNAP-021)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

macOS lacks a native "Always-on-Top" mechanism for third-party windows. Power users routinely require reference windows (calculators, documentation, video feeds, terminal outputs) to remain floating above background windows while actively typing and interacting with other applications.
Furthermore, when macOS Stage Manager is active, launching an application from Dock, Finder, Spotlight, or Raycast causes macOS to isolate the new app, pushing existing active Stage windows into the side thumbnail strip.

Technical challenges:

1. macOS AppKit offers no public API to adjust `CGWindowLevel` for windows belonging to other processes. Private APIs (e.g. `CGSSetWindowLevel`, `SLSSetWindowProperty`) violate Apple Hardened Runtime, Sandbox security, and FlowSnap's zero-private-API architectural constraint.
2. Multiple windows may be pinned concurrently, requiring an unambiguous, dynamic Z-ordering scheme.
3. System modal dialogs (Keychain, Touch ID, Apple ID authentication) must never be obscured.
4. Launching new apps in Stage Manager must preserve the current Stage without resource-intensive continuous polling.

## Decision

1. **Active Re-assertion Coordination (`WindowPinningCoordinating` & `WindowPinningCoordinator`)**:
   - Maintains an ordered list of pinned windows (`[PinnedWindowRecord]`) in Last-In-First-Out (LIFO) order.
   - Observes system window focus and activation events (`NSWorkspace.didActivateApplicationNotification` and `kAXFocusedWindowChangedNotification`).
   - When an unpinned window is focused, `WindowPinningCoordinator` immediately re-asserts all pinned windows from bottom to top using public Accessibility action `kAXRaiseAction` (`AXUIElementPerformAction(element, kAXRaiseAction)`).
   - Crucially, re-assertion **does not call `activate()`** or steal keyboard/text focus from the active background window.
   - Pinned windows remain visually on top with zero private APIs.

2. **System Modal Safety & Space Scoping**:
   - Inspects the active process identifier and bundle identifier. If the active app is `com.apple.SecurityAgent` or `com.apple.CoreAuthUI`, re-assertion is temporarily suspended to prevent obscuring authentication dialogs.
   - Pinned windows remain strictly scoped to the Desktop Space where they were pinned.

3. **Stage Manager Launch Co-existence (`StageManagerLaunchCoordinating` & `StageManagerLaunchCoordinator`)**:
   - Listens to `NSWorkspace.didLaunchApplicationNotification`.
   - When Stage Manager is enabled (`StageManagerDetecting.isStageManagerEnabled == true`) and `PreferencesStore.stageManagerLaunchCoexistenceEnabled == true`:
     - Snapshots existing visible windows on the active Stage.
     - Uses `ApplicationObserver` to await the new application's window creation (`kAXWindowCreatedNotification`) with a 5.0-second ceiling.
     - Executes coordinated `kAXRaiseAction` across previous Stage windows, merging them with the new window on the current Stage without sidebar strip ejection.

4. **Hotkey Binding & Menu Bar Status Item**:
   - Adds `ShortcutAction.togglePinFocusedWindow` (default: `Control + Option + P`).
   - Renders pinned window counts and interactive unpin options in `MenuBarView`.
   - Triggers a non-intrusive 1.0-second HUD Toast indicating `📌 Pinned [App]` or `Unpinned [App]`.

5. **Automatic Lifecycle Cleanup**:
   - Listens to `NSWorkspace.didTerminateApplicationNotification` to purge terminated apps from `pinnedWindows`.
   - Purges dead window IDs when `kAXRaiseAction` returns `kAXErrorInvalidUIElement`.

## Consequences

- **Positive**:
  - Universal always-on-top window pinning for any macOS application using 100% public APIs.
  - No continuous background CPU polling overhead (strictly event-driven).
  - Clean coexistence with Stage Manager when launching new apps.
  - Safe against obscuring system authentication dialogs.
  - Zero private APIs; fully compliant with macOS Hardened Runtime.
- **Negative / Trade-offs**:
  - Requires Accessibility permissions (`AXIsProcessTrusted() == true`), which FlowSnap already requires.

## References

- `01-elicitation.md` — Confirmed decisions `ASM-PIN-001`, `ASM-PIN-002`, `ASM-PIN-003`.
- `CONTEXT.md` — Ubiquitous Language terms `WindowPinningCoordinating`, `WindowPinningCoordinator`, `PinnedWindowRecord`, `StageManagerLaunchCoordinating`, `StageManagerLaunchCoordinator`.
- `ADR-0008` — Application Observing Seam (`ApplicationObserver`).
- `ADR-0013` — Stage Manager Multi-Window Auto-Grouping Architecture.
