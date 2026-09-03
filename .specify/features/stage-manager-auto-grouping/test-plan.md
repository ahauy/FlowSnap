# Test Plan: Stage Manager Multi-Window Auto-Grouping (US-WORK-017)

**Feature slug**: `stage-manager-auto-grouping`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (before implementation)
**Traces to**: `.specify/features/stage-manager-auto-grouping/05-user-stories.md`

---

## Unit Tests

### `StageManagerDetector`

#### TC-SMA-001: Reads Stage Manager Enabled State

```gherkin
Given com.apple.WindowManager preference GloballyEnabled is true (or 1)
When  isStageManagerEnabled is accessed
Then  it returns true
```

**File**: `FlowSnapTests/Infrastructure/StageManagerDetectorTests.swift`
**Traces to**: `REQ-SMA-001`, `BR-SMA-001`

#### TC-SMA-002: Reads Stage Manager Disabled State & Missing Preference Fallback

```gherkin
Given com.apple.WindowManager preference GloballyEnabled is false (or 0) or nil
When  isStageManagerEnabled is accessed
Then  it returns false
```

**File**: `FlowSnapTests/Infrastructure/StageManagerDetectorTests.swift`
**Traces to**: `REQ-SMA-001`, `BR-SMA-005`

---

### `WorkspaceManager+Restore` (Smart Stage Coordination)

#### TC-SMA-003: Multi-Window Workspace Restore with Stage Manager Active (Happy Path)

```gherkin
Given Stage Manager is enabled (isStageManagerEnabled == true)
  And a workspace with 2 apps: VS Code (Anchor) and Chrome (Secondary)
When  restore(workspace:) is called
Then  VS Code is placed and revealed via launcher.reveal
  And Chrome is placed and raised via accessibilityService.raise
  And Chrome is NOT revealed via launcher.reveal (preventing Stage swap)
  And VS Code is re-raised to retain primary keyboard focus
```

**File**: `FlowSnapTests/Core/WorkspaceManagerStageManagerTests.swift`
**Traces to**: `US-SMA-001` Scenario 1, `REQ-SMA-002`, `REQ-SMA-003`, `REQ-SMA-004`

#### TC-SMA-004: Multi-Window Workspace Restore with Stage Manager Inactive

```gherkin
Given Stage Manager is disabled (isStageManagerEnabled == false)
  And a workspace with 2 apps: VS Code and Chrome
When  restore(workspace:) is called
Then  both VS Code and Chrome are revealed via launcher.reveal (standard restore)
```

**File**: `FlowSnapTests/Core/WorkspaceManagerStageManagerTests.swift`
**Traces to**: `US-SMA-001` Scenario 2, `REQ-SMA-005`

#### TC-SMA-005: Single-App Workspace Restore with Stage Manager Active

```gherkin
Given Stage Manager is enabled (isStageManagerEnabled == true)
  And a workspace with 1 app: Safari
When  restore(workspace:) is called
Then  Safari is placed and revealed via launcher.reveal
```

**File**: `FlowSnapTests/Core/WorkspaceManagerStageManagerTests.swift`
**Traces to**: `US-SMA-001` Scenario 4

#### TC-SMA-006: Secondary App Hidden (Cmd+H) Unhide & Raise

```gherkin
Given Stage Manager is enabled (isStageManagerEnabled == true)
  And Secondary app (Chrome) is hidden
When  restore(workspace:) is called
Then  Chrome has unhide called
  And Chrome is placed and raised via accessibilityService.raise without reveal
```

**File**: `FlowSnapTests/Core/WorkspaceManagerStageManagerTests.swift`
**Traces to**: `US-SMA-001` Scenario 3
