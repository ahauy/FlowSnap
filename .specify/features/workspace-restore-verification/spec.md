# Feature Specification: Verified Workspace Restoration

**Feature Branch**: `workspace-restore-verification`  
**Created**: 2026-09-02  
**Status**: Draft  
**Input**: User-approved enhancement proposal `US-WORK-011_Giai_phap_hoan_chinh_v2.md`

## User Scenarios & Testing

### User Story 1 - Trustworthy placement (Priority: P1)

As a FlowSnap user, I want restore to report success only after the window's
actual geometry and state match the target, so false-positive restores disappear.

**Why this priority**: This is the primary P0 correctness defect.

**Independent Test**: Script a target that accepts a frame write but returns an
old frame, and verify bounded retries plus an explicit non-success result.

**Acceptance Scenarios**:

1. Given an exact target and matching frame/state, when restore completes, then
   the placement is counted as placed.
2. Given a successful write with an unchanged frame, when verification runs,
   then restore retries at most three times and never reports placed without a
   matching read-back.
3. Given an unreadable frame or missing exact AX target, when restore prepares
   the placement, then it records unverifiable and performs no unsafe fallback.

### User Story 2 - Deterministic fullscreen preparation (Priority: P1)

As a FlowSnap user, I want fullscreen windows to exit fullscreen before moving,
so frame writes are not lost during the transition.

**Why this priority**: Fullscreen is the second P0 correctness failure mode.

**Independent Test**: Script fullscreen state transitions and verify polling,
timeout, and zero `setFrame` calls on failure.

**Acceptance Scenarios**:

1. Given fullscreen exit is confirmed within two seconds, when preparation ends,
   then placement may begin.
2. Given fullscreen exit throws or remains true through the timeout, when restore
   handles preparation, then no placement is attempted and the reason is
   `fullscreenTransitionTimeout`.

### User Story 3 - Accurate partial summary (Priority: P1)

As a FlowSnap user, I want to see whether a window failed, was unverifiable, or
was skipped before placement, so I can understand partial restore results.

**Why this priority**: Honest feedback is necessary once false positives stop
   being counted as success.

**Independent Test**: Run a mixed pass and inspect counters, issue groups, and
   the existing banner without opening a modal.

**Acceptance Scenarios**:

1. Given mixed placed, failed, unverifiable, and skipped outcomes, when the pass
   completes, then counters sum to the total and the banner groups reasons.
2. Given a move error after allowed retries, when the pass completes, then the
   item is `moveFailed`, not `noWindow`.
3. Given an absent app, launch timeout, or no eligible window, when resolution
   ends, then the matching discovery reason increments skipped count.
4. Given partial failures, when the banner appears, then it remains non-blocking
   and uses the existing auto-dismiss timeout.

### User Story 4 - Stable ordering and focus (Priority: P1)

As a FlowSnap user, I want restore to avoid application focus churn, so one
deterministic window is active at the end.

**Why this priority**: Focus churn obscures which placements actually completed.

**Independent Test**: Provide placements in non-sorted input order and observe
   call order plus the single final focus target.

**Acceptance Scenarios**:

1. Given placements with different order indexes, when restore runs, then it
   processes them sequentially in ascending order without per-app activation.
2. Given multiple verified placements, when the pass ends, then only the lowest
   order index is revealed/focused once.
3. Given no verified placement, when the pass ends, then no reveal/focus is
   forced.

### User Story 5 - Safe visibility and diagnostics (Priority: P2)

As a FlowSnap maintainer, I want visibility claims and diagnostics bounded by
publicly provable state, so Space behavior is not overstated and user content is
not logged.

**Why this priority**: It protects trust and privacy while Cross-Space remains a
   separate exploration.

**Independent Test**: Run a cross-Space-like fixture and inspect verification and
   diagnostic fields.

**Acceptance Scenarios**:

1. Given geometry matches while Space membership is unknown, when verification
   completes, then no current-Space visibility claim is emitted.
2. Given restore phases emit diagnostics, when logs are inspected, then they
   contain only bundle ID, phase, reason, attempt, and technical error/code.
3. Given a restore pass is already running, when restore is triggered again,
   then the existing in-flight guard prevents a concurrent pass.

### Edge Cases

- A silent frame write is retried and ends as `unverifiablePlacement` if it never
  matches.
