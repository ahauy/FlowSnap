# Test Plan: Quake-Style Quick Scratchpad & Instant Window Toggle (US-SNAP-022)

**Feature slug**: `quake-scratchpad-instant-toggle`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: Subagent `backend-developer` — Stage TDD (before implementation)  
**Traces to**: `.specify/features/quake-scratchpad-instant-toggle/05-user-stories.md` & `spec.md`

---

## Unit Tests

### `ScratchpadCoordinator`

#### TC-SCRATCH-001: Assign Focused Window as Scratchpad

```gherkin
Given Window A (ID: 201, PID: 500, App: "iTerm2") is focused
When  assignFocusedWindow() is called
Then  it returns true
  And state becomes .visible(record) with windowID == 201 and appName == "iTerm2"
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-001`, `BR-SCRATCH-001`, `US-SCRATCH-001` Scenario 1.1

#### TC-SCRATCH-002: Re-assigning Replaces Prior Scratchpad

```gherkin
Given Scratchpad is currently assigned to Window A (ID: 201, "iTerm2")
When  Window B (ID: 202, PID: 600, App: "Calculator") is focused and assignFocusedWindow() is called
Then  state becomes .visible(record) with windowID == 202 and appName == "Calculator"
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-001`, `BR-SCRATCH-001`, `US-SCRATCH-001` Scenario 1.2

#### TC-SCRATCH-003: Detach Scratchpad

```gherkin
Given Scratchpad is assigned to Window A
When  detachScratchpad() is called
Then  state becomes .unassigned
  And currentRecord is nil
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-001`, `BR-SCRATCH-001`, `US-SCRATCH-001` Scenario 1.3

#### TC-SCRATCH-004: Instant Summon (< 50ms) Caches PreSummonFocus and Activates

```gherkin
Given Scratchpad is hidden (.hidden(record))
  And current frontmost app is Brave (PID: 700, Window: 101)
When  toggleScratchpad() or summonScratchpad() is called
Then  preSummonFocus is cached with PID: 700
  And accessibilityService.raise is called for the scratchpad window
  And state becomes .visible(record)
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-002`, `BR-SCRATCH-002`, `US-SCRATCH-002` Scenario 2.1

#### TC-SCRATCH-005: Hybrid Dismiss for Single-Window Application

```gherkin
Given Scratchpad app (iTerm2, PID: 500) has exactly 1 window
  And state is .visible(record)
When  toggleScratchpad() or dismissScratchpad() is called
Then  appHider is requested to hide PID: 500
  And state becomes .hidden(record)
  And focus is restored to preSummonFocus app
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-003`, `BR-SCRATCH-003`, `ASM-SCRATCH-001`, `US-SCRATCH-003` Scenario 3.1

#### TC-SCRATCH-006: Hybrid Dismiss for Multi-Window Application

```gherkin
Given Scratchpad app (Terminal, PID: 500) has 2 or more windows open
  And state is .visible(record)
When  dismissScratchpad() is called
Then  appHider is NOT called to hide PID: 500 (prevents hiding other windows)
  And preSummonFocus app is activated
  And state becomes .hidden(record)
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-003`, `BR-SCRATCH-003`, `ASM-SCRATCH-001`, `US-SCRATCH-003` Scenario 3.1

#### TC-SCRATCH-007: Pre-Summon Focus Restoration

```gherkin
Given preSummonFocus was saved as PID: 700 (Brave, Window: 101)
When  dismissScratchpad() completes
Then  Brave (PID: 700) is reactivated and raised via accessibilityService
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-004`, `BR-SCRATCH-004`, `US-SCRATCH-003` Scenario 3.1

#### TC-SCRATCH-008: Safe Fallback when Pre-Summon Process Terminated

```gherkin
Given preSummonFocus was saved as PID: 999
  And PID: 999 has terminated before dismiss
When  dismissScratchpad() is called
Then  it does not crash or throw unhandled errors
  And state becomes .hidden(record)
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-004`, `RISK-SCRATCH-002`

#### TC-SCRATCH-009: ESC Key Dismiss

```gherkin
Given Scratchpad is .visible(record) and dismissOnEsc == true
When  handleEscKey() is triggered
Then  dismissScratchpad() is executed
  And state becomes .hidden(record)
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-005`, `BR-SCRATCH-005`, `US-SCRATCH-003` Scenario 3.2

#### TC-SCRATCH-010: Dismiss on Blur (Outside Click)

```gherkin
Given Scratchpad is .visible(record) and dismissOnBlur == true
When  handleClickOutside(clickPoint: (50, 50)) is triggered (outside scratchpad bounds)
Then  dismissScratchpad() is executed
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-005`, `BR-SCRATCH-005`, `ASM-SCRATCH-002`, `US-SCRATCH-003` Scenario 3.3

#### TC-SCRATCH-011: Safe Lifecycle Detach on App Termination

```gherkin
Given Scratchpad is assigned to PID: 500
When  didTerminateApplication notification is received for PID: 500
Then  state automatically transitions to .unassigned
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-006`, `BR-SCRATCH-006`, `ASM-SCRATCH-003`, `US-SCRATCH-004` Scenario 4.1

#### TC-SCRATCH-012: Dead Window UIElement Auto-Purge

```gherkin
Given Scratchpad is assigned to Window A
When  accessibilityService.raise returns false (invalid UI element) during summon
Then  state transitions to .unassigned
```

**File**: `FlowSnapTests/Core/Scratchpad/ScratchpadCoordinatorTests.swift`  
**Traces to**: `REQ-SCRATCH-006`, `BR-SCRATCH-006`, `US-SCRATCH-004` Scenario 4.2
