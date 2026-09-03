# Feature: Verified Workspace Restoration (US-WORK-011)

- **Feature slug:** `workspace-restore-verification`
- **Scope:** P0 manual restore from Menu Bar and Settings
- **Status:** Implemented; source review passed. Final build verification is environment-blocked by Xcode's `ObservationMacros` plugin

## Purpose

Restore reports a window as placed only after reading back its actual AX frame
and state. Placement is separate from best-effort visibility and focus, so a
successful geometry proof is never inferred from activation or current Space
visibility.

## Behavior

- Placements run serially in ascending `orderIndex`.
- A missing AX element is `unverifiablePlacement`; no fallback move is attempted.
- Full-screen windows must exit synchronously and be observed as non-full-screen
  within two seconds (100 ms polling) before any frame write.
- Frame writes and verification mismatches retry at most three total attempts,
  with 100 ms then 200 ms backoff.
- Verification requires matching frame components within 30 points and confirms
  the window is neither minimized nor full-screen.
- After the pass, only the lowest-order verified placement receives one
  best-effort reveal/focus action.

## Result model

`RestoreSummary` exposes `placedCount`, `failedCount`, `unverifiableCount`, and
`skippedCount`, plus reasoned issue lists. Reasons include `moveFailed`,
`unverifiablePlacement`, `fullscreenTransitionTimeout`, `notInstalled`,
`launchTimeout`, and `noWindow`.

`RestoreSummaryBanner` reuses the existing non-modal, auto-dismissing banner and
groups placed, failed, unverifiable, and skipped outcomes with counters.

## Implementation map

| Area | Files |
| --- | --- |
| Policy and evidence | `FlowSnap/Core/Workspace/RestoreVerification.swift` |
| Sequential restore | `FlowSnap/Core/Workspace/WorkspaceManager+Restore.swift` |
| AX state operations | `FlowSnap/Infrastructure/Accessibility/AccessibilityService.swift`, `AXAccessibilityService.swift` |
| Typed summary | `FlowSnap/Domain/Workspace/RestoreSummary.swift` |
| Existing banner/consumers | `FlowSnap/UI/Components/RestoreSummaryBanner.swift`, `WorkspaceSettingsView.swift`, `WorkspaceViewModel.swift` |

## Validation

The feature test plan is at
`.specify/features/workspace-restore-verification/test-plan.md`. Focused tests
cover silent frame writes, minimized-state mismatch, exact AX element routing,
fullscreen handling, typed summary outcomes, and final focus ordering.

Cross-Space behavior remains a bounded capability spike; AX frame evidence does
not claim current-Space visibility.
