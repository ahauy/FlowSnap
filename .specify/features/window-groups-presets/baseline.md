# Domain Decision Baseline: Window Groups & Workspace Presets (US-WORK-012)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0  
**Feature Slug**: `window-groups-presets`  
**Date**: 2026-09-01

This document is compiled incrementally by every stage of the Universal BA Pipeline. Do not hand-edit past decisions in place; any subsequent scope adjustments require a version bump in `CHANGELOG.md`.

---

## Stage 0 — Intake

See `00-intake.md`. Classified as **Full Feature** (Full Feature Pipeline, Stages 1–8).

- **Roadmap Anchor**: Epic 10 / `US-WORK-012` (Window Groups & Named Presets).
- **Dependencies**: Depends on `US-WORK-011` (delivered); blocks `US-WORK-013` (App Launch Observer & Current Space Policy).

---

## Stage 2 — Elicitation (Confirmed Decisions)

See `01-elicitation.md`. Confirmed decisions:

| Decision ID       | Summary & Outcome                                                                                                                                                                                                                                                                                                    |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **ASM-GROUP-001** | **Smart App Category Fallbacks**: Presets define app categories (`.editor`, `.browser`, `.terminal`, `.notes`, `.writing`, `.design`) with prioritized fallback candidate lists. Resolution checks Running → Installed (launch via `NSWorkspace.open` with ≤ 10s wait) → Skip slot + report in `RestoreSummary`.     |
| **ASM-GROUP-002** | **Window Group Synchronization & Dynamic Lifecycle**: `WindowGroup` coordinates minimize/un-minimize, focus with z-order preservation, and spatial movement across ≥ 2 windows. Groups dynamically auto-prune on window destruction (`kAXUIElementDestroyedNotification`) and auto-dissolve when < 2 members remain. |
| **ASM-GROUP-003** | **Global Hotkey Dispatch & Collision Prevention**: Dedicated preset hotkeys (`⌃⌥C`, `⌃⌥R`, `⌃⌥W`, `⌃⌥D`) dispatched through `CommandDispatcher`. The Settings UI rejects collisions against existing snap shortcuts (`ShortcutAction.allCases`).                                                                     |

---

## Stage 4 — Domain Model

See `03-domain-model.md`.

- **Entities & Value Objects**: `WorkspacePreset`, `PresetAppSlot`, `PresetAppCategory`, `BuiltinPresetFactory`, `WindowGroup`, `GroupSyncOptions`.
- **Coordinators & Engines**: `@MainActor WindowGroupManager`, `CommandDispatcher.dispatch(.restorePreset(id))`.
- **Persistence**: Built-in presets as immutable domain templates; user hotkeys/options persisted in `PreferencesStore` (UserDefaults); custom workspaces in `workspaces.json`.

---

## Stage 5 — Risk Register

See `04-risk-register.md`. 8 risks analyzed (`RISK-GROUP-001…008`). Key mitigations:

- Re-entrancy locking & generation token to prevent echo loops in group synchronization.
- Event-driven auto-pruning to eliminate dangling `CGWindowID` references.
- 10.0s bounded launch timeout to prevent UI freezes on cold app launches.
- Pre-flight AX trust guard to prevent partial window mutations.

---

## Stage 6 — Specification Documents

- `spec/brd.md` — Business Context, Objectives OBJ-GROUP-01…04, BR-PRESET-001…006, BR-GROUP-001…006, Scope.
- `spec/prd.md` — Product Requirements PRD-PRESET-001…006, PRD-GROUP-001…006, NFR-GROUP-001…005, UX States.
- `spec/srs.md` — Software Requirements REQ-PRESET-001…007, REQ-GROUP-001…007 with derivation traceability and verification methods.
- `spec/user-stories.md` — User Stories US-WORK-012.1…4 with comprehensive Gherkin happy and edge-case scenarios.

---

## Stage 7 — Validation Gate

See `validation-report.md`.

- **IEEE 29148 Gate**: **PASS (100% Quality Conformance across all 8 criteria)**.
- **Assumption Conformance**: 3/3 passed.
- **Risk Coverage**: 8/8 passed.

---

## Stage 8 — Traceability & Sign-off

See `traceability-matrix.md`.

- 12/12 Business Rules mapped to PRD and SRS.
- 14/14 SRS Requirements mapped to User Stories and Swift Testing targets.
- 3/3 Assumptions and 8/8 Risks traced end-to-end.
- Zero orphan requirements; zero orphan scenarios.

---

## Core Business Rules Summary

- **BR-PRESET-001 (Curated Workflow Presets)**: 4 standard presets: Coding (60/25/15), Research (50/25/25), Writing (70/30), Design (70/30).
- **BR-PRESET-002 (App Category Fallbacks)**: Evaluates running candidate → installed candidate → skip slot.
- **BR-PRESET-003 (Graceful Launch & Toast)**: ≤ 10s timeout on auto-launch; non-blocking summary toast.
- **BR-PRESET-004 (Resolution-Independent Framing)**: Frames recomputed against active display's `visibleBounds`.
- **BR-PRESET-005 (Preset Hotkey Routing)**: Routed via `GlobalHotkeyManager` → `CommandDispatcher`.
- **BR-PRESET-006 (Hotkey Collision Rejection)**: Rejects collisions with standard snap actions in UI.
- **BR-GROUP-001 (Group Membership Cardinality)**: Minimum 2 members; dissolves when < 2.
- **BR-GROUP-002 (Simultaneous Minimize/Restore)**: Coordinated state transitions across all group members.
- **BR-GROUP-003 (Simultaneous Focus & Z-Order)**: Raises group windows to front while preserving relative z-order.
- **BR-GROUP-004 (Simultaneous Group Move)**: Coordinated relative translation when move sync is enabled.
- **BR-GROUP-005 (Re-Entrancy Guard)**: Ignores echo events during active group dispatch.
- **BR-GROUP-006 (Public API & Memory Safety)**: 100% Public AX APIs; dynamic auto-pruning on window destroy.

---

## Scope Lock (MoSCoW)

- **Must-Have (P0)**: Built-in presets factory (4 presets), smart fallback resolution, preset global hotkeys with collision check, `WindowGroup` core synchronization (minimize/restore, focus with z-order), dynamic auto-pruning, Settings presets gallery.
- **Should-Have (P1)**: Menu Bar popover presets submenu, restore summary toast, group move synchronization.
- **Could-Have (P2)**: Custom user preset authoring, visual group border highlighting.
- **Won't-Have (v1.0)**: Cross-Space / Mission Control window movement, native AppKit tab consolidation, cloud preset sync, app launch space trapping (deferred to `US-WORK-013`).
