# ADR-0009: Per-App Window Policies & Smart Floating Stack Architecture (US-WORK-014)

- **Status**: Accepted
- **Date**: 2026-09-03
- **Feature**: `per-app-rules-floating-stack` (US-WORK-014)
- **Author**: FlowSnap Core Architecture Team

## Context & Problem Statement

Users need customized window placement rules per application (e.g., Telegram always floating, Spotify always remembering its last closed position, VS Code always snapped to a 70% left column). In addition, when floating apps are opened over an active tiled layout, they must not disturb underlying tiled windows, and dismissing a floating app should naturally restore keyboard/window focus to the previously active tiled window.

Key architectural challenges:

1. macOS does not provide a public API for third-party apps to change external window levels to `kCGFloatingWindowLevelKey` without private APIs.
2. Stored pixel frames for `.rememberPosition` risk opening windows off-screen when external displays are disconnected or display resolutions change.
3. Managing per-app rules requires persistence in `PreferencesStore`, synchronization with `WindowPolicyManager`, and an interactive configuration UI in `ApplicationRulesView`.

## Decision

1. **`WindowPolicy` Domain Model Expansion**:
   - `WindowPolicy` supports:
     - `.currentSpace`: Places window on active Space and primary display visible frame.
     - `.currentDisplay`: Places window on active display.
     - `.floating`: Exempt from tiling/grid layout modifications. Participates in `SmartFocusStack`.
     - `.rememberPosition`: Restores last known position, safely clamped to visible screen bounds.
     - `.assignedLayout(LayoutZone)`: Automatically snaps to a canonical layout zone upon window creation using `LayoutEngine`.
2. **Standard Window Level for Floating & MRU Focus Restoration**:
   - Floating apps retain standard window levels to avoid private CGS hacks.
   - `SmartFocusStack` maintains a Most-Recently-Used history of focused windows. When a floating application closes or hides, FlowSnap restores focus to the preceding non-floating window via `AccessibilityService.setFocus(element)`.
3. **Display-Aware Frame Clamping for Remembered Positions**:
   - `RememberedFrameStore` stores the last known frame per `bundleIdentifier`.
   - When restoring, coordinates are clamped against `DisplayManaging.primaryDisplay.visibleFrame` ensuring at least 80% visibility and preventing positioning under the menu bar or dock.
4. **Persistence in `PreferencesStore`**:
   - App rules are modeled as `AppPolicyRule` (Codable, Identifiable, Hashable) containing `bundleID: String`, `appName: String`, `policy: WindowPolicy`, and `iconName: String`.
   - Stored in `UserDefaults` via `PreferencesStore` with reactive `@Published` or `@Observable` properties.
5. **UI Seam**:
   - `ApplicationRulesView` connects directly to `PreferencesStore` and `WindowPolicyManager`, enabling users to add rules from installed/running apps, select policies from a picklist, and configure canonical snap zones.

## Consequences

- **Positive**:
  - 100% compliant with Public macOS APIs (zero private CGS symbols).
  - Tiled layouts remain stable when auxiliary/chat apps open.
  - Multi-display unplugging/plugging never leaves windows trapped in invisible coordinates.
  - Testable via mock services without requiring live macOS window server interactions.
- **Negative / Trade-offs**:
  - Cannot force a third-party window to remain permanently topmost across all spaces without private CGS window level manipulation. Standard level with focus management delivers the safe native equivalent.

## References

- `01-elicitation.md` — Confirmed decisions `ASM-POLICY-001`, `ASM-POLICY-002`, `ASM-POLICY-003`.
- `CONTEXT.md` — Ubiquitous Language terms for `AppPolicyRule`, `RememberedFrameStore`, `SmartFocusStack`.
- ADR-0001 — Zero Private APIs Mandate.
- ADR-0008 — Application Observing Protocol Seam.
