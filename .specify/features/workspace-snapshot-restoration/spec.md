# Spec: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

**Feature Slug:** `workspace-snapshot-restoration`
**Baseline:** `.specify/features/workspace-snapshot-restoration/baseline.md` (SIGNED-OFF v1.0)
**Status:** Technical spec — pending Gate 2 approval

## 1. Technical Scope & Boundaries

### In Scope
- Upgrade Sprint-0 stubs: `Workspace`, `WindowPlacement`, `WorkspaceManager`, `WorkspaceStore`.
- Save flow: capture visible windows → group by bundle-id → infer `LayoutZone` per app → persist.
- Restore flow: resolve/launch apps → map windows to zones on the **current display** → move via AX.
- Actor-backed JSON persistence at `~/Library/Application Support/FlowSnap/workspaces.json`.
- UI entry points: Menu Bar popover section + new Settings "Workspaces" tab.
- Auto-launch of missing apps with ≤ 10s first-window wait and graceful skip.

### Out of Scope (locked by baseline MoSCoW)
- Exclusive restore mode (v1.1 additive `mode` field), Window Groups/Presets (US-WORK-012),
  pixel coordinates, multi-display targets, cross-space movement, cloud sync/export.

## 2. User Journeys

### J1 — Save Workspace
1. User opens Menu Bar popover → "Save Current Workspace…".
2. Sheet asks for name (unique, case-insensitive, non-empty) + icon (SF Symbol picker, curated set).
3. FlowSnap enumerates visible normal windows (excludes own pid, non-normal kinds, bundle-id-less windows),
   groups by bundle identifier, infers each app's zone from its current frame vs target display visibleFrame,
   records `expectedWindowCount`.
4. `WorkspaceStore` persists atomically. Popover shows success state.

### J2 — Restore Workspace
1. User clicks a workspace in popover (or Settings) → restore starts.
2. Target display = display of focused window → fallback cursor → fallback primary (reuses `DisplayManaging`).
3. For each placement (ordered by `orderIndex`): resolve running app by bundle-id;
   if absent → `ApplicationLauncher.open` → wait ≤ 10s for first normal window.
4. Primary window of the app → zone frame (recomputed from current `visibleFrame` + current gap).
   Extra windows → cascaded offsets inside the same zone, clamped to zone bounds.
5. Unresolvable apps are skipped with a reason; restore never aborts.
6. Summary surfaced: "Restored 2/3 — VS Code not running".

### J3 — Manage Workspaces
- Settings → Workspaces tab: list, rename (uniqueness enforced), delete (with confirmation), restore.

## 3. Functional Requirements (from SRS REQ-WORK-001…011)

- FR-1 Save captures intent only: bundle-id → `LayoutZone` + count. No pixels persisted (BR-001).
- FR-2 Zone inference is a pure function: max-IoU match between window normalized frame and zone
  normalized rects; deterministic tie-break by `LayoutZone.allCases` order.
- FR-3 Restore recomputes frames from current display `visibleFrame` and current `windowGap`
  (same gap semantics as `SnapEngine`) (BR-007).
- FR-4 Count-aware mapping: primary window → zone; extras cascade +24pt diagonal, clamped (BR-002).
- FR-5 Auto-launch via public `NSWorkspace` APIs only; ≤ 10s wait; skip reasons:
  `notInstalled`, `launchTimeout`, `noWindow` (BR-003/004).
- FR-6 Additive restore: non-workspace windows untouched (BR-005).
- FR-7 Persistence via `WorkspaceStore` actor; atomic temp-file + rename; corrupt JSON →
  empty list + typed error, never crash (BR-006/009).
- FR-8 Workspace names unique case-insensitively (BR-008).
- FR-9 List/rename/delete operations exposed to both popover and Settings.

## 4. Non-Functional Requirements

- NFR-1 Swift 6 strict concurrency: store is an `actor`; manager is `@MainActor`; zero Sendable warnings.
- NFR-2 No force unwrap/try/cast; file < 800 LOC; function < 50 LOC; `swiftlint lint --strict` passes.
- NFR-3 Restore dispatch latency: per-window AX move uses existing 2-phase `setFrame`; no polling
  except the bounded 10s launch-wait loop (100ms interval, self-terminating).
- NFR-4 Zero Private API (BR-010): `NSWorkspace` + AX only.
- NFR-5 Schema is additive-forward: unknown fields ignored on decode; v1.1 `mode` field will not break v1.0 files.

## 5. Edge Cases & Error Handling

| # | Edge case | Behavior |
|---|-----------|----------|
| E1 | Duplicate workspace name on save/rename | Typed error `duplicateName`; UI shows inline message |
| E2 | Empty name / whitespace-only | Rejected before capture |
| E3 | No eligible windows at save | Error `noEligibleWindows`; nothing persisted |
| E4 | App not installed at restore | Skip reason `notInstalled`; included in summary |
| E5 | Launch timeout / no window in 10s | Skip reason `launchTimeout` / `noWindow` |
| E6 | Window not resizable | Placed anyway (best effort); AX errors logged, restore continues |
| E7 | Corrupt workspaces.json | Empty list + `WorkspaceStoreError.corruptFile`; next save rewrites file |
| E8 | Restore on different display size than save | Frames recomputed from current visibleFrame (mandatory test) |
| E9 | More windows than at save | Extras cascade inside zone, clamped |
| E10 | Fewer windows than at save | Available windows placed; missing ones ignored (no error) |
| E11 | AX permission missing | Restore pre-flight guard → permission prompt path (reuses existing onboarding) |
| E12 | Minimized windows of a workspace app | Not enumerated (visible-only capture); app still placed via its visible windows |

## 6. Open Technical Decisions (resolved as ADRs — see plan.md)

- ADR-001: `WindowPlacement.zoneID: UUID` stub → replaced by `zone: LayoutZone` (+ count, orderIndex).
  Zero-migration: the stub was never persisted.
- ADR-002: Window enumeration reuses `AccessibilityService.allVisibleManagedWindows()` filtered by
  bundle-id — no new protocol surface.
- ADR-003: `WorkspaceStore` converted from class stub to `actor`; layouts stubs removed (never
  implemented, unused; belong to a future story).
- ADR-004: App launching abstracted behind `ApplicationLaunching` protocol for testability.
