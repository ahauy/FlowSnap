# Test Plan: Launch FlowSnap at Login (US-SNAP-024)

**Feature slug**: `launch-at-login`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI (Antigravity) — Stage TDD (before implementation)  
**Traces to**: `.specify/features/launch-at-login/06-user-stories.md`

---

## Unit Tests

### `LaunchAtLoginManagerTests` (`FlowSnapTests/Infrastructure/LaunchAtLoginManagerTests.swift`)

#### TC-LAL-001: Initial Status Derivation from SMAppService

```gherkin
Given MockLaunchAtLoginManager is configured with status .enabled
When  PreferencesStore is initialized with the mock manager
Then  store.launchAtLogin evaluates to true
  And store.launchAtLoginStatus evaluates to .enabled
```

**Traces to**: `US-LAL-001`, `BR-LAL-001`

---

#### TC-LAL-002: Initial Status Not Registered

```gherkin
Given MockLaunchAtLoginManager is configured with status .notRegistered
When  PreferencesStore is initialized with the mock manager
Then  store.launchAtLogin evaluates to false
  And store.launchAtLoginStatus evaluates to .notRegistered
```

**Traces to**: `US-LAL-001`, `BR-LAL-001`

---

#### TC-LAL-003: User Toggles ON Calls Register

```gherkin
Given PreferencesStore is initialized with mock manager in .notRegistered state
When  store.setLaunchAtLogin(true) is invoked
Then  mock manager registerCallCount increments by 1
  And store.launchAtLogin evaluates to true
  And store.launchAtLoginStatus evaluates to .enabled
```

**Traces to**: `US-LAL-001`, `BR-LAL-002`

---

#### TC-LAL-004: User Toggles OFF Calls Unregister

```gherkin
Given PreferencesStore is initialized with mock manager in .enabled state
When  store.setLaunchAtLogin(false) is invoked
Then  mock manager unregisterCallCount increments by 1
  And store.launchAtLogin evaluates to false
  And store.launchAtLoginStatus evaluates to .notRegistered
```

**Traces to**: `US-LAL-002`, `BR-LAL-003`

---

#### TC-LAL-005: Registration Failure Reverts State Gracefully

```gherkin
Given MockLaunchAtLoginManager is configured to throw an error on register()
When  store.setLaunchAtLogin(true) is invoked
Then  the error is caught without throwing an unhandled exception
  And store.launchAtLogin evaluates to false
  And store.launchAtLoginStatus evaluates to .error("Simulated registration error")
```

**Traces to**: `US-LAL-005`, `BR-LAL-002`, `BR-LAL-006`

---

#### TC-LAL-006: External Status Change Synchronized on App Activation

```gherkin
Given PreferencesStore is initialized with mock manager in .enabled state
When  external system changes status to .notRegistered
  And NSApplication.didBecomeActiveNotification is posted
Then  store.launchAtLogin updates to false
  And store.launchAtLoginStatus updates to .notRegistered
```

**Traces to**: `US-LAL-003`, `BR-LAL-004`

---

#### TC-LAL-007: Requires Approval State and Open System Settings

```gherkin
Given PreferencesStore is initialized with mock manager in .requiresApproval state
When  store.openSystemLoginItemsSettings() is invoked
Then  mock manager openSystemSettingsCallCount increments by 1
  And store.launchAtLoginStatus.requiresUserApproval evaluates to true
```

**Traces to**: `US-LAL-004`, `BR-LAL-005`

---

#### TC-LAL-008: Explicit Status Refresh

```gherkin
Given MockLaunchAtLoginManager status changes from .notRegistered to .enabled
When  store.refreshLaunchAtLoginStatus() is called
Then  store.launchAtLogin evaluates to true
  And store.launchAtLoginStatus evaluates to .enabled
```

**Traces to**: `US-LAL-003`, `BR-LAL-004`
