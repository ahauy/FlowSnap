# 01 — Elicitation Record (Stage 2) — workspace-snapshot-restoration

> Interview anchored on roadmap AC for US-WORK-011. Only underspecified / high-risk branches were grilled.
> Confirmed by user in chat: `1A, 2A, 3A`.

## Confirmed Decisions

### ASM-WORK-001 — Restore auto-launches missing apps (graceful fallback)

- **Decision:** Option A. When a workspace app is not running at restore time, FlowSnap auto-launches it via `NSWorkspace.open` (public API), waits for its first window via AX observation, then places it into its slot.
- **Fallback:** If the app is not installed, or launch / first-window creation times out (~10s), the app is skipped and reported in the restore summary (e.g. "Restored 2/3 — VS Code not running").
- **Rationale:** Matches the "Hero Feature" positioning — one-key workspace restoration.

### ASM-WORK-002 — Count-aware mapping with same-zone stacking

- **Decision:** Option A. Capture the window count per app at save time. At restore, the primary window takes the placement zone; extra windows of the same bundle-id are stacked/cascaded sequentially inside the same zone.
- **Rationale:** Title-based 1:1 mapping is brittle (titles change); frontmost-only mapping loses user windows.

### ASM-WORK-003 — Additive restore (non-workspace windows untouched)

- **Decision:** Option A. Restore only arranges windows belonging to the workspace; all other windows are left completely untouched in v1.0.
- **Future-proofing:** A per-workspace `mode: additive | exclusive` field may be added in v1.1 as an additive schema change without breaking `workspaces.json` compatibility.

## Anchored (not re-asked) — settled by roadmap AC

- Storage: JSON at `~/Library/Application Support/FlowSnap/workspaces.json`, actor-backed store.
- Placement model: intent-based (`WindowPlacement` = bundle-id → relative zone/ratio), never hard pixels → portable across displays.
- Save UX: user names the workspace (e.g. "Coding") with an icon.
- Restore UX: entry points in Menu Bar popover + Settings; restore onto the current display.
- Test requirement: restore must be verified on a screen size different from the one at save time.
