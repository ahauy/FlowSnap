# Risk Register & Scope Lock: Workspace Snapshot & Restoration (US-WORK-011)

- **Feature**: `workspace-snapshot-restoration`
- **Stage**: BA Pipeline — Stage 5: Risk & Contradiction Scanner
- **Anchors**: ASM-WORK-001 (auto-launch), ASM-WORK-002 (count-aware mapping), ASM-WORK-003 (additive restore)

---

## 1. Risk Matrix

| Risk ID | Description | Probability | Impact | Mitigation Strategy |
| :--- | :--- | :---: | :---: | :--- |
| **RISK-WORK-001** | **AX first-window observation hangs after auto-launch**: launched app shows no AX window within the wait window (slow first launch, login dialogs, notarization gatekeeper delay). | Medium | High | Hard ~10s timeout per app (BR-WORK-003/004); skip + report in `RestoreSummary`; never block remaining placements; restore continues sequentially per app. |
| **RISK-WORK-002** | **App not installed at restore time**: bundle-id in `workspaces.json` no longer resolves on this Mac. | Medium | Medium | Resolve via `NSWorkspace.urlForApplication(withBundleIdentifier:)` before launch; skip with `.notInstalled` reason; summary shows "Restored 2/3 — VS Code not running". |
| **RISK-WORK-003** | **Restore on differently-sized display misplaces windows**: zone/ratio math drifts across resolutions, notches, or menu-bar insets. | Medium | High | Intent-based placements only (BR-WORK-001); recompute frames from current display `visibleBounds` via `DisplayManager`/`CoordinateTransformer` (BR-WORK-007); mandatory test: restore on a display size different from save time. |
| **RISK-WORK-004** | **`workspaces.json` corruption or partial write** (crash mid-write, disk full) loses all saved workspaces. | Low | High | Atomic temp-file + rename writes (BR-WORK-009); on parse failure degrade to empty list + typed error, never crash; no silent overwrite of a corrupt file until user saves again. |
| **RISK-WORK-005** | **Concurrent store access races**: Popover, Settings, and restore flow read/write simultaneously. | Medium | Medium | All I/O funneled through the `WorkspaceStore` actor (BR-WORK-006); Swift 6 strict concurrency, zero Sendable warnings; UI reads via reactive `workspaces` on `@MainActor`. |
| **RISK-WORK-006** | **Extra windows of same app leak outside the zone**: count-aware stacking cascades beyond zone bounds or overlaps other workspace windows. | Medium | Medium | Clamp cascade offsets inside the placement zone (BR-WORK-002); deterministic stacking order (window order from `WindowRegistry`); covered by unit tests on zone math. |
| **RISK-WORK-007** | **Restore fights user's live work**: moving windows the user is actively dragging or typing into feels jarring. | Medium | Low | Additive restore only — non-workspace windows untouched (BR-WORK-005, ASM-WORK-003); restore is user-initiated and re-undoable by re-snapping (intake reversibility note). |
| **RISK-WORK-008** | **AX permission not granted** when restore is triggered from a fresh install or after permission reset. | Low | High | Pre-flight AX trust check via `AXAccessibilityService`; if untrusted, surface a non-blocking prompt and abort restore with zero partial moves. |
| **RISK-WORK-009** | **Schema drift breaks stored workspaces** (future field renames, v1.1 `exclusive` mode). | Low | Medium | Additive-only schema evolution; decode with optional/defaulted new fields; unknown fields tolerated; version field reserved in JSON root for v1.1. |
| **RISK-WORK-010** | **Duplicate workspace names confuse restore targets** (two "Coding" entries). | Low | Low | Case-insensitive uniqueness enforced in `WorkspaceStore.save` (BR-WORK-008); Save sheet blocks submit with inline error. |

## 2. Consolidated Assumptions (ASM → Risk traceability)

| Assumption | Decision carried into design | Related risks |
| :--- | :--- | :--- |
| **ASM-WORK-001** | Auto-launch missing apps via `NSWorkspace.open`, ≤10s first-window wait, graceful skip + summary report. | RISK-WORK-001, RISK-WORK-002, RISK-WORK-008 |
| **ASM-WORK-002** | Count-aware mapping: primary window → zone, extra same-app windows stacked/cascaded in the same zone. | RISK-WORK-006, RISK-WORK-003 |
| **ASM-WORK-003** | Additive restore in v1.0; `mode: additive \| exclusive` reserved as additive v1.1 schema change. | RISK-WORK-007, RISK-WORK-009 |

## 3. Contradiction & Scope Lock (MoSCoW)

- **Must-Have**:
  - Save flow: name + icon entry, capture of bundle-id → relative zone/ratio + per-app window count.
  - `WorkspaceStore` actor persisting to `~/Library/Application Support/FlowSnap/workspaces.json` (atomic writes).
  - Restore flow: count-aware mapping, auto-launch of missing apps with ≤10s timeout, graceful skip + summary.
  - Additive restore semantics (non-workspace windows untouched).
  - Restore onto the current display via `DisplayManager`/`CoordinateTransformer`.
  - Test proving restore on a display size different from save time.
- **Should-Have**:
  - Workspace list management (rename, delete with confirmation) in Popover and Settings.
  - Restore summary surfacing skipped apps with reasons.
  - Empty-state and store-error UX states with retry.
- **Could-Have**:
  - Icon picker with curated SF Symbol suggestions beyond a default set.
  - "Restore last used workspace" quick action in the popover.
  - Duplicate-name auto-suffix suggestion ("Coding 2").
- **Won't-Have (this feature / v1.0)**:
  - Exclusive restore mode (closing non-workspace windows) — deferred to v1.1 as additive `mode` field (ASM-WORK-003).
  - Window Groups & Named Presets — blocked successor US-WORK-012.
  - Hard pixel coordinates in placements — forbidden by design (BR-WORK-001).
  - Multi-display placement targets (restore pins to the current display only).
  - Cross-space / virtual-desktop window movement (not feasible with public APIs).
  - Cloud sync or shared workspace export/import.
