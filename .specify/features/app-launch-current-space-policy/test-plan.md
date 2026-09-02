# Test Plan: App Launch Observer & Current Space Policy (US-WORK-013)

**Feature slug**: `app-launch-current-space-policy`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Kilo) — Phase 5 TDD (trước implement)
**Traces to**: `.specify/features/app-launch-current-space-policy/spec.md` (§6 US-LAUNCH-001..006)

> **Mục đích**: Document này mô tả test cases ở dạng Gherkin trước khi viết code.
> Sau khi implement xong, actual test files được viết dựa trên document này.

## Mapping Summary

| User Story | TC IDs | File |
| :--- | :--- | :--- |
| US-LAUNCH-001 — Detect a new app launch | TC-013-01 | `FlowSnapTests/Infrastructure/WorkspaceObserverTests.swift` |
| US-LAUNCH-002 — Detect a re-activated app | TC-013-08 | `FlowSnapTests/Infrastructure/WorkspaceObserverTests.swift` |
| US-LAUNCH-003 — First window appears on current Space | TC-013-02, TC-013-03, TC-013-06 | `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift`, `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift` |
| US-LAUNCH-004 — Timeout when no window appears within 10 s | TC-013-04 | `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift` |
| US-LAUNCH-005 — Dedup of rapid duplicate launches | TC-013-05 | `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift` |
| US-LAUNCH-006 — Public macOS APIs only | TC-013-07 | `scripts/audit-no-private-apis.sh` (CI grep gate) |

| Requirement | TC IDs |
| :--- | :--- |
| REQ-LAUNCH-001 (WorkspaceObserver listen) | TC-013-01, TC-013-08 |
| REQ-LAUNCH-002 (AXObserver register) | TC-013-02, TC-013-05 |
| REQ-LAUNCH-003 (apply `.currentSpace`) | TC-013-06 |
| REQ-LAUNCH-004 (10s timeout, cleanup) | TC-013-04 |
| REQ-LAUNCH-005 (100% public APIs) | TC-013-07 |

Additional contract-level TCs (from `data-model.md` and `plan.md` §3.1):
- TC-013-09 — `ApplicationObserving` protocol is `Sendable` and shape-stable for mocks.
- TC-013-10 — `LaunchObservationEvent` / `LaunchObservationFailure` / `AXErrorCode` are `Sendable` + `Hashable`.
- TC-013-11 — `WindowEvent.applicationLaunched(pid, bundleID:)` and `WindowEvent.applicationWindowCreated(pid, windowID:)` are `Sendable` + `Hashable`.

---

## Unit Tests

### `ApplicationObserving` (Domain protocol contract)

#### TC-013-09: Protocol shape and Sendability

```gherkin
Given the `ApplicationObserving` protocol defined in Domain
When a test-only type conforms to it (e.g. `MockApplicationObserver`)
Then the conformance compiles without warnings
  And the protocol is declared `: Sendable`
  And it exposes `observe(pid:bundleID:)` async, `stopObserving(pid:)` sync, and `events: AsyncStream<LaunchObservationEvent>`
```

**File**: `FlowSnapTests/Domain/ApplicationObservingContractTests.swift`
**Priority**: Must-Have
**Traces to**: `data-model.md §1.1`, `plan.md §3.1`

---

### `LaunchObservationEvent` (Domain value type)

#### TC-013-10: Event and failure types are Sendable + Hashable

```gherkin
Given `LaunchObservationEvent`, `LaunchObservationFailure`, and `AXErrorCode` defined in Domain
When constructed with sample values
Then each is `Sendable` and `Hashable`
  And `LaunchObservationEvent.windowCreated(pid, windowID)`, `.timeout(pid)`, `.failed(pid, reason:)` are valid cases
  And `AXErrorCode(rawValue: Int32)` round-trips via `rawValue`
```

**File**: `FlowSnapTests/Domain/LaunchObservationEventTests.swift`
**Priority**: Must-Have
**Traces to**: `data-model.md §1.2`

---

### `WindowEvent` (Core event)

#### TC-013-11: New event cases are Sendable + Hashable

```gherkin
Given `WindowEvent` is extended with `applicationLaunched(pid_t, bundleID: String?)` and `applicationWindowCreated(pid:windowID:)`
When a `WindowEvent.applicationLaunched(pid: 42, bundleID: "com.example.app")` is constructed
  And a `WindowEvent.applicationWindowCreated(pid: 42, windowID: 99)` is constructed
Then both values are `Sendable` and `Hashable`
  And the `Hashable` synthesis considers `bundleID` (different bundleIDs produce different hashes)
```

**File**: `FlowSnapTests/Core/Events/WindowEventLaunchTests.swift`
**Priority**: Must-Have
**Traces to**: `plan.md §3.2`, T-013-A3

---

### `WorkspaceObserver` (Infrastructure NSWorkspace bridge)

#### TC-013-01: Publishes `applicationLaunched(pid, bundleID)` on `didLaunchApplicationNotification`

```gherkin
Given a `WorkspaceObserver` wired to an `EventBus` and a fake `NSWorkspace` notification source
When the fake posts `NSWorkspace.didLaunchApplicationNotification` with an `NSRunningApplication(pid: 1001, bundleID: "com.apple.Safari")`
Then the `EventBus` receives exactly one `WindowEvent.applicationLaunched(pid: 1001, bundleID: "com.apple.Safari")`
  And the observer returns synchronously (no polling, no delay)
```

**File**: `FlowSnapTests/Infrastructure/WorkspaceObserverTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-001`, `REQ-LAUNCH-001`

