# Test Plan: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-018)

**Feature slug**: `universal-fullscreen-escape`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (Phase 5)
**Traces to**: `.specify/features/universal-fullscreen-escape/05-user-stories.md`

---

## Unit Tests

### `FullScreenEscapeCoordinator`

#### `TC-FSE-001`: Tier 0 Fast Attribute Write Success

```gherkin
Given a window in full screen mode where AXFullscreen attribute write succeeds
When  exitFullScreen is invoked
Then  the coordinator exits via Tier 0 (.attributeWrite)
And   neither Tier 1 (button press) nor Tier 2 (CGEvent keystroke) are invoked
And   execution completes in under 5ms
```

**File**: `FlowSnapTests/Infrastructure/FullScreenEscapeCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-WORK-018-01`

---

#### `TC-FSE-002`: Tier 1 AX Button Press on Electron / Chromium Apps

```gherkin
Given an Electron window where AXFullscreen attribute write fails with cannotComplete
And   the window possesses an accessible full screen / zoom button
When  exitFullScreen is invoked
Then  the coordinator cascades to Tier 1 (.axButtonPress)
And   the full screen button action (kAXPressAction) is triggered
And   CGEvent keystroke is NOT dispatched
```

**File**: `FlowSnapTests/Infrastructure/FullScreenEscapeCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-WORK-018-02`

---

#### `TC-FSE-003`: Tier 2 Fallback to Synthesized `⌃⌘F` Keystroke

```gherkin
Given a window where attribute write fails and no AX full screen button exists
When  exitFullScreen is invoked
Then  the coordinator cascades to Tier 2 (.cgEventShortcut)
And   the target application process PID is activated
And   a Control + Command + F keystroke is posted via CGEventPosting
```

**File**: `FlowSnapTests/Infrastructure/FullScreenEscapeCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-WORK-018-03`

---

#### `TC-FSE-004`: Adaptive Polling Loop Early Termination

```gherkin
Given an escape signal has been triggered
When  the window exits full screen at 200ms
Then  the adaptive polling loop terminates at 200ms instead of waiting for 800ms
And   returns FullScreenEscapeResult.succeeded == true
```

**File**: `FlowSnapTests/Infrastructure/FullScreenEscapeCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-WORK-018-04`

---

#### `TC-FSE-005`: Timeout Handling at 800ms Ceiling

```gherkin
Given an unresponsive window where the space exit animation stalls
When  the 800ms ceiling is reached
Then  the coordinator terminates the polling loop gracefully
And   returns without throwing an unhandled fatal exception
```

**File**: `FlowSnapTests/Infrastructure/FullScreenEscapeCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-WORK-018-05`

---

## Integration Tests

### `WindowManager.move`

#### `TC-FSE-006`: WindowManager Reposition with Fullscreen Escape

```gherkin
Given a window of kind .fullscreen
When  windowManager.move is invoked with a target frame
Then  windowManager delegates to FullScreenEscapeCoordinating
And   the window is repositioned to targetFrame after the full screen exit completes
```

**File**: `FlowSnapTests/Core/Window/WindowManagerTests.swift`
**Priority**: Must-Have
**Traces to**: `REQ-FSE-006`
