# Software Requirements Specification: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

- **Feature**: `workspace-snapshot-restoration`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (SRS)
- **Anchors**: ASM-WORK-001 (auto-launch), ASM-WORK-002 (count-aware mapping), ASM-WORK-003 (additive restore)
- **Status**: SIGNED-OFF v1.0 — 2026-08-31
- **Upstream**: `spec/brd.md` (BR-WORK-###), `spec/prd.md` (PRD-WORK-###)

---

## 1. Functional Requirements

### REQ-WORK-001 — Intent-Based Workspace Capture

**Derived from**: BR-WORK-001, BR-WORK-002 | **Assumption**: ASM-WORK-002 | **Satisfies**: PRD-WORK-001

The system shall, on Save, capture one `WindowPlacement` per workspace app
containing: `bundleIdentifier`, the relative `LayoutZone` (with `LayoutRatio`
incl. custom ratios/gaps), and `expectedWindowCount` observed via
`WindowRegistry`. The serialized `Workspace` shall contain no absolute pixel
coordinates.

### REQ-WORK-002 — Portable Frame Recomputation

**Derived from**: BR-WORK-001, BR-WORK-007 | **Assumption**: — | **Satisfies**: PRD-WORK-001, PRD-WORK-007

At restore, the system shall recompute every target frame from the current
display's `visibleBounds` via `DisplayManager`/`CoordinateTransformer` and
convert to AX coordinates. Save-time display geometry shall never be reused.

### REQ-WORK-003 — Count-Aware Stacking

**Derived from**: BR-WORK-002 | **Assumption**: ASM-WORK-002 | **Satisfies**: PRD-WORK-002

For each placement with `expectedWindowCount > 1`, the system shall place the
primary window into the placement zone and stack/cascade each additional
same-bundle-id window sequentially inside the same zone, with cascade offsets
clamped inside zone bounds and deterministic order taken from `WindowRegistry`.

### REQ-WORK-004 — Auto-Launch of Missing Apps

**Derived from**: BR-WORK-003, BR-WORK-010 | **Assumption**: ASM-WORK-001 | **Satisfies**: PRD-WORK-003

For each placement whose app is not running, the system shall resolve the app
via `NSWorkspace.urlForApplication(withBundleIdentifier:)`; if resolvable,
launch it via `NSWorkspace.open` and wait ≤ 10s for its first window via AX
observation before placing it. Only public APIs shall be used.

### REQ-WORK-005 — Graceful Skip & Restore Summary

**Derived from**: BR-WORK-004 | **Assumption**: ASM-WORK-001 | **Satisfies**: PRD-WORK-004

The system shall skip a placement — recording a `SkippedApp` with reason
`.notInstalled`, `.launchTimeout`, or `.noWindowAppeared` — when the app is
unresolvable, launch/first-window exceeds the ~10s timeout, or no window
appears. Skipping shall never block or abort remaining placements. The system
shall report a `RestoreSummary` (`restoredCount`, `totalCount`, `skipped`) in
Popover and Settings, e.g. "Restored 2/3 — VS Code not running", auto-dismissed
after a few seconds.

### REQ-WORK-006 — Additive Restore Semantics

**Derived from**: BR-WORK-005 | **Assumption**: ASM-WORK-003 | **Satisfies**: PRD-WORK-005

The system shall move only windows whose bundle identifiers appear in the
workspace's placements. All other windows shall remain untouched. The
`Workspace.mode` field shall serialize as `additive` in v1.0; `exclusive` is
reserved for v1.1 as an additive schema change.

### REQ-WORK-007 — Actor-Backed Persistence

**Derived from**: BR-WORK-006 | **Assumption**: — | **Satisfies**: PRD-WORK-006

All reads and writes of workspaces shall go through the `WorkspaceStore` actor
persisting a `[Workspace]` array to
`~/Library/Application Support/FlowSnap/workspaces.json`. No UI or manager code
shall perform direct file I/O on workspace data. No migration of US-SNAP-010
UserDefaults keys is required.

### REQ-WORK-008 — Atomic Durable Writes & Corruption Resilience

**Derived from**: BR-WORK-009 | **Assumption**: — | **Satisfies**: PRD-WORK-006

`WorkspaceStore` shall write via temp-file + rename (atomic). On corrupt or
unreadable JSON, the store shall degrade to an empty list plus a typed error —
never crash — and shall not silently overwrite the corrupt file until the user
saves again.

### REQ-WORK-009 — Unique Workspace Names

**Derived from**: BR-WORK-008 | **Assumption**: — | **Satisfies**: PRD-WORK-008

`WorkspaceStore.save` shall reject a workspace whose `name` duplicates an
existing workspace case-insensitively, surfacing a typed error. The Save sheet
shall disable submit while the name is empty or duplicate and show an inline
error.

### REQ-WORK-010 — Workspace Management UX

**Derived from**: BR-WORK-006 | **Assumption**: — | **Satisfies**: PRD-WORK-009

Popover and SettingsView shall present a reactive `workspaces` list with an
empty-state CTA ("Save current arrangement"), rename, delete with confirmation,
and restore entry points in both surfaces.

### REQ-WORK-011 — AX Pre-Flight Guard

**Derived from**: BR-WORK-004, BR-WORK-010 | **Assumption**: — | **Satisfies**: PRD-WORK-010

Before dispatching any placement, the system shall verify AX trust via
`AXAccessibilityService`; if untrusted, it shall surface a non-blocking prompt
and abort restore with zero partial window moves.

## 2. Non-Functional Requirements

- **NFR-WORK-001** (from PRD): Swift 6 strict concurrency, zero Sendable warnings; store I/O actor-isolated.
- **NFR-WORK-002**: no `!`/`try!`/`as!`; file < 800 LOC; function < 50 LOC; `swiftlint --strict` passes.
- **NFR-WORK-003**: per-app timeout bounded (~10s); restore never blocks the main thread.
- **NFR-WORK-004**: zero Private API (no CGS/undocumented frameworks).
- **NFR-WORK-005**: additive-only schema evolution; unknown fields tolerated; version field reserved.

## 3. Verification Methods

| REQ | Method | Test target |
| :--- | :--- | :--- |
| REQ-WORK-001 | Unit (Swift Testing `@Test`) | `WorkspaceManagerTests` — capture produces placements, no pixel fields |
| REQ-WORK-002 | Unit + Integration | `DisplayManagerTests` — recompute on different display size |
| REQ-WORK-003 | Unit | `WorkspaceManagerTests` — stacking/clamp math on zone bounds |
| REQ-WORK-004 | Unit (mocked `NSWorkspace`-like double) | `WorkspaceManagerTests` — launch + ≤10s wait |
| REQ-WORK-005 | Unit | `WorkspaceManagerTests` — skip reasons, summary counts |
| REQ-WORK-006 | Unit | `WorkspaceManagerTests` — non-workspace windows untouched |
| REQ-WORK-007 | Unit | `WorkspaceStoreTests` — actor isolation, file path |
| REQ-WORK-008 | Unit | `WorkspaceStoreTests` — atomic write, corrupt-file degrade |
| REQ-WORK-009 | Unit | `WorkspaceStoreTests` — duplicate rejection (case-insensitive) |
| REQ-WORK-010 | UI test / manual | Popover + Settings flows |
| REQ-WORK-011 | Unit + manual | Pre-flight abort with zero moves |

Mandatory integration test (roadmap AC): restore a saved workspace on a display
size different from the one at save time and assert all placements land inside
the correct relative zones (REQ-WORK-002, RISK-WORK-003).