#### TC-013-08: Publishes `applicationLaunched(pid, bundleID)` on `didActivateApplicationNotification`

```gherkin
Given a `WorkspaceObserver` is observing
When the fake posts `NSWorkspace.didActivateApplicationNotification` for an already-running app
Then the `EventBus` receives `WindowEvent.applicationLaunched(pid, bundleID)` for the activated app
  And no new AXObserver is registered (US-LAUNCH-002, handled by ApplicationObserver dedup)
```

**File**: `FlowSnapTests/Infrastructure/WorkspaceObserverTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-002`, `REQ-LAUNCH-001`

---

### `ApplicationObserver` (Infrastructure AXObserver lifecycle)

#### TC-013-02: `observe(pid:)` registers an AXObserver and registers a notification

```gherkin
Given an `ApplicationObserver` constructed with a fake `AXObserverCreate` injector
When `observe(pid: 1001, bundleID: "com.example")` returns
Then exactly one `AXObserverCreate` was invoked for `pid: 1001`
  And `AXObserverAddNotification` was called with `kAXWindowCreatedNotification` on the app element
  And a 10s timeout task was scheduled (observable via the test clock or a hook)
```

**File**: `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-001`, `REQ-LAUNCH-002`, TC-013-02 (plan §9)

#### TC-013-03: AXObserver callback publishes `applicationWindowCreated`

```gherkin
Given an `ApplicationObserver` has registered an observer for `pid: 1001`
When the simulated AXObserver callback fires for a window with `kAXWindowAttribute` = 99
Then the `EventBus` receives `WindowEvent.applicationWindowCreated(pid: 1001, windowID: 99)`
  And the `ApplicationObserving.events` stream yields `LaunchObservationEvent.windowCreated(pid: 1001, windowID: 99)`
  And the AXObserver entry is cleaned up (auto-release, plan §10 decision 2)
```

**File**: `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-003`, `REQ-LAUNCH-002`, TC-013-03 (plan §9)

#### TC-013-04: Timeout at 10 s calls cleanup and publishes `.timeout`

```gherkin
Given an `ApplicationObserver` has registered an observer for `pid: 1001` but no callback has fired
When 10 seconds elapse without any `kAXWindowCreatedNotification`
Then the `ApplicationObserving.events` stream yields `LaunchObservationEvent.timeout(pid: 1001)`
  And the AXObserver entry is removed
  And no `applicationWindowCreated` event is published on the `EventBus`
```

**File**: `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-004`, `REQ-LAUNCH-004`, TC-013-04 (plan §9)

#### TC-013-05: Dedup within 5 s prevents re-registration

```gherkin
Given an `ApplicationObserver` already has a registered entry for `pid: 1001`
When `observe(pid: 1001, bundleID: "com.example")` is called again within 5 seconds
Then no second `AXObserverCreate` is invoked
  And the existing observer continues to operate until its 10 s timeout
```

**File**: `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-005`, `REQ-LAUNCH-002`, TC-013-05 (plan §9)

---

### `WindowPolicyManager.applyPolicy` (Core)

#### TC-013-06: `.currentSpace` invokes `setFrame` with `DisplayManaging.visibleFrame`

```gherkin
Given a `WindowPolicyManager` with default policy `.currentSpace`
  And a `MockAccessibilityService` recording `setFrame` calls
  And a `MockDisplayManager` whose `primaryDisplay.visibleFrame` is `CGRect(x: 0, y: 25, width: 1920, height: 1055)`
When `applyPolicy(for: someManagedWindow)` is invoked
Then `setFrame` is called exactly once on the `MockAccessibilityService`
  And the frame passed equals the `MockDisplayManager.primaryDisplay.visibleFrame`
  And the policy is resolved via `defaultPolicy` (no per-bundle override)
```

**File**: `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift`
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-003`, `REQ-LAUNCH-003`, TC-013-06 (plan §9)

---

### Source Audit (CI gate)

#### TC-013-07: Zero `CGS` / `SLS` symbols in Infrastructure

```gherkin
Given the full source under `FlowSnap/Infrastructure/`
When audited with `grep -E "CGS|SLS"`
Then zero matches are returned
```

**File**: `scripts/audit-no-private-apis.sh` (CI grep gate; T-013-E5)
**Priority**: Must-Have
**Traces to**: `US-LAUNCH-006`, `REQ-LAUNCH-005`, TC-013-07 (plan §9)

---

## Test Coverage Checklist

- [x] All `US-LAUNCH-###` Scenario 1 (happy path) have corresponding TCs (TC-013-01, TC-013-03, TC-013-06)
- [x] All `US-LAUNCH-###` Scenario 2+ (edge cases) have corresponding TCs (TC-013-04 timeout, TC-013-05 dedup, TC-013-08 activate)
- [x] Business rule anti-abuse: dedup within 5s prevents observer thrash (TC-013-05)
- [x] Error states covered: `LaunchObservationEvent.failed` (via `MockApplicationObserver.failingBundleIDs`), `AXObserverCreate` failure, `AXObserverAddNotification` failure
- [x] Idempotency: dedup makes `observe(pid:)` idempotent within `dedupWindow` (TC-013-05)
- [x] Race conditions: timeout vs. callback race (TC-013-03 vs TC-013-04 — first to fire wins; auto-release semantics from plan §10 decision 2)
- [x] Sendable proof: TC-013-09, TC-013-10, TC-013-11 (Swift 6 strict concurrency gate)
- [x] Public API gate: TC-013-07 (CI grep)
