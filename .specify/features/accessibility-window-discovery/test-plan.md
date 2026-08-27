# Test Plan: Accessibility & Focused Window Discovery (US-SNAP-001)

**Feature slug**: `accessibility-window-discovery`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI (`code-explorer` / `backend-developer`) — Stage TDD (Prior to Implementation)  
**Traces to**: `.specify/features/accessibility-window-discovery/spec/user-stories.md`

---

## Unit Tests

### `AccessibilityService` (Permission & Router)

#### TC-AX-001: Trusted State Verification

```gherkin
Given Accessibility permission has been granted in macOS TCC
When  AccessibilityService.isTrusted is checked
Then  it returns true
```

- **File**: `FlowSnapTests/Infrastructure/AccessibilityServiceTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001a` Scenario 1

#### TC-AX-002: Untrusted State Verification

```gherkin
Given Accessibility permission has NOT been granted
When  AccessibilityService.isTrusted is checked
Then  it returns false
```

- **File**: `FlowSnapTests/Infrastructure/AccessibilityServiceTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001a` Scenario 2

#### TC-AX-003: System Settings Router URL Scheme

```gherkin
Given SystemSettingsRouter is requested to route to accessibility
When  openAccessibilitySettings() is executed
Then  it targets "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

- **File**: `FlowSnapTests/Infrastructure/AccessibilityServiceTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001a` Scenario 3

---

### `ManagedWindow` & Domain Modeling

#### TC-AX-004: Standard Window Classification & Snappability

```gherkin
Given a ManagedWindow with kind == .normal and isResizable == true
When  window.kind.isSnappable is evaluated
Then  it returns true
```

- **File**: `FlowSnapTests/Domain/ManagedWindowTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001c` Scenario 1

#### TC-AX-005: Dialog and Sheet Window Non-Snappability

```gherkin
Given ManagedWindows with kind == .dialog or kind == .sheet or kind == .system
When  window.kind.isSnappable is evaluated
Then  it returns false for all non-normal kinds
```

- **File**: `FlowSnapTests/Domain/ManagedWindowTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001c` Scenario 2 & 3

#### TC-AX-006: Fallback Title Identity

```gherkin
Given an active window where kAXTitleAttribute is empty or nil
When  the ManagedWindow is constructed using process fallback
Then  ManagedWindow.title contains the localizedName of the running application
```

- **File**: `FlowSnapTests/Domain/ManagedWindowTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001b` Scenario 2

---

### `WindowRegistry` (Core Actor Isolation)

#### TC-AX-007: Safe Concurrent Registration and Lookup

```gherkin
Given an empty WindowRegistry actor
When  a ManagedWindow is registered and subsequently retrieved by id
Then  the retrieved window matches the stored instance with identical geometry
```

- **File**: `FlowSnapTests/Core/WindowRegistryTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-001b` Scenario 1

---

## Test Coverage Checklist

- [x] All `US-SNAP-001a` Scenarios covered (TC-AX-001, 002, 003)
- [x] All `US-SNAP-001b` Scenarios covered (TC-AX-006, 007)
- [x] All `US-SNAP-001c` Scenarios covered (TC-AX-004, 005)
- [x] Swift 6 Strict Concurrency and Sendable checks validated
