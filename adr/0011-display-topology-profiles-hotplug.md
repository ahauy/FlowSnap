# ADR-0011: Display Topology Profiles & Hot-Plug Rebalancer Architecture (US-DISP-016)

- **Status**: Accepted
- **Date**: 2026-09-03
- **Feature**: `display-topology-profiles-hotplug` (US-DISP-016)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

When external displays are connected or disconnected (e.g., unplugging a laptop from a desk dock, or hot-plugging an HDMI/Type-C monitor), macOS abruptly reflows or cascades windows onto the remaining screens. This creates two distinct friction points:

1. **Hot-Unplug**: Windows formerly on the external screen can be placed with their title bars off-screen, under the menu bar, or scattered chaotically across the laptop display.
2. **Hot-Plug Reconnect**: When the user reconnects the same monitor later, macOS leaves the windows grouped on the laptop display. The user is forced to manually drag and re-tile their workspace every single time.

Additionally, macOS fires multiple `NSApplication.didChangeScreenParametersNotification` events in rapid succession during hardware negotiation or when waking from sleep ("screen flapping").

## Decision

1. **Deterministic Topology Fingerprint (`TopologyFingerprint`)**:
   - Every display topology is identified by a deterministic SHA-256 hash.
   - Sourced solely from public APIs:
     - Sorted screens from left-to-right (`x` origin ascending).
     - Display UUID via `CGDisplayCreateUUIDFromDisplayID` (or vendor/model ID fallback).
     - Screen `localizedName` (e.g. `"Built-in Retina Display"`, `"KG270 M5"`).
     - Resolution bounds and visible frame size.
   - Completely private-API-free, compatible with App Store and Hardened Runtime.

2. **Debounced Hot-Plug Observer (`DisplayHotPlugObserver`)**:
   - Listens to `NSApplication.didChangeScreenParametersNotification`.
   - Coalesces rapid notifications with a 600ms debounce timer to allow display negotiation to settle.
   - Emits a unified `@MainActor` topology change event once stable.

3. **Hot-Unplug Safe Proportional Clamping & Auto-Snapshot (`FrameClampingHelper`)**:
   - When display count decreases (disconnect event):
     - FlowSnap captures an automated snapshot of active window placements associated with the departing topology fingerprint.
     - Windows moving onto the primary display are clamped using `FrameClampingHelper`:
       - Proportional shrink if window width/height exceeds primary `visibleFrame`.
       - Title bar safety zone: Window top boundary clamped strictly below Menu Bar (`minY >= visibleFrame.minY`) with title bar height (≥ 36pt) fully accessible.
       - Window bounds clamped inside `visibleFrame.maxX` and `visibleFrame.maxY`.

4. **Zero-Prompt Auto-Restore on Hot-Plug Reconnect (`TopologyProfileManager`)**:
   - When a known `TopologyFingerprint` is detected after reconnect:
     - Automatically looks up the saved `DisplayTopologyProfile`.
     - Dispatches windows back to their designated displays and zones asynchronously.
     - Skips applications that are no longer running without error; reinforces focus on the primary active window.

## Consequences

- **Positive**:
  - Seamless, zero-friction transition between mobile laptop use and multi-monitor desk setups.
  - Zero private APIs.
  - Robust against display negotiation flapping via 600ms debounce.
  - Title bars can never be lost off-screen.
- **Negative / Trade-offs**:
  - Debounce introduces a 600ms delay after cable connection before window restoration begins (essential for hardware stability).

## References

- `01-elicitation.md` — Confirmed decisions `ASM-DISP-004`, `ASM-DISP-005`, `ASM-DISP-006`.
- `CONTEXT.md` — Ubiquitous Language terms for `TopologyFingerprint`, `DisplayTopologyProfile`, `FrameClampingHelper`.
- ADR-0001 — Zero Private APIs Mandate.
- ADR-0010 — Cross-Display Window Throw Architecture.
