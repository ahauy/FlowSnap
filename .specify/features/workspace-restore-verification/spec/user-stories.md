# User Stories: Verified Workspace Restoration Enhancement

## US-WRV-001: Trustworthy placement results

**As a** FlowSnap macOS user  
**I want to** know that a restored window was actually placed  
**So that** restore reports never claim success based only on an AX API return value  
**Traces to:** REQ-WRV-001, REQ-WRV-002, REQ-WRV-003, REQ-WRV-004

### Acceptance criteria

- **Scenario 1 (happy path)**
  - Given an exact AX element and a target frame
  - When `setFrame` succeeds and the read-back frame is within 30 points, minimized is false, and fullscreen is false
  - Then the placement is `placed` and increments `placedCount`.
- **Scenario 2 (silent AX ignore)**
  - Given `setFrame` returns success but the actual frame remains old
  - When verification detects a mismatch
  - Then the core retries within the three-attempt budget and never counts the placement as placed unless a later verification passes.
- **Scenario 3 (unreadable frame)**
  - Given `frame(of:)` returns nil
  - When the allowed attempts are exhausted
  - Then the result is `unverifiablePlacement` and `unverifiableCount` increments.
- **Scenario 4 (missing AX element)**
  - Given `resolved.element == nil`
  - When restore prepares the placement
  - Then it makes no move call and records `unverifiablePlacement`.
- **Scenario 5 (minimized after move)**
  - Given the frame matches but minimized remains true
  - When verification runs
  - Then the attempt is not placed, retries while recoverable, and a final mismatch is recorded as `unverifiablePlacement`.

## US-WRV-002: Deterministic fullscreen preparation

**As a** FlowSnap macOS user  
**I want to** restore fullscreen windows only after they truly exit fullscreen  
**So that** frame writes are not silently ignored during a transition  
**Traces to:** REQ-WRV-005, REQ-WRV-006

### Acceptance criteria

- **Scenario 1 (exit confirmed)**
  - Given the target is fullscreen and `exitFullScreen` returns
  - When polling observes `isFullScreen == false` within 2 seconds
  - Then placement may begin and no fixed 700ms sleep is used as proof.
- **Scenario 2 (exit throws)**
  - Given `exitFullScreen` throws
  - When preparation handles the error
  - Then no `setFrame` call occurs and the reason is `fullscreenTransitionTimeout`.
- **Scenario 3 (timeout)**
  - Given fullscreen remains true throughout the 2-second polling budget
  - When the timeout expires
  - Then no placement attempt occurs and the summary records `fullscreenTransitionTimeout`.

## US-WRV-003: Accurate partial-restore summary

**As a** FlowSnap macOS user  
**I want to** see why each placement did not complete  
**So that** I can distinguish move errors, unverifiable state, and discovery skips  
**Traces to:** REQ-WRV-007, REQ-WRV-008, REQ-WRV-010, REQ-WRV-011

### Acceptance criteria

- **Scenario 1 (mixed outcomes)**
  - Given a pass with placed, failed, unverifiable, and skipped placements
  - When the pass completes
  - Then counters sum to total placements and the banner groups each issue category with its reason.
- **Scenario 2 (move error)**
  - Given move throws on all recoverable attempts
  - When the final attempt fails
  - Then the result is `moveFailed`, increments `failedCount`, and is not represented as `noWindow`.
- **Scenario 3 (discovery skip)**
  - Given an app is not installed, launch times out, or no eligible window appears
  - When resolution ends
  - Then the corresponding `notInstalled`, `launchTimeout`, or `noWindow` reason increments `skippedCount` and no placement attempt is made.
- **Scenario 4 (non-blocking UX)**
  - Given partial failures
  - When the summary is shown
  - Then `RestoreSummaryBanner` remains non-modal and auto-dismisses using its existing timeout.

## US-WRV-004: Stable ordering and final focus

**As a** FlowSnap macOS user  
**I want to** avoid application focus churn during restore  
**So that** the final active window is deterministic  
**Traces to:** REQ-WRV-008, REQ-WRV-009

### Acceptance criteria

- **Scenario 1 (ordered pass)**
  - Given placements with arbitrary input order and distinct `orderIndex` values
  - When restore runs
  - Then placements execute sequentially in ascending `orderIndex` without per-app activation/reveal.
- **Scenario 2 (lowest verified focus)**
  - Given order indexes 0 and 1 are verified and index 2 fails
  - When all placements complete
  - Then only index 0 receives final best-effort reveal/focus.
- **Scenario 3 (lowest fails)**
  - Given index 0 fails and index 1 verifies
  - When all placements complete
  - Then only index 1 receives final best-effort reveal/focus.
- **Scenario 4 (none verified)**
  - Given every placement fails, is unverifiable, or is skipped
  - When the pass completes
  - Then no reveal/focus is forced.

## US-WRV-005: Honest visibility and safe diagnostics

**As a** FlowSnap maintainer  
**I want to** keep Space visibility and diagnostics bounded by what public APIs prove  
**So that** restore does not overclaim or expose user content  
**Traces to:** REQ-WRV-001, REQ-WRV-009, REQ-WRV-011, REQ-WRV-012

### Acceptance criteria

- **Scenario 1 (cross-Space geometry)**
  - Given an AX frame matches while the window may be on another Space
  - When verification completes
  - Then the placement may be verified geometrically but no current-Space visibility claim is emitted.
- **Scenario 2 (privacy-safe log)**
  - Given resolve, prepare, place, verify, and final-focus events
  - When diagnostics are emitted
  - Then logs contain only allowed bundle ID/phase/reason/attempt/technical error fields and never title/content/screenshots.
- **Scenario 3 (repeat click)**
  - Given a restore pass is already running
  - When the user triggers restore again
  - Then the existing in-flight guard prevents a concurrent pass; no cancel flow is introduced.
