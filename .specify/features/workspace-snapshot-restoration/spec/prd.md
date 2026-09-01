# Product Requirements Document: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

- **Feature**: `workspace-snapshot-restoration`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (PRD)
- **Anchors**: ASM-WORK-001 (auto-launch), ASM-WORK-002 (count-aware mapping), ASM-WORK-003 (additive restore)
- **Status**: SIGNED-OFF v1.0 — 2026-08-31
- **Upstream**: `spec/brd.md` (BR-WORK-001…010)

---

## 1. Product Overview

A named Workspace is a user-curated, intent-based snapshot of a multi-window
arrangement. The product delivers three flows: Save (capture current arrangement
under a user-chosen name + icon), Manage (list, rename, delete), and Restore
(dispatch windows of the mapped apps into their slots on the current display,
auto-launching apps that are not running).

## 2. Product Requirements

| ID | Requirement | Derived from (BR) | Assumption | Verified by (SRS) |
| :--- | :--- | :--- | :--- | :--- |
| PRD-WORK-001 | **Intent-Based Capture** — Save records, per app, its bundle identifier, the relative `LayoutZone` (incl. custom ratios/gaps from US-SNAP-008), and `expectedWindowCount`. No pixel coordinates are ever serialized. | BR-WORK-001, BR-WORK-007 | — | REQ-WORK-001, REQ-WORK-002 |
| PRD-WORK-002 | **Count-Aware Restore Mapping** — at restore, the primary window of each app takes the placement zone; extra same-bundle-id windows are stacked/cascaded sequentially inside the same zone with cascade offsets clamped inside zone bounds and deterministic order from `WindowRegistry`. | BR-WORK-002 | ASM-WORK-002 | REQ-WORK-003 |
| PRD-WORK-003 | **Auto-Launch & Place** — for each placement whose app is not running, resolve the app via `NSWorkspace.urlForApplication(withBundleIdentifier:)`, launch via `NSWorkspace.open`, wait ≤ 10s for the first AX window, then place. | BR-WORK-003, BR-WORK-010 | ASM-WORK-001 | REQ-WORK-004 |
| PRD-WORK-004 | **Graceful Skip & Summary** — apps that are not installed, fail to launch, or show no AX window within the timeout are skipped without blocking remaining placements; a `RestoreSummary` ("Restored 2/3 — VS Code not running") is surfaced in Popover and Settings and auto-dismisses. | BR-WORK-004 | ASM-WORK-001 | REQ-WORK-005 |
| PRD-WORK-005 | **Additive Restore Semantics** — restore touches only windows belonging to workspace apps; all other windows are untouched in v1.0. `mode` is always `additive`; `exclusive` is reserved for v1.1 as an additive schema change. | BR-WORK-005 | ASM-WORK-003 | REQ-WORK-006 |
| PRD-WORK-006 | **Actor-Backed Atomic Store** — a `WorkspaceStore` actor is the single writer to `~/Library/Application Support/FlowSnap/workspaces.json`; writes are temp-file + rename atomic; corrupt JSON degrades to empty list + typed error, never a crash; no silent overwrite of a corrupt file until the next user save. | BR-WORK-006, BR-WORK-009 | — | REQ-WORK-007, REQ-WORK-008 |
| PRD-WORK-007 | **Current-Display Geometry** — restore recomputes frames from the current display's `visibleBounds` via `DisplayManager`/`CoordinateTransformer`; save-time geometry is never reused. | BR-WORK-007 | — | REQ-WORK-002 |
| PRD-WORK-008 | **Unique Naming** — the Save flow blocks submit while the name is empty or duplicates an existing workspace (case-insensitive), with an inline error from a typed store error. | BR-WORK-008 | — | REQ-WORK-009 |
| PRD-WORK-009 | **Workspace Management UX** — Popover and SettingsView expose a reactive workspace list with empty-state CTA, rename, and delete-with-confirmation; restore entry points exist in both surfaces. | BR-WORK-006 | — | REQ-WORK-010 |
| PRD-WORK-010 | **AX Pre-Flight Guard** — restore performs an AX trust check via `AXAccessibilityService` before any move; if untrusted, surface a non-blocking prompt and abort with zero partial moves. | BR-WORK-004, BR-WORK-010 | — | REQ-WORK-011 |

## 3. Non-Functional Requirements

| ID | Requirement | Derived from |
| :--- | :--- | :--- |
| NFR-WORK-001 | Swift 6 strict concurrency: zero data-race/Sendable warnings; all store I/O behind the actor; UI reads via `@MainActor` reactive state. | Tech-context hard rules; RISK-WORK-005 |
| NFR-WORK-002 | No force unwrap `!`, no `try!`, no `as!`; file < 800 LOC; function < 50 LOC; `swiftlint --strict` passes. | Tech-context hard rules |
| NFR-WORK-003 | Restore of a 3-app workspace completes (placement dispatched or skip recorded) within ~15s worst case (3 × 10s timeout budget is bounded per app, not cumulative blocking of the UI). | BR-WORK-003/004; OBJ-WORK-01 |
| NFR-WORK-004 | Zero Private API policy: only `NSWorkspace`, AX, and public AppKit/SwiftUI. | BR-WORK-010 |
| NFR-WORK-005 | Additive-only schema evolution: unknown JSON fields tolerated; new fields optional/defaulted; version field reserved in the JSON root for v1.1. | RISK-WORK-009 |

## 4. UX States (from Domain Model §5)

| State | Surface | Behavior |
| :--- | :--- | :--- |
| Save Sheet | Popover / Settings | Name field + icon picker; Save disabled while name empty or duplicate (PRD-WORK-008); inline error on store failure. |
| Workspace List | Popover / SettingsView | Reactive `workspaces`; empty state with "Save current arrangement" CTA; delete with confirmation. |
| Restoring | Popover / Settings | Progress indicator while dispatching. |
| Restore Summary | Popover / Settings | "Restored 2/3 — VS Code not running" from `RestoreSummary`; auto-dismiss after a few seconds. |
| Store Error | Popover / Settings | Non-blocking alert on read/write failure; list falls back to empty; retry offered. |

## 5. Dependencies & Module Map

- `WorkspaceManager` (@MainActor, @Observable) orchestrates save/restore; depends on `WindowRegistry`, `AXAccessibilityService`, `LayoutEngine`, `DisplayManager`, `WorkspaceStore`.
- `WorkspaceStore` (actor) — single writer to `workspaces.json` (PRD-WORK-006).
- Reused modules: `AXAccessibilityService`, `WindowRegistry`, `LayoutEngine` (US-SNAP-008 ratios/gaps), `DisplayManager` + `CoordinateTransformer`, `CommandDispatcher` (US-SNAP-004), `PreferencesStore` (US-SNAP-010), `MenuBarController` (US-SNAP-005).

## 6. Release Plan

- **v1.0 (this feature)**: additive mode only; current-display restore; auto-launch with graceful skip.
- **v1.1 (reserved)**: `mode: additive | exclusive` as an additive schema change (ASM-WORK-003); "Restore last used workspace" quick action; duplicate-name auto-suffix suggestion.
- **Successor (blocked)**: US-WORK-012 Window Groups & Named Presets.
