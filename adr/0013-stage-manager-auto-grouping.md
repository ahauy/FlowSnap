# ADR-0013: Stage Manager Multi-Window Auto-Grouping Architecture (US-WORK-017)

- **Status**: Accepted
- **Date**: 2026-09-03
- **Feature**: `stage-manager-auto-grouping` (US-WORK-017)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

When macOS Stage Manager is enabled (`com.apple.WindowManager GloballyEnabled = 1`), macOS WindowServer treats each call to `NSRunningApplication.activate(options: [.activateAllWindows])` as a signal to bring that application forward onto a fresh stage.
In previous FlowSnap releases, `WorkspaceManager+Restore` called `launcher.reveal(bundleID:)` sequentially for every placement in a workspace.
As a result:

1. When restoring a multi-window workspace (e.g. VS Code 60% + Chrome 40%), VS Code was placed, but activating Chrome subsequently caused macOS to **eject VS Code from the stage into the Stage Manager thumbnail strip** on the left.
2. At the end of restore, only the last app remained on stage, breaking side-by-side workspace restoration for Stage Manager users.

## Decision

1. **Dynamic Stage Manager Detection (`StageManagerDetecting`)**:
   - `StageManagerDetector` queries the preference domain `com.apple.WindowManager` key `GloballyEnabled` dynamically at each restore pass using `CFPreferencesCopyAppValue`.
   - Bypasses cached values with zero private APIs, providing sub-millisecond detection and immediate response when users toggle Stage Manager in macOS Control Center.

2. **Smart Stage Coordination**:
   - **Anchor App Activation**: The first placement (`orderedPlacements.first`) is designated as the Anchor App. It is moved to its zone and activated via `launcher.reveal(bundleID:)` to establish the active Stage.
   - **Secondary App Raising via `kAXRaiseAction`**: All subsequent placements (`orderedPlacements.dropFirst()`) are unhidden if necessary (`launcher.unhide(bundleID:)`), positioned via `WindowManager.move()`, and brought onto the active Stage via `AccessibilityServing.raise(_:)` (`kAXRaiseAction`).
   - `app.activate()` is **STRICTLY NOT CALLED** for secondary apps. This instructs macOS to keep the secondary windows on the existing Stage alongside the Anchor App rather than swapping stages.
   - **Final Keyboard Focus Lock**: After all placements have been moved and raised, FlowSnap sends a final `raise` action to the primary window of the Anchor App, ensuring that primary keyboard focus is immediately ready on the user's primary application (e.g. code editor).

3. **Graceful Fallback**:
   - When Stage Manager is disabled or preference reading fails, FlowSnap automatically falls back to standard sequential reveal restoration.

## Consequences

- **Positive**:
  - Full side-by-side multi-window workspace restoration works reliably on macOS Stage Manager.
  - Zero private CGS/SLS APIs; 100% compliant with Apple Accessibility specifications.
  - Seamless backward compatibility when Stage Manager is turned off.
  - Primary keyboard focus is preserved on the main app.
- **Negative / Trade-offs**:
  - Secondary apps must support `kAXRaiseAction` on their window elements. If an app ignores `kAXRaiseAction`, FlowSnap falls back safely with best-effort window placement.

## References

- `01-elicitation.md` — Confirmed decisions `ASM-SMA-001`, `ASM-SMA-002`, `ASM-SMA-003`.
- `CONTEXT.md` — Ubiquitous Language terms `StageManagerDetecting`, `StageManagerDetector`, `SmartStageCoordination`.
- `ADR-0001` — Zero Private APIs Mandate.
- `ADR-0012` — Universal Fullscreen Escape Architecture.
