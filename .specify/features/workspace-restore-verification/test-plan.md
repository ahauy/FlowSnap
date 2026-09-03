# Test Plan: Verified Workspace Restoration

**Feature slug**: `workspace-restore-verification`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI — Stage TDD (before implementation)  
**Traces to**: [`spec/user-stories.md`](spec/user-stories.md)

> This plan defines Gherkin cases before implementation. Swift Testing/XCTest
> files are written from these cases after the red test phase begins.

## Unit and integration tests

### Placement verification

#### TC-WRV-001: Matching frame and state is placed

```gherkin
Given an exact AX element and a target frame
When setFrame succeeds and read-back frame/state match within policy
Then the outcome is placed and placedCount increments
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-001` Scenario 1

#### TC-WRV-002: Silent frame write is retried

```gherkin
Given setFrame returns success but read-back remains the old frame
When verification runs
Then attempts occur at most three times with 100ms then 200ms backoff
And placedCount does not increment unless a later read-back matches
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-001` Scenario 2

#### TC-WRV-003: Unreadable frame is unverifiable

```gherkin
Given frame(of:) returns nil for every attempt
When the attempt budget is exhausted
Then the outcome is unverifiablePlacement
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-001` Scenario 3

#### TC-WRV-004: Missing AX element is not moved

```gherkin
Given resolved.element is nil
When restore prepares the placement
Then setFrame is never called
And the outcome is unverifiablePlacement
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-001` Scenario 3

#### TC-WRV-005: Minimized state prevents placement success

```gherkin
Given the frame matches but the window remains minimized
When verification runs
Then the attempt is not placed and the final mismatch is unverifiablePlacement
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-001` Scenario 4

#### TC-WRV-006: Move error is retried and classified

```gherkin
Given move throws a recoverable error for every attempt
When restore reaches the final attempt
Then the outcome is moveFailed and failedCount increments
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-003` Scenario 2

### Fullscreen preparation

#### TC-WRV-007: Fullscreen exit is polled before move

```gherkin
Given a target is fullscreen and exitFullScreen returns
When polling observes false within two seconds
Then setFrame is called only after the false observation
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-002` Scenario 1

#### TC-WRV-008: Fullscreen exit throw prevents move

```gherkin
Given exitFullScreen throws
When preparation handles the error
Then setFrame is not called and fullscreenTransitionTimeout is recorded
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-002` Scenario 2

#### TC-WRV-009: Fullscreen timeout prevents move

```gherkin
Given isFullScreen remains true for the two-second budget
When polling times out
Then setFrame is not called and fullscreenTransitionTimeout is recorded
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceFullscreenRestoreTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-002` Scenario 2

### Summary and orchestration

#### TC-WRV-010: Counters conserve total placements

```gherkin
Given a pass with placed, failed, unverifiable, and skipped outcomes
When the pass completes
Then the four counters sum to totalPlacements
And each issue appears in its category collection
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-003` Scenario 1

#### TC-WRV-011: Discovery failures remain skipped

```gherkin
Given an app is not installed, launch times out, or has no eligible window
When resolution ends
Then the matching reason increments skippedCount
And no placement attempt occurs
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceManagerRestoreTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-003` Scenario 3

#### TC-WRV-012: Partial summary uses existing banner

```gherkin
Given a summary contains partial failures
When the banner is rendered
Then grouped reasons are visible without a modal
And the existing auto-dismiss behavior remains
```

**File**: `FlowSnapTests/UI/PresetAndGroupViewTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-003` Scenario 4

### Ordering and final focus

#### TC-WRV-013: Placements run in orderIndex order

```gherkin
Given input placements are not sorted
When restore runs
Then calls occur sequentially in ascending orderIndex
And no per-app reveal/activation occurs
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-004` Scenario 1

#### TC-WRV-014: Lowest verified placement receives final focus

```gherkin
Given multiple placements verify successfully
When all placements complete
Then only the lowest orderIndex receives one reveal/focus action
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-004` Scenario 2

#### TC-WRV-015: No verified placement receives no focus

```gherkin
Given every placement fails, is unverifiable, or is skipped
When the pass completes
Then no reveal/focus action occurs
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreVerificationTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-004` Scenario 3

### Visibility, privacy, and concurrency

#### TC-WRV-016: Geometry does not claim current-Space visibility

```gherkin
Given an AX frame matches while Space membership is unknown
When verification completes
Then no current-Space visibility proof is emitted
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceSpaceVisibilityTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-005` Scenario 1

#### TC-WRV-017: Diagnostics exclude user content

```gherkin
Given restore emits phase diagnostics
When the captured log fields are inspected
Then only bundle ID, phase, reason, attempt, and technical error/code appear
And no title, content, UI text, or screenshot appears
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreLoggingTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-005` Scenario 2

#### TC-WRV-018: Concurrent restore trigger is guarded

```gherkin
Given a restore pass is already running
When restore is triggered again
Then the existing in-flight guard prevents a concurrent pass
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceRestoreConcurrencyTests.swift`  
**Priority**: Must-Have  
**Traces to**: `US-WRV-005` Scenario 3

#### TC-WRV-019: Existing regression suites remain green

```gherkin
Given all existing workspace, preset, AX, and banner tests
When the full test suite runs
Then no pre-existing behavior regresses
```

**File**: `FlowSnapTests`  
**Priority**: Must-Have  
**Traces to**: `SC-005`

## Test Coverage Checklist

- [x] Every US-WRV happy-path scenario has a TC.
- [x] Every US-WRV edge scenario has a TC.
- [x] Error states, idempotency, and concurrency are covered where applicable.
- [x] No database/API contract tests are applicable to this local macOS feature.
- [x] Focused P0 test files are implemented; execution is currently blocked by
  the environment's malformed Xcode ObservationMacros plugin response.