- `frame(of:) == nil` is never success.
- A frame match with minimized or fullscreen state remains non-success.
- Fullscreen throw/timeout prevents any `setFrame` call.
- A missing AX element never invokes resolve-by-frame guessing.
- One placement failure does not abort later placements.
- AX geometry may verify placement but never proves current-Space visibility.
- A second restore trigger while one is active is ignored by the existing guard.
- App-name picker changes, cancellation, and full Cross-Space integration are
  explicitly deferred.

## Requirements

### Functional Requirements

- **FR-001**: System MUST verify actual frame, minimized state, and fullscreen
  state after every placement attempt before counting a placement as placed.
- **FR-002**: System MUST use named policy values for 30-point frame tolerance,
  three total attempts, 100/200ms retry backoff, and 2s fullscreen timeout with
  100ms polling.
- **FR-003**: System MUST retry recoverable move errors and verification
  mismatches within the bounded attempt budget and stop on non-recoverable
  conditions.
- **FR-004**: System MUST refuse to move a placement whose exact AX element is
  unavailable and MUST report it as unverifiable.
- **FR-005**: System MUST complete fullscreen exit verification before any frame
  write and MUST report a timeout/throw explicitly without moving.
- **FR-006**: System MUST expose fullscreen state through the existing
  accessibility seam using public APIs and update all conformers.
- **FR-007**: System MUST return typed per-placement outcomes and summary
  counters for placed, failed, unverifiable, and skipped categories.
- **FR-008**: System MUST preserve distinct reasons `moveFailed`,
  `unverifiablePlacement`, `fullscreenTransitionTimeout`, `notInstalled`,
  `launchTimeout`, and `noWindow`.
- **FR-009**: System MUST process placements sequentially by ascending order
  index, continue after placement-level failures, and perform at most one final
  reveal/focus for the lowest-order verified result.
- **FR-010**: System MUST keep current-Space visibility separate from placement
  verification and MUST NOT use geometry as Space proof.
- **FR-011**: System MUST reuse the existing non-blocking summary banner,
  grouped reasons, auto-dismiss timeout, localization, and accessibility
  conventions.
- **FR-012**: System MUST limit diagnostics to bundle ID, phase, reason, attempt,
  and technical error/code; window title/content, UI text, screenshots, and user
  data MUST NOT be logged.
- **FR-013**: System MUST preserve existing workspace JSON compatibility and
  keep Cross-Space spike, picker app name, resolve-by-frame fallback, and cancel
  outside P0.

### Key Entities

- **RestorePlacementResult**: Immutable outcome for one placement, including
  order, category, and typed reason.
- **WindowVerificationResult**: Read-back frame/minimized/fullscreen predicates.
- **RestoreSummary**: Ephemeral aggregate counts and separate issue groups.
- **RestoreVerificationPolicy**: Fixed P0 tolerance, retry, and polling budgets.
- **Workspace / WindowPlacement**: Existing durable intent data, unchanged by P0.

## Success Criteria

### Measurable Outcomes

- **SC-001**: 100% of scripted silent-write, unreadable-frame, minimized-state,
  and fullscreen-timeout cases are not counted as placed.
- **SC-002**: Every placement completes within three attempts and no more than
  300ms retry backoff, excluding the existing app-launch budget.
- **SC-003**: 100% of mixed-result restore passes satisfy the summary counter
  conservation rule and expose a specific reason for each non-placed item.
- **SC-004**: A restore pass emits at most one final reveal/focus action and emits
  none when no placement is verified.
- **SC-005**: Existing workspace/preset/banner/accessibility regression suites
  remain green after all interface consumers and mocks are updated.
- **SC-006**: Diagnostic review finds zero window titles, content, screenshots,
  or user text in restore logs.

## Assumptions

- The local macOS user has Accessibility permission when a restore pass begins.
- Existing `WorkspaceStore` JSON and manual Menu Bar/Settings entry points remain
  the durable/data and UX seams.
- `AccessibilityService` and `ApplicationLaunching` remain dependency-injected
  and testable; no new private API or external dependency is introduced.
- The existing summary banner's auto-dismiss timeout, localization baseline, and
  accessibility behavior are preserved.
- Cross-Space capability is investigated only as a non-blocking follow-up.
- Cancelable restore, picker app names, and resolve-by-frame fallback are future
  scope and do not alter P0 acceptance.
