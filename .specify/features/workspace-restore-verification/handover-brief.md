# Handover Brief: Verified Workspace Restoration Enhancement

**Baseline version**: 1.0 (signed off 2026-09-02)  
**Spec documents**: [`spec/SRS.md`](spec/SRS.md), [`spec/user-stories.md`](spec/user-stories.md)  
**Traceability matrix**: [`traceability-matrix.md`](traceability-matrix.md)

## What's being built

P0 hardens manual Menu Bar/Settings workspace restore into a verified pipeline:
exact AX target resolution, fullscreen state gate, frame/minimized/fullscreen
post-condition checks, bounded retry, typed outcomes, and one final verified
focus. The existing summary banner reports placed/failed/unverifiable/skipped
groups without blocking the user, while diagnostics remain privacy-safe.

## What's explicitly out of scope

Cross-Space implementation beyond a non-blocking capability spike, picker app
names, resolve-by-frame fallback, cancellation/progress UI, hotkey/preset/group
flow changes, private Space APIs, summary persistence, and workspace JSON
migration.

## Known accepted risks/gaps

Cross-Space visibility is not provable from AX geometry and remains deferred.
Additional AX reads and summary/interface changes require regression coverage
across all existing consumers. No validation gaps were accepted.

## Next step

Invoke `speckit-specify` to generate the implementation specification, then
`speckit-plan` and `speckit-tasks` before coding.
