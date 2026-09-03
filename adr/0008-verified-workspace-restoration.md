# ADR-0008: Verified Workspace Restoration Pipeline

- **Status:** Proposed
- **Date:** 2026-09-02
- **Deciders:** FlowSnap user proposal and Core Engineering
- **Technical context:** Existing restore counts AX `setFrame` success as placement success, uses a fixed fullscreen delay, and collapses all per-placement outcomes into `placed` or `skipped`.

## Context

macOS Accessibility can accept a frame write while silently leaving geometry or
window state unchanged. A fixed delay cannot prove that fullscreen transition
completed, and AX frame geometry cannot prove current-Space visibility. The
restore behavior therefore needs a single reusable seam that owns preparation,
verification, bounded retry, typed outcomes, and one final best-effort focus.

## Decision

Keep restore orchestration behind `WorkspaceManager` and keep AX mechanics behind
`AccessibilityService`. Add a minimal `isFullScreen` read, a named verification
policy, exact-element-only placement, and typed per-placement results aggregated
by `RestoreSummary`. Fullscreen polling is a state gate before `setFrame`; frame
and minimized/fullscreen checks are post-conditions; reveal/focus is a separate
final step. Do not introduce a second Space-management mechanism or a
resolve-by-frame fallback in P0.

## Consequences

### Positive

- Placement reports are truthful and testable even when AX silently ignores a
  write.
- Retry, fullscreen timing, and failure categorization are centralized and
  reusable by future restore callers.
- Existing workspace JSON and manual entry points remain compatible.
- Space visibility is not overclaimed, and focus churn is reduced to one final
  best-effort action.

### Negative / Trade-offs

- More AX reads and test seams are required after each move.
- Some restores previously shown as successful will now be reported as failed or
  unverifiable.
- Summary and protocol consumers must absorb additive result/reason fields.
- Cross-Space behavior remains unresolved until a separate capability spike.

### Alternatives considered

1. **Trust `setFrame` return value** — rejected because macOS can silently ignore
   the write.
2. **Keep a fixed 700ms fullscreen sleep** — rejected because elapsed time does
   not prove state completion across apps and machines.
3. **Resolve a missing AX element by frame** — rejected for P0 because it can
   move a different helper or invisible window.
4. **Create a new Space manager now** — rejected until US-WORK-013 capability is
   verified; public APIs do not establish a reliable current-Space proof.
