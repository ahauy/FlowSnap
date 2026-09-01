# Domain Decision Baseline: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

**Status**: SIGNED-OFF v1.0
**Version**: 1.0
**Feature Slug**: `workspace-snapshot-restoration`
**Date**: 2026-08-31

This document is compiled incrementally by every stage of the Universal BA
Pipeline. Do not hand-edit sections owned by another skill.

## Stage 0 — Intake

See `00-intake.md`. Classified Full Feature (Full Feature Pipeline, Stages 1–8).
Depends on US-SNAP-010 (delivered); blocks US-WORK-012.

## Stage 2 — Elicitation (Confirmed Decisions)

See `01-elicitation.md`. Confirmed by user: `1A, 2A, 3A`.

| Decision | Outcome |
| :--- | :--- |
| **ASM-WORK-001** | Auto-launch missing apps via `NSWorkspace.open`, wait ≤ 10s for first AX window, graceful skip + summary report. |
| **ASM-WORK-002** | Count-aware mapping: primary window → placement zone; extra same-bundle-id windows stacked/cascaded inside the same zone. |
| **ASM-WORK-003** | Additive restore in v1.0; `mode: additive \| exclusive` reserved as additive v1.1 schema change. |

## Stage 4 — Domain Model

See `03-domain-model.md`. Entities: `Workspace` (aggregate root), `WindowPlacement`
(value object), `WorkspaceStore` (persistence actor), `WorkspaceManager`
(@MainActor orchestrator), `RestoreSummary`/`SkippedApp`. Persistence: single JSON
document at `~/Library/Application Support/FlowSnap/workspaces.json`.

## Stage 5 — Risk Register

See `04-risk-register.md`. 10 risks (RISK-WORK-001…010); top mitigations: hard
~10s auto-launch timeout, intent-based placements + current-display recompute,
atomic temp-file + rename writes, AX pre-flight guard.

## Stage 6 — Specification

- `spec/brd.md` — business context, objectives OBJ-WORK-01…04, BR-WORK-001…010, MoSCoW scope lock.
- `spec/prd.md` — PRD-WORK-001…010, NFR-WORK-001…005, UX states, release plan.
- `spec/srs.md` — REQ-WORK-001…011, each with Derived from BR/ASM traceability, verification methods.
- `spec/user-stories.md` — US-WORK-011.1…4 with Gherkin happy + edge scenarios.

## Stage 7 — Validation

See `validation-report.md`. IEEE 29148: PASS (100% conformance, 8/8 criteria).
Assumption conformance and risk coverage checks clean; no blocking gaps.

## Stage 8 — Traceability & Sign-off

See `traceability-matrix.md`. 10/10 BRs, 11/11 REQs, 3/3 assumptions, 10/10 risks
traced end-to-end; no orphans.

## Core Business Rules (Summary)

- **BR-WORK-001 (Intent, Not Pixels)**: placements store bundle-id → relative zone/ratio only; hard pixels forbidden.
- **BR-WORK-002 (Count-Aware Mapping)**: primary window → zone; extras stacked/cascaded inside the same zone.
- **BR-WORK-003 (Auto-Launch Missing Apps)**: `NSWorkspace.open` + ≤ 10s AX first-window wait.
- **BR-WORK-004 (Graceful Skip & Report)**: skip uninstalled/timed-out apps; report "Restored 2/3 — VS Code not running"; never block the whole restore.
- **BR-WORK-005 (Additive Restore)**: only workspace windows are moved; others untouched in v1.0.
- **BR-WORK-006 (Actor-Backed Persistence)**: all I/O via `WorkspaceStore` actor to `workspaces.json`.
- **BR-WORK-007 (Current-Display Restore)**: recompute from current display `visibleBounds`, never save-time geometry.
- **BR-WORK-008 (Unique Workspace Names)**: case-insensitive uniqueness enforced at save.
- **BR-WORK-009 (Atomic Durable Writes)**: temp-file + rename; corrupt JSON degrades to empty list + typed error, never crash.
- **BR-WORK-010 (Zero Private API)**: only `NSWorkspace` and AX; no CGS/undocumented frameworks.

## Scope Lock (MoSCoW)

- **Must-Have**: save flow (name + icon, intent capture), actor-backed atomic store, restore flow (count-aware, auto-launch ≤ 10s, graceful skip + summary), additive semantics, current-display restore, different-display-size test.
- **Should-Have**: list management (rename, delete with confirmation), restore summary surfacing, empty-state/store-error UX with retry.
- **Could-Have**: curated icon picker, "Restore last used workspace" quick action, duplicate-name auto-suffix.
- **Won't-Have (v1.0)**: exclusive restore mode (v1.1 additive `mode` field), Window Groups & Named Presets (US-WORK-012), hard pixel coordinates, multi-display targets, cross-space movement, cloud sync/export.
