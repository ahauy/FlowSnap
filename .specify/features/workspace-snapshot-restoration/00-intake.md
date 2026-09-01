# Intake: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

- **Date**: 2026-08-31
- **Requested by**: FlowSnap Product Roadmap / EPIC 10 (Workspace Snapshots & Intent-Based Multi-Window Restoration)
- **Classification**: Full Feature
- **Classification signals**:
  - New/changed domain entities: 4 (`Workspace` and `WindowPlacement` — updated with full `Codable, Hashable`; new `WorkspaceStore` persistence actor; new `WorkspaceManager` mapping engine)
  - Existing persistence schema change: Yes (new JSON store at `~/Library/Application Support/FlowSnap/workspaces.json` via Swift Actor; additive — no migration of existing `UserDefaults` keys from US-SNAP-010)
  - Screens/flows touched: 3 (Save Workspace flow with identifier name + icon entry; Restore Workspace dispatch flow; Workspace list management in Popover and Settings)
  - User roles affected: 1 (Mac power user / FlowSnap user)
  - Cross-cutting impact: Yes (Domain → `WorkspaceStore` → `WorkspaceManager` → `AXAccessibilityService` / `WindowRegistry` / `LayoutEngine` / `DisplayManager` → `MenuBarController` / `SettingsView`)
  - Estimated code lines changed: ~500-800 lines
  - Reversible without user impact: Mostly (deleting `workspaces.json` reverts storage; restore moves live windows but is re-undoable by re-snapping)
- **Protocol selected**: Full Feature Pipeline (Stages 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8, all at full depth with interactive interview at Stage 2).
- **Override**: None (Matches roadmap Epic 10 / US-WORK-011 — Effort `M`, context-budget single-session, Priority Should-Have P1).
- **Roadmap dependencies**: Depends-on `US-SNAP-010` (delivered). Blocks `US-WORK-012` (Window Groups & Named Presets).

## Key roadmap constraints carried into Stage 2

- Snapshots store **intent, not pixels**: `WindowPlacement` = Bundle Identifier → relative zone / ratio region. Hard pixel coordinates are forbidden to keep layouts portable across displays.
- Restore must find windows of the mapped apps wherever they currently are and dispatch them to their defined slots **on the current display**.
- Persistence must go through a Swift Actor-backed JSON store (hard rule from `00-tech-context.md`).
- Tests must cover restoring a layout on a display of a different size than the one at save time.

## One-line problem statement

Enable users to save the current multi-window arrangement as a named, intent-based Workspace (app bundle identifier → relative zone/ratio placement, never hard pixel coordinates) persisted safely to `workspaces.json`, and restore it on demand by mapping the windows of running apps back onto their defined slots on the current display.
