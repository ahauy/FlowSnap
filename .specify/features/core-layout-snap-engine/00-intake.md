# Intake: Core Layout Calculation & Basic Snap Engine (US-SNAP-002)

- **Date**: 2026-08-28
- **Requested by**: Product Backlog & Roadmap (Sprint 1, Epic 2)
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 2 (`LayoutZone` enum / struct update, `SnapTarget` alignment)
  - Existing DB schema change: No
  - Screens/flows touched: Pure calculation engine + Snap coordinator + FlowSnapLab test harness
  - User roles affected: 1 (macOS desktop user)
  - Cross-cutting impact: Low (core geometric calculations isolated from AX hardware calls)
  - Estimated code lines changed: 100–250 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 [interactive interview, 2–3 questions] → 4 [light] → 5 [light] → 6 [user stories] → 7 → 8. Stage 3 gap-analysis skipped)
- **Override**: None

## One-line problem statement

FlowSnap requires a deterministic, pure-math layout calculation engine (`LayoutEngine`) and snap coordinator (`SnapEngine`) that converts normalized snap zones (halves, quarters, maximize, restore) into pixel-perfect target frames against any visible screen bounds, without depending on hardware or private macOS APIs.
