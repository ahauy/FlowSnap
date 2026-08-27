# Intake: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Date**: 2026-08-27
- **Requested by**: Product Roadmap (Sprint 1, Epic 1)
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 1 (`ManagedWindow` update, `WindowKind` enum)
  - Existing DB schema change: No
  - Screens/flows touched: 1 (Accessibility permission check + focused window query)
  - User roles affected: 1 (macOS desktop user)
  - Cross-cutting impact: No
  - Estimated code lines changed: 50–150 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 [interactive interview, 2–3 questions] → 4 [light] → 5 [light] → 6 [user stories] → 7 → 8. Stage 3 gap-analysis skipped)
- **Override**: None

## One-line problem statement

FlowSnap requires macOS Accessibility permissions (`AXUIElement`) to detect and inspect the geometry (frame, PID, title, kind) of the currently focused window without crashing or leaking memory.
