# Intake: Workspace Presentation Observation (P0.5)

- **Date**: 2026-09-02
- **Requested by**: FlowSnap product stakeholder
- **Classification**: Bounded Task
- **Classification signals**: One additive observation abstraction and result state; one existing restore flow; one existing summary/banner surface; no persistence or schema change; estimated implementation 100–200 lines plus tests; explicitly excludes Cross-Space migration.
- **Protocol selected**: Bounded Task — elicitation interview, light domain model, light risk scan, user-story specification, validation, and handover before technical planning.
- **Override**: None

## One-line problem statement

Workspace restore can verify AX geometry and state without proving that the target window is presented on the current screen, causing the user-facing summary to overstate a restore as successful.

