# Intake: Window Groups & Workspace Presets (US-WORK-012)

- **Date**: 2026-09-01
- **Requested by**: FlowSnap Product Backlog & Roadmap / EPIC 10 (US-WORK-012: Window Groups & Named Presets)
- **Classification**: Full Feature
- **Classification signals**:
  - New/changed domain entities: 4 (`WorkspacePreset`, `PresetTemplate`, `WindowGroup`, `PresetAppFallbackCategory` — built on top of `Workspace`, `WindowPlacement`, `LayoutZone`, and `LayoutRatio`)
  - Existing persistence schema change: Yes (additive UserDefaults key for preset hotkey bindings & customizable preset configs in `PreferencesStore`; zero breaking change to `workspaces.json`)
  - Screens/flows touched: 3 (Settings > Presets & Workspaces Gallery view with visual layout previews; Global Hotkey Manager & `CommandDispatcher` preset hotkey router; Menu Bar Popover Presets section & Window Group management actions)
  - User roles affected: 1 (Mac power user / FlowSnap user)
  - Cross-cutting impact: Yes (Domain → `PresetFactory` → `WindowGroupManager` → `WorkspaceManager` → `CommandDispatcher` → `GlobalHotkeyManager` → `SettingsView` / `MenuBarController`)
  - Estimated code lines changed: ~600–900 lines
  - Reversible without user impact: Yes (presets are stateless or additive templates; window groups are dynamic and dissolve safely on window close; zero destructive data mutations)
- **Protocol selected**: Full Feature Pipeline (Stages 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8, with interactive elicitation anchors, domain modeling, risk register, formal SRS, traceability matrix, and IEEE 29148 validation).
- **Override**: None (Matches roadmap Epic 10 / US-WORK-012 — Effort `M`, context-budget single-session, Priority Should-Have P1).
- **Roadmap dependencies**: Depends-on `US-WORK-011` (delivered). Blocks `US-WORK-013` (Application Launch Observer & Current Space Policy).

## Key roadmap constraints carried into Stage 2

1. **Curated Built-in Workflow Presets**:
   - Out-of-the-box presets for standard workflows:
     - **Coding Preset**: Primary Code Editor (60%), Documentation / Browser (25%), Terminal / Shell (15% / split).
     - **Research Preset**: Primary Research Browser (50%), Notes / Knowledge Base (25%), Secondary Reference / Browser (25%).
     - **Writing Preset**: Focused Document Editor (70%), Reference / Dictionary / Web (30%).
     - **Design Preset**: Vector / UI Design Editor (70%), Asset Palette / Reference Browser (30%).
2. **Smart App Fallback Chains**:
   - Presets must not be hardcoded to a single binary. If VS Code is not installed, fallback gracefully to Xcode or TextEdit; if Chrome is absent, fallback to Safari or Arc; if Notion is absent, fallback to Apple Notes.
3. **Dedicated Hotkey Activation**:
   - Instant activation hotkeys (e.g. `⌃⌥C` for Coding, `⌃⌥R` for Research, `⌃⌥W` for Writing, `⌃⌥D` for Design) with conflict prevention against snap hotkeys.
4. **Window Groups (Coordinated Multi-Window Management)**:
   - Grouping 2+ windows to coordinate simultaneous actions: collective move/shift, collective minimize/unminimize, and collective frontmost focus.
5. **Zero Private API & Strict Concurrency**:
   - 100% Public macOS APIs (`NSWorkspace`, AX API, AppKit / SwiftUI). Swift 6 strict concurrency with actor isolation for all group coordination and preset state.

## One-line problem statement

Empower Mac power users to instantly activate curated, intent-based multi-app workflow layouts (Coding, Research, Writing, Design) via dedicated hotkeys and smart application fallbacks, while linking collaborating windows into synchronized `WindowGroups` that move, minimize, and focus together.
