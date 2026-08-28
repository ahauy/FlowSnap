# Intake: Global Hotkeys & Command Dispatcher (US-SNAP-004)

- **Date**: 2026-08-28
- **Requested by**: FlowSnap Product Roadmap / Persona A (Hải - Senior Software Engineer)
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 1 (`HotkeyCombination` / `HotkeyBinding`)
  - Existing DB schema change: No
  - Screens/flows touched: 1 (Background hotkey listener & command dispatch to `SnapEngine`)
  - User roles affected: 1 (Mac power user / Developer)
  - Cross-cutting impact: No (strictly decoupled via `CommandDispatcher`)
  - Estimated code lines changed: ~150-250 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 [Interactive Grilling] → 4 [Light Domain Modeling] → 5 [Light Risk Register] → 6 [User Stories] → 7 [Validation] → 8 [Handover]). Stage 3 (`gap-analysis`) skipped.
- **Override**: None (Matches roadmap Effort `M`).

## One-line problem statement

Enable instant (< 50ms), conflict-free global hotkey interception across all macOS applications using Carbon Event Hotkeys and route actions asynchronously via `CommandDispatcher` to `SnapEngine`.
