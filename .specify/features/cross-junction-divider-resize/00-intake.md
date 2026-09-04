# Intake: Multi-Window T-Junction & Crosshair Divider Resize

- **Date**: 2026-09-04
- **Requested by**: ahauy
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 1 (CrossJunction model extending divider topology)
  - Existing DB schema change: No
  - Screens/flows touched: 1 (Adaptive divider live resize interaction & overlay)
  - User roles affected: 1 (End user)
  - Cross-cutting impact: No
  - Estimated code lines changed: ~120–180 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1, 2 [Interactive Customer Interview], 4, 5 [Light], 6 [User Stories], 7, 8; Stage 3 skipped)
- **Override**: None

## One-line problem statement

Enable 4-way multi-window simultaneous resizing at T-junctions and cross junctions between 3 or 4 tiled windows with a single crosshair (`┼`) drag gesture.
