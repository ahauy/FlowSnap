# Elicitation Record: Verified Workspace Restoration Enhancement (US-WORK-011)

## Stage 1 — Business Value

- **Problem / pain:** Restore can report success when `setFrame` returned success but the window did not actually move. Fullscreen transitions are also timing-sensitive, and visibility/focus behavior can be confused with placement correctness.
- **Priority order:** (1) truthful, post-condition-verified placement; (2) deterministic fullscreen preparation; (3) separate best-effort visibility/focus.
- **Personas:** macOS FlowSnap users manually restoring workspaces from Menu Bar or Settings.
- **Execution scope:** Manual restore only for this task.
- **Architectural scope:** Core/service logic must be reusable by future hotkey, preset, and window-group flows, but those flows are not implemented here.
- **Success definition:** A window is reported as successfully restored only when actual frame, minimized state, and fullscreen state satisfy verification rules. Partial failures are explicit in `RestoreSummary`.
- **P0 boundary:** Complete deterministic restore tests and behavior. Cross-Space is exploratory/spike work only and is not a P0 blocker.

## Confirmed decisions

### ASM-WRV-001 — Verification is required for placement success

`setFrame` API success alone never yields a placed result. Placement requires post-condition verification of actual frame plus minimized/fullscreen state.

### ASM-WRV-002 — Manual execution with reusable core seam

Only Menu Bar/Settings manual restore is in scope. Verification, preparation, retry, and result mapping belong in reusable core/service layers.

### ASM-WRV-003 — Cross-Space is not a P0 acceptance gate

AX frame must not be treated as proof of current-Space visibility. Cross-Space capability may be investigated and existing US-WORK-013 infrastructure may be assessed, but no speculative Space API is required for P0.

### ASM-WRV-004 — Bounded retry is verification-driven

Each placement has at most three total attempts. Both `setFrame` errors and post-condition mismatches retry with 100ms then 200ms backoff. Verification remains the source of truth; non-recoverable conditions are not blindly retried.

### ASM-WRV-005 — Fullscreen is a preparation gate

For a fullscreen target, call synchronous throwing `exitFullScreen`, poll every 100ms for at most 2 seconds, and only then attempt placement. A thrown exit or timeout skips placement with `fullscreenTransitionTimeout` (or an explicitly distinct equivalent) and does not call `setFrame`.

### ASM-WRV-006 — Sequential placement and one final focus

Process placements sequentially in ascending `orderIndex` without per-app activation/reveal. After all placements, reveal/focus exactly one verified placement: the lowest `orderIndex`; if none verify, do not force focus/reveal a failed target. Reveal/focus is never placement proof.

### ASM-WRV-007 — Typed outcome categories and truthful counters

`RestoreSummary` exposes `placedCount`, `failedCount`, `unverifiableCount`, and `skippedCount`. P0 reasons include `.moveFailed`, `.unverifiablePlacement`, `.fullscreenTransitionTimeout`, `.notInstalled`, `.launchTimeout`, and `.noWindow`. `skipped` is not a catch-all for placement failures.

### ASM-WRV-008 — Missing AX element is unverifiable

When `resolved.element == nil`, P0 must not call `setFrame` or use resolve-by-frame guessing. The result is `.unverifiablePlacement`.

### ASM-WRV-009 — Picker app name is deferred

`appLocalizedName` and picker presentation are a separate UX follow-up, outside this P0 enhancement.

## Pillar 2 — State Machine & Lifecycle (confirmed)

Per placement: `resolved → preparing → placing/verification (up to 3 attempts) → placed | failed | unverifiable | skipped`. Fullscreen timeout terminates before placing. Restore pass completes after all placements and optionally enters one final-focus step, then returns to its idle/persisted workspace state.

## Pillar 3 — Business Rules (confirmed)

- Frame tolerance is a named policy constant, not a literal in orchestration.
- `frame == nil` is never success; it yields `unverifiable` after the allowed attempts.
- A frame match is insufficient when the target remains minimized or fullscreen.
- Display intersection is diagnostic/safety information only, never current-Space proof.
- Every unsuccessful placement has an explicit summary reason.

## Pillar 4 — Workflows & Edge Cases (confirmed)

- Placement attempts are sequential and bounded; a non-recoverable boundary condition must terminate the placement without blind retries.
- Fullscreen timeout is a pre-placement skip/failure and must not invoke `setFrame`.
- A restore pass continues after per-placement failures and performs final focus only when at least one placement is verified.
- Cross-Space behavior remains best-effort/exploratory; no current-Space proof is claimed from geometry.

## Pillar 5 — Entities, Data Boundaries & Privacy (open)

No new persisted workspace schema is intended for P0. Local diagnostics may log `bundleID`, phase, reason, attempt, and technical error/code. Window titles, content, UI text, screenshots, and user data are never logged; bundle IDs do not need masking. Reuse an existing logging abstraction if present; do not add a parallel logger.

## Pillar 6 — UX & Non-Functional Requirements (confirmed)

- Reuse `RestoreSummaryBanner`; do not create a new summary UI.
- Show placed, failed, unverifiable, and skipped groups with their reasons when details are expanded.
- Preserve the existing auto-dismiss timeout, including partial failures; no blocking modal.
- Preserve fullscreen timeout (~2s), 100ms polling, three attempts with 100/200ms backoff, sequential `orderIndex` processing, and no per-app activation.
- Cancel/progress cancellation is explicitly deferred to a follow-up.

### ASM-WRV-010 — Preserve existing localization and accessibility baseline

P0 keeps FlowSnap's current localization and accessibility conventions. The existing banner remains the only UI surface; no new multilingual system or standalone accessibility audit is introduced, but updated content must not regress VoiceOver, keyboard navigation, contrast, or existing sizing behavior.

## Decision summary for downstream stages

P0 delivers a reusable, deterministic restore core for manual Menu Bar/Settings restore. A placement is `placed` only after verified frame/minimized/fullscreen post-conditions. Missing AX elements are `.unverifiablePlacement` with no move attempt. Both move errors and verification mismatches retry up to three total attempts with bounded backoff, except non-recoverable conditions. Fullscreen exit is a synchronous pre-placement gate with 2s polling; timeout/throw prevents `setFrame`. Results expose typed counters and reasons; one final best-effort reveal/focus targets the lowest-order verified placement. Cross-Space is exploratory only; picker app names and cancellation are follow-ups. Existing localization and accessibility behavior is preserved.

## Open questions

- Exact failure-reason mapping and summary counting — blocking for domain modeling/spec.
- Data/privacy/observability constraints — blocking for domain modeling/spec.
- UX/NFR behavior for partial restore and final focus — blocking for domain modeling/spec.
