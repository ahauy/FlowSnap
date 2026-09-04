# Test Plan: Universal Always-On-Top Pinning & Stage Manager Launch Co-existence (US-SNAP-021)

**Feature slug**: `always-on-top-window-pinning`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (before implementation)
**Traces to**: `.specify/features/always-on-top-window-pinning/05-user-stories.md`

---

## Unit Tests

### `WindowPinningCoordinator`

#### TC-PIN-001: Toggle Pin on Unpinned Window

```gherkin
Given Window A (ID: 101, PID: 500) is unpinned
When  togglePin(window: Window A) is called
Then  it returns true (pinned)
  And Window A is at the top of pinnedWindows
  And accessibilityService.raise is called for Window A
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-001`, `BR-PIN-001`, `US-PIN-001` Scenario 1

#### TC-PIN-002: Toggle Pin on Already Pinned Window

```gherkin
Given Window A (ID: 101) is already pinned
When  togglePin(window: Window A) is called
Then  it returns false (unpinned)
  And Window A is removed from pinnedWindows
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-001`, `BR-PIN-001`, `US-PIN-001` Scenario 2

#### TC-PIN-003: Dynamic LIFO Z-Stacking across Multiple Pinned Windows

```gherkin
Given Window A (ID: 101) is pinned
When  Window B (ID: 102) is pinned
Then  pinnedWindows order is [Window B, Window A]
When  Window A receives focus
Then  pinnedWindows order updates to [Window A, Window B]
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-002`, `BR-PIN-002`, `US-PIN-001` Scenario 3

#### TC-PIN-004: Active Re-assertion Coordination on Unpinned Window Focus

```gherkin
Given Window A (ID: 101) and Window B (ID: 102) are pinned in order [Window B, Window A]
When  Window C (ID: 201, unpinned) receives focus
Then  handleFocusChange is called
  And Window A is raised first via kAXRaiseAction
  And Window B is raised second via kAXRaiseAction
  And no activate() call is made on Window A or Window B
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-003`, `BR-PIN-003`, `US-PIN-002` Scenario 1

#### TC-PIN-005: System Modal Safety & Exemption

```gherkin
Given Window A is pinned
When  active app bundle is "com.apple.SecurityAgent" or "com.apple.CoreAuthUI"
Then  re-assertion is suspended (zero raise calls made)
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-004`, `BR-PIN-004`, `US-PIN-002` Scenario 2

#### TC-PIN-006: Terminated Application Cleanup

```gherkin
Given Window A (PID: 500) and Window B (PID: 600) are pinned
When  application with PID: 500 terminates
Then  Window A is automatically purged from pinnedWindows
  And Window B remains pinned
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-007`, `BR-PIN-007`

#### TC-PIN-007: Dead Window UIElement Auto-Purge

```gherkin
Given Window A is pinned
When  accessibilityService.raise returns false (invalid UI element) during re-assertion
Then  Window A is purged from pinnedWindows
```

**File**: `FlowSnapTests/Core/Policy/WindowPinningCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-007`, `RISK-PIN-003`

---

### `StageManagerLaunchCoordinator`

#### TC-PIN-008: Stage Manager Launch Co-existence (Happy Path)

```gherkin
Given Stage Manager is enabled (isStageManagerEnabled == true)
  And stageManagerLaunchCoexistenceEnabled == true
  And current Stage has windows [Window X, Window Y]
When  application launch notification is received for App Z (PID: 700)
  And window creation for App Z is detected
Then  kAXRaiseAction is coordinated for Window X and Window Y
  And both previous windows stay on the active Stage
```

**File**: `FlowSnapTests/Infrastructure/StageManagerLaunchCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-006`, `BR-PIN-006`, `US-PIN-003` Scenario 1

#### TC-PIN-009: Stage Manager Launch Co-existence Disabled or Inactive

```gherkin
Given stageManagerLaunchCoexistenceEnabled == false OR isStageManagerEnabled == false
When  application launch notification is received
Then  zero raise actions are dispatched (standard macOS behavior)
```

**File**: `FlowSnapTests/Infrastructure/StageManagerLaunchCoordinatorTests.swift`  
**Traces to**: `REQ-PIN-006`, `US-PIN-003` Scenario 2
