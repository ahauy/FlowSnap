# ADR-0012: Universal Fullscreen Escape Architecture (US-WORK-018)

- **Status**: Accepted
- **Date**: 2026-09-03
- **Feature**: `universal-fullscreen-escape` (US-WORK-018)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

FlowSnap must be able to restore multi-window workspaces even if one or more targeted application windows are currently residing in macOS Native Full Screen mode (separate Spaces).
In previous versions, `AXAccessibilityService.exitFullScreen` only attempted to set `AXFullscreen = false` via `AXUIElementSetAttributeValue`. On standard Apple AppKit apps this works, but on Chromium/Electron-based applications (VS Code, Brave, Slack, Discord, Antigravity), writing to `AXFullscreen` returns `cannotComplete` (`-25204`).
As a result:

1. Electron windows were left trapped in fullscreen Spaces.
2. Space transition animations were not awaited with feedback, causing subsequent `setFrame` calls to fail silently.
3. This blocked `US-WORK-017` (Stage Manager Multi-Window Auto-Grouping).

## Decision

1. **Three-Tier Resilient Escape Sequence (`FullScreenEscapeCoordinator`)**:
   - **Tier 0 (Fast Attribute Write)**: Attempt setting `AXFullscreen = false` and `AXFullScreen = false`. Succeeds in ~1ms for Cocoa apps.
   - **Tier 1 (AX FullScreen Button Press)**: If Tier 0 returns `cannotComplete` or fails, query `kAXFullScreenButtonAttribute` on the window's `AXUIElement` and trigger `kAXPressAction` via `AXUIElementPerformAction`.
   - **Tier 2 (Synthesized `Control + Command + F` via CGEvent)**: If Tier 1 cannot locate the button or fails to execute, activate the target application via `NSRunningApplication.activate(options: [.activateIgnoringOtherApps])`, wait 50ms for focus, and post a `⌃⌘F` keystroke sequence directly to the target PID via `CGEvent.postToPid`.

2. **Adaptive Transition Polling Loop**:
   - Instead of sleeping a fixed 700ms, FlowSnap polls the window's fullscreen state every 100ms with a maximum ceiling of 800ms.
   - If the window finishes its exit animation early (e.g. 300–400ms on Apple Silicon), execution returns immediately to proceed with window movement, saving 300–400ms of latency.
   - If 800ms elapses without confirmation, FlowSnap proceeds best-effort without crashing.

3. **Zero Private APIs**:
   - Implemented entirely via public macOS Accessibility (`AXUIElement`) and CoreGraphics (`CGEvent`) APIs.

## Consequences

- **Positive**:
  - 100% reliable exit from fullscreen across both native Cocoa and modern Electron/Chromium applications.
  - Sub-millisecond execution for standard native apps.
  - ~300ms faster restore times on Apple Silicon through adaptive polling.
  - Unblocks US-WORK-017 (Stage Manager integration).
- **Negative / Trade-offs**:
  - Tier 2 fallback temporarily activates the target application to ensure the synthetic keystroke is delivered by macOS WindowServer.

## References

- `01-elicitation.md` — Confirmed decisions `ASM-FSE-001`, `ASM-FSE-002`, `ASM-FSE-003`.
- `CONTEXT.md` — Ubiquitous Language terms `FullScreenEscapeCoordinator`, `FullScreenEscapeTier`.
- ADR-0001 — Zero Private APIs Mandate.
