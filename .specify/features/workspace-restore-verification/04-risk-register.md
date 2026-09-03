# Risk Register & Contradiction Scan: Verified Workspace Restoration Enhancement

- **Feature**: `workspace-restore-verification`
- **Stage**: BA Pipeline — Stage 5: Risk & Contradiction Scanner

## 1. Contradiction scan

### Findings reviewed

1. **Outcome naming vs. summary accounting:** The domain model separates
   `failed`, `unverifiable`, and `skipped`, while the existing code only has
   `skipped`. **Resolved** by making the new summary contract authoritative:
   issue collections and counters are distinct, with the conservation rule
   `placed + failed + unverifiable + skipped == total`.
2. **Fullscreen transition vs. retry:** Generic move retry could accidentally
   retry a failed fullscreen preparation. **Resolved** by modeling fullscreen as
   a pre-placement gate; throw/timeout produces zero `setFrame` attempts and no
   move retry.
3. **AX frame vs. Space visibility:** A geometry match could be interpreted as
   current-Space visibility. **Resolved** by keeping Space visibility outside
   `WindowVerificationResult`; reveal/focus is explicitly best-effort.
4. **Missing AX element vs. fallback move:** Existing fallback can resolve by
   frame, conflicting with exact-target correctness. **Resolved** by the P0 rule
   that `element == nil` is unverifiable and must not be moved.
5. **Final focus vs. sequential restore:** Per-app reveal would cause focus
   churn. **Resolved** by deferring reveal/focus until all placements complete
   and selecting the lowest-order verified target.

No unresolved logic contradiction, unreachable terminal state, or state-machine
deadlock remains. The `Aborted` and `Empty` pass states terminate explicitly;
every per-placement terminal state returns to the pass loop.

## 2. Risk register

| ID | Risk | Prob. | Impact | Mitigation / acceptance |
|---|---|---:|---:|---|
| RISK-WRV-001 | Additional AX reads may increase WindowServer IPC cost during a large restore. | Med | Med | Keep the pass sequential; cap attempts at 3; poll only fullscreen at 100ms; test representative multi-window workspaces. |
| RISK-WRV-002 | Existing `PresetResolver` and UI/test consumers may break when `RestoreSummary` gains counters/reason collections. | High | High | Treat summary as an additive coordinated contract; update all in-repo constructors/consumers and compile/test every target. |
| RISK-WRV-003 | Adding `isFullScreen` to `AccessibilityService` requires every mock/conformer to implement it. | High | Med | Update production and test adapters together; keep the interface minimal and provide no guessing default. |
| RISK-WRV-004 | `AccessibilityError` may not expose enough information to classify recoverable vs. non-recoverable move failures. | Med | High | Preserve the original technical error in diagnostics; define an explicit classification seam in the restore implementation and default unknown errors to `.moveFailed`, not success. |
| RISK-WRV-005 | AX fullscreen attributes vary across macOS versions/apps, causing false negatives or timeout. | Med | High | Reuse existing multi-strategy classification; verify state after exit; record timeout explicitly; no frame write while state remains fullscreen. |
| RISK-WRV-006 | Existing `WindowManager.move` unminimizes/fullscreen-handles internally, creating duplicate preparation or ordering changes. | Med | Med | Centralize preparation policy in the restore flow and reduce the adapter to exact-element move semantics; add tests for one unminimize/one fullscreen gate. |
| RISK-WRV-007 | Some apps change frame asynchronously after AX write, producing transient mismatches and extra retries. | Med | Low | Use the specified 100/200ms bounded backoff; classify only final mismatch as unverifiable and log attempt phases. |
| RISK-WRV-008 | Users see more failures than before because false positives are corrected. | High | Med | Preserve non-blocking `RestoreSummaryBanner` and auto-dismiss; show clear grouped counts/reasons; document accuracy correction. |
| RISK-WRV-009 | Final reveal/activation may switch Spaces or be refused by macOS. | Med | Med | Perform at most one best-effort action; never use its return value to change placement result; do not claim current-Space proof. |
| RISK-WRV-010 | Logging bundle IDs and technical errors could leak more than intended if call sites add titles. | Low | Med | Restrict logging rule to bundle ID/phase/reason/attempt/error code; review logs and tests for absence of title/content/screenshot fields. |
| RISK-WRV-011 | Existing summary serialization or equality assumptions may silently omit new issue categories. | Low | Med | Summary remains in-memory; add explicit equality/counter tests and update banner/preset consumers in the same change. |
| RISK-WRV-012 | Cross-Space spike could expand into unsupported private API work. | Med | High | Keep it exploratory and non-blocking; reuse US-WORK-013 only where public APIs are proven; no second Space manager in P0. |

## 3. Assumptions & constraints (consolidated)

- **ASM-WRV-001:** Placement success requires verified frame plus minimized/fullscreen state; AX write success is insufficient.
- **ASM-WRV-002:** Execution is manual restore only, with reusable core/service seams for future callers.
- **ASM-WRV-003:** Cross-Space is exploratory and not a P0 acceptance gate.
- **ASM-WRV-004:** Three total attempts with 100ms/200ms backoff cover recoverable move errors and verification mismatches.
- **ASM-WRV-005:** Fullscreen exit is synchronous, polled every ~100ms for ≤2s, and gates placement; throw/timeout prevents `setFrame`.
- **ASM-WRV-006:** Placements run sequentially by ascending `orderIndex`; no per-app activation/reveal; one final verified focus.
- **ASM-WRV-007:** Summary has separate placed/failed/unverifiable/skipped counts and typed reasons.
- **ASM-WRV-008:** Missing AX element is `.unverifiablePlacement`; no resolve-by-frame fallback.
- **ASM-WRV-009:** Picker `appLocalizedName` is a follow-up outside P0.
- **ASM-WRV-010:** Existing localization and accessibility conventions are preserved.
- **Constraints:** Swift 6 strict concurrency; macOS 14+; public AX/AppKit APIs only; no persisted workspace schema migration; no P0 cancel control; no title/content/screenshot logging; reuse existing logger and summary banner; signed-off baseline remains immutable.

## 4. MoSCoW scope lock

### Must-have (P0)

- Exact-element restore with safe optional handling.
- Frame/minimized/fullscreen post-condition verification with named tolerance.
- Three-attempt retry for recoverable move errors and verification mismatches.
- Fullscreen polling gate and explicit timeout reason.
- Typed `MoveOutcome`/placement results and summary counters/reasons.
- Sequential ordering and one final verified reveal/focus.
- Existing banner update with grouped feedback and auto-dismiss.
- Privacy-safe local diagnostics and regression/unit tests for deterministic restore.

### Should-have (P1)

- Small Cross-Space capability spike documenting reuse/adapter decision for
  US-WORK-013, without changing P0 behavior.

### Could-have (P2)

- Resolve-by-frame fallback, only after a separate safety proof and tests.
- Cancelable restore/progress flow.

### Won't-have (out of scope)

- `appLocalizedName` picker UX (separate follow-up).
- Hotkey, preset, or window-group flow changes beyond reusing the core seam.
- A new or private-API Space manager; current-Space visibility proof.
- P0 cancellation, new modal summary UI, or localization-system redesign.
- Persisting restore outcomes or adding workspace JSON migration.

## 5. Quality gate result

All findings are resolved or explicitly bounded above. No Critical unresolved risk
blocks specification; proceed to `spec-writer`.
