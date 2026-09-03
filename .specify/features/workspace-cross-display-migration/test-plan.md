# Test Plan: Atomic Workspace Cross-Display Migration (US-DISP-017)

**Feature slug**: `workspace-cross-display-migration`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (before implementation)
**Traces to**: `.specify/features/workspace-cross-display-migration/05-user-stories.md`

---

## Unit Tests

### `WorkspaceMigrator`

#### TC-MIG-001: 2-Window Workspace Migration across Displays (Stage Manager OFF)

```gherkin
Given 2 connected displays (Display 1: 2560x1440, Display 2: 1920x1080)
  And Stage Manager is disabled
  And an active workspace with 2 windows (Editor 60% Left, Terminal 40% Right) on Display 1
When  migrateActiveWorkspace(direction: .next) is called
Then  both windows are moved to Display 2 with proportional bounds via RelativeFrameScaler
  And mouse cursor is warped to the center of the primary window on Display 2
  And returns .success(windowsMigrated: 2, targetDisplayID: Display2.id)
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `US-MIG-001` Scenario 1, `REQ-MIG-001`, `REQ-MIG-003`

#### TC-MIG-002: 3-Window Workspace Migration with 2-Phase Move Ordering

```gherkin
Given 2 connected displays
  And Stage Manager is disabled
  And an active workspace with 3 windows on Display 1
When  migrateActiveWorkspace(direction: .next) is called
Then  windows shrinking in area are moved in Phase 1 before windows expanding in Phase 2
  And all 3 windows are placed accurately on Display 2
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `US-MIG-001` Scenario 1, `REQ-MIG-004`

#### TC-MIG-003: Multi-Window Migration with Stage Manager Active (Staggered IPC & Raise)

```gherkin
Given 2 connected displays
  And Stage Manager is enabled (isStageManagerEnabled == true)
  And an active workspace with 2 windows (Anchor Window, Secondary Window) on Display 1
When  migrateActiveWorkspace(direction: .next) is called
Then  Anchor Window is moved to Display 2 first
  And Secondary Window is moved with staggered delay and raised via kAXRaiseAction without app.activate()
  And Anchor Window is re-raised for primary keyboard focus
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `US-MIG-001` Scenario 2, `REQ-MIG-004`

#### TC-MIG-004: Single Display Safe No-Op

```gherkin
Given only 1 display connected
When  migrateActiveWorkspace(direction: .next) is called
Then  it immediately returns .noOp(.singleDisplay)
  And no window move or cursor warp occurs
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `US-MIG-001` Scenario 3, `REQ-MIG-001`

#### TC-MIG-005: No Active Workspace Safe No-Op

```gherkin
Given 2 connected displays
  And no active workspace on the focused display
When  migrateActiveWorkspace(direction: .next) is called
Then  it immediately returns .noOp(.noActiveWorkspace)
  And no window move occurs
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `US-MIG-001` Scenario 4, `REQ-MIG-002`

#### TC-MIG-006: Cyclic Wrap-Around Display Resolution

```gherkin
Given 3 displays arranged horizontally (D1, D2, D3)
  And active workspace on D3
When  migrating with direction .next
Then  target display resolved is D1
When  migrating with direction .previous from D1
Then  target display resolved is D3
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `US-MIG-001` Scenario 5, `REQ-MIG-001`

---

## Component Integration Tests

### `CommandDispatcher` + `WorkspaceMigrator`

#### TC-MIG-007: WindowCommand.migrateWorkspace Dispatches to WorkspaceMigrator

```gherkin
Given CommandDispatcher initialized with WorkspaceMigrator
When  dispatch(.migrateWorkspace(.next)) is called
Then  workspaceMigrator receives migrateActiveWorkspace(direction: .next)
```

**File**: `FlowSnapTests/Core/Workspace/WorkspaceMigratorTests.swift`
**Traces to**: `REQ-MIG-006`
