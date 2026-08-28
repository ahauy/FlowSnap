# Test Plan: Menu Bar Status Item & Quick Snap Controls

**Feature slug**: `menubar-quick-controls`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (Pre-implementation)
**Traces to**: `.specify/features/menubar-quick-controls/spec.md`

---

## Unit Tests

### `MenuBarViewModel`

#### TC-MENU-001: Accessibility Permission State Observation

```gherkin
Given AccessibilityService.isTrusted is false
When  MenuBarViewModel.refreshState() is invoked
Then  MenuBarViewModel.isAccessibilityTrusted is false
And   Warning banner is marked active

Given AccessibilityService.isTrusted is true
When  MenuBarViewModel.refreshState() is invoked
Then  MenuBarViewModel.isAccessibilityTrusted is true
And   Warning banner is marked inactive
```

**File**: `FlowSnapTests/UI/MenuBarViewModelTests.swift`
**Priority**: Must-Have (P0)
**Traces to**: `BR-MENU-004`, `REQ-MENU-004`

---

#### TC-MENU-002: Trigger Snap Action & Auto-Dismiss

```gherkin
Given a focused target window exists
And   a dismiss callback handler is set on MenuBarViewModel
When  MenuBarViewModel.triggerSnap(.leftHalf) is called
Then  CommandDispatcher receives WindowCommand.snap(.leftHalf, targetWindow)
And   dismiss handler is invoked to close the menu
```

**File**: `FlowSnapTests/UI/MenuBarViewModelTests.swift`
**Priority**: Must-Have (P0)
**Traces to**: `BR-MENU-002`, `BR-MENU-003`, `REQ-MENU-003`

---

#### TC-MENU-003: Request Accessibility Permission Action

```gherkin
Given AccessibilityService mock is injected
When  MenuBarViewModel.requestAccessibilityPermission() is called
Then  AccessibilityService.openSystemSettings() is invoked
```

**File**: `FlowSnapTests/UI/MenuBarViewModelTests.swift`
**Priority**: Must-Have (P0)
**Traces to**: `BR-MENU-004`, `REQ-MENU-004`

---

#### TC-MENU-004: MenuBarAction Domain Mapping & Icons

```gherkin
Given all cases in MenuBarAction enum
When  querying target, iconName, and shortcutHint
Then  each action maps to valid SF Symbols and expected shortcut badges (e.g. ⌃⌥←)
```

**File**: `FlowSnapTests/UI/MenuBarViewModelTests.swift`
**Priority**: Must-Have (P0)
**Traces to**: `BR-MENU-005`, `REQ-MENU-005`

---

## Test Coverage Checklist

- [x] TC-MENU-001: Permission status change reaction
- [x] TC-MENU-002: Quick snap command dispatch and auto-dismiss
- [x] TC-MENU-003: System settings deep-link delegation
- [x] TC-MENU-004: Action mapping and shortcut badges
