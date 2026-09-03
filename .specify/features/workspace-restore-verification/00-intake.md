# Intake: Verified Workspace Restoration Enhancement (US-WORK-011)

- **Date**: 2026-09-02
- **Requested by**: FlowSnap user proposal `US-WORK-011_Giai_phap_hoan_chinh_v2.md`
- **Classification**: Full Feature / scope enhancement
- **Classification signals**:
  - New/changed domain entities: 3+ (`MoveOutcome`, verification result/policy, additional `SkipReason`, app display metadata)
  - Existing persistence schema change: No confirmed schema migration; must preserve existing workspace data
  - Screens/flows touched: 2 (restore orchestration and workspace picker)
  - User roles affected: 1 (Mac power user / FlowSnap user)
  - Cross-cutting impact: Yes (WorkspaceManager, WindowManager, AccessibilityService, launch/observer infrastructure, restore summary, picker UI)
  - Estimated code lines changed: 200+ including tests and integration seams
  - Reversible without user impact: Mostly; restore remains user-triggered and additive
- **Protocol selected**: Full Feature Pipeline (Stages 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8, with interactive elicitation before spec/code)
- **Override**: None
- **Baseline relationship**: Enhancement to `.specify/features/workspace-snapshot-restoration/` after its `SIGNED-OFF v1.0` baseline; the signed baseline remains immutable.

## One-line problem statement

Make Workspace Restore report success only after verifiable geometry/state checks, handle fullscreen transitions deterministically, separate placement from best-effort visibility/focus, and show app names in the workspace picker.

## Proposal interpretation

The attached Markdown is treated as a proposal containing intended behaviors, implementation guidance, and test ideas. It is not itself an approved specification; ambiguous policy choices must be confirmed during elicitation.
