# Intake: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

- **Date**: 2026-08-28
- **Requested by**: Product Backlog & Roadmap (Sprint 1, Epic 3)
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 1 (`Display` domain model enhancement / `DisplayManaging` protocol)
  - Existing DB schema change: No
  - Screens/flows touched: Multi-monitor detection, AppKit-to-AX coordinate inversion math, screen reconnection observer, SnapEngine target display selection
  - User roles affected: 1 (macOS desktop user with single or multi-monitor setups)
  - Cross-cutting impact: Medium (Bridge between AppKit bottom-left and Accessibility top-left global coordinate systems)
  - Estimated code lines changed: 120–250 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 [interactive interview, 2–3 questions] → 4 [light] → 5 [light] → 6 [user stories] → 7 → 8. Stage 3 gap-analysis skipped)
- **Override**: None

## One-line problem statement

FlowSnap must accurately resolve the target `Display` containing the active window or cursor across heterogeneous multi-monitor layouts (horizontal, vertical, diagonal, differing Retina scales) and execute 100% accurate global coordinate inversion between AppKit and Accessibility APIs without private API dependencies.
