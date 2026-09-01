# Business Requirements Document: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

- **Feature**: `workspace-snapshot-restoration`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (BRD)
- **Anchors**: ASM-WORK-001 (auto-launch), ASM-WORK-002 (count-aware mapping), ASM-WORK-003 (additive restore)
- **Status**: SIGNED-OFF v1.0 — 2026-08-31

---

## 1. Business Context

FlowSnap is a macOS-native (SwiftUI + AppKit, LSUIElement agent app) window management
utility for Mac power users. Its "Hero Feature" positioning is one-key workspace
restoration: a user arranges their apps once, saves the arrangement as a named
Workspace, and restores it on demand with a single action.

Today, users must manually re-open apps and re-snap windows one by one after
reboots, display changes, or context switches (e.g. switching between "Coding"
and "Writing" setups). This is repetitive, error-prone, and undermines FlowSnap's
core value proposition of effortless window management.

## 2. Business Objectives & Success Metrics

| ID | Objective | Metric | Target |
| :--- | :--- | :--- | :--- |
| OBJ-WORK-01 | Eliminate manual multi-window setup after context switches | Median time to restore a 3-app workspace | < 5s (vs. ~60s manual) |
| OBJ-WORK-02 | Make saved layouts portable across displays | Restore accuracy on a display size different from save time | 100% of placements land inside the correct relative zone |
| OBJ-WORK-03 | Build trust through predictable, non-destructive restore | Restores completing without user-visible failure of the whole flow | ≥ 99% of restore invocations never abort the whole flow |
| OBJ-WORK-04 | Protect user data integrity | Workspace loss due to store corruption | 0 incidents (atomic writes, degrade-not-crash) |

## 3. Stakeholders & Concerns

| Stakeholder | Concern | Addressed by |
| :--- | :--- | :--- |
| Mac power user (primary) | One-key restore of a full multi-app arrangement | OBJ-WORK-01, BR-WORK-003 |
| User with multiple displays | Layout survives display changes | OBJ-WORK-02, BR-WORK-001/007 |
| User mid-task | Restore must not fight live work | OBJ-WORK-03, BR-WORK-005 |
| FlowSnap support | No data loss, no crashes, diagnosable failures | OBJ-WORK-04, BR-WORK-009 |
| App Store / notarization review | Zero Private API policy | BR-WORK-010 |

## 4. Business Requirements

| ID | Requirement | Derived from | Satisfied by (PRD) |
| :--- | :--- | :--- | :--- |
| BR-WORK-001 | **Intent, Not Pixels** — placements store only bundle-id → relative zone/ratio; hard pixel coordinates are forbidden in `workspaces.json` so layouts stay portable across displays of any size. | Roadmap US-WORK-011 AC; RISK-WORK-003 | PRD-WORK-001 |
| BR-WORK-002 | **Count-Aware Mapping** — save captures `expectedWindowCount` per app; at restore the primary window takes the placement zone and extra same-bundle-id windows are stacked/cascaded sequentially inside the same zone. | ASM-WORK-002; RISK-WORK-006 | PRD-WORK-002 |
| BR-WORK-003 | **Auto-Launch Missing Apps** — if an app is not running at restore, launch via `NSWorkspace.open` (public API), wait ≤ 10s for its first window via AX observation, then place it. | ASM-WORK-001; RISK-WORK-001 | PRD-WORK-003 |
| BR-WORK-004 | **Graceful Skip & Report** — if an app is not installed or launch/first-window times out, skip it and report in `RestoreSummary` ("Restored 2/3 — VS Code not running"); never block or fail the whole restore. | ASM-WORK-001; RISK-WORK-001/002 | PRD-WORK-004 |
| BR-WORK-005 | **Additive Restore** — restore arranges only windows belonging to the workspace; all other windows remain untouched in v1.0. `mode` field reserved for v1.1 `exclusive`. | ASM-WORK-03; RISK-WORK-007 | PRD-WORK-005 |
| BR-WORK-006 | **Actor-Backed Persistence** — all reads/writes go through the `WorkspaceStore` actor to `~/Library/Application Support/FlowSnap/workspaces.json`; no direct file I/O from UI or manager; additive schema, no UserDefaults migration. | Tech-context hard rule; RISK-WORK-005 | PRD-WORK-006 |
| BR-WORK-007 | **Current-Display Restore** — placements map onto the current display's `visibleBounds` via `DisplayManager`/`CoordinateTransformer`, never the geometry captured at save time. | Roadmap AC; RISK-WORK-003 | PRD-WORK-001/007 |
| BR-WORK-008 | **Unique Workspace Names** — `name` is unique among persisted workspaces; `WorkspaceStore.save` rejects duplicates (case-insensitive) with a typed error surfaced in the Save flow. | RISK-WORK-010 | PRD-WORK-008 |
| BR-WORK-009 | **Atomic Durable Writes** — `WorkspaceStore` writes via temp-file + rename; corrupt/unreadable JSON degrades to empty list + typed error, never a crash; no silent overwrite of a corrupt file until the user saves again. | RISK-WORK-004 | PRD-WORK-006 |
| BR-WORK-010 | **Zero Private API** — restore uses only public APIs (`NSWorkspace.open`, AX). No CGS or undocumented frameworks. | Tech-context hard rule | PRD-WORK-003 |

## 5. Scope

### 5.1 In Scope (v1.0)

- Save flow: user-named workspace (name + SF Symbol icon) capturing bundle-id → relative zone/ratio + per-app window count.
- `WorkspaceStore` actor persisting to `workspaces.json` with atomic writes.
- Restore flow: count-aware mapping, auto-launch of missing apps (≤ 10s timeout), graceful skip + summary.
- Additive restore semantics; restore onto the current display.
- Workspace list management (rename, delete with confirmation) in Popover and Settings.
- Test proving restore on a display size different from save time.

### 5.2 Out of Scope (Won't-Have, v1.0)

- Exclusive restore mode (closing non-workspace windows) — deferred to v1.1 as additive `mode` field (ASM-WORK-003).
- Window Groups & Named Presets — blocked successor US-WORK-012.
- Hard pixel coordinates in placements — forbidden by design (BR-WORK-001).
- Multi-display placement targets; restore pins to the current display only.
- Cross-space / virtual-desktop window movement (not feasible with public APIs).
- Cloud sync or shared workspace export/import.

## 6. Assumptions & Dependencies

- ASM-WORK-001/002/003 are confirmed decisions (elicitation Stage 2) and are binding for design.
- Depends on delivered modules: `AXAccessibilityService`, `WindowRegistry`, `LayoutEngine` (incl. custom ratios/gaps, US-SNAP-008), `DisplayManager` + `CoordinateTransformer`, `CommandDispatcher`, `PreferencesStore` (US-SNAP-010), `MenuBarController`.
- Blocks successor US-WORK-012 (Window Groups & Named Presets).
