# Architecture Plan — App Launch Observer & Current Space Policy (US-WORK-013)

> Speckit Plan: derives `plan.md` from `spec.md` (5 REQs), grounded in
> `00-tech-context.md` and the existing FlowSnap module layout. No implementation
> code is produced here beyond `contracts/` stubs.

## 1. Goals & Non-Goals

Goals:
- Wire `WorkspaceObserver` to `NSWorkspace` and bridge to `EventBus`.
- Add a focused `ApplicationObserver` infrastructure service that manages
  per-pid `AXObserver` registration, lifecycle, and timeout.
- Apply `.currentSpace` default policy on `kAXWindowCreatedNotification`.
- Preserve 100 % public macOS APIs; Swift 6 strict concurrency; Deep Module
  principles.

Non-Goals:
- `PreferencesStore` integration (US-WORK-014).
- UI wiring for Application Rules tab (US-WORK-014).
- Per-app overrides (US-WORK-014).
- Polling fallback implementation (RISK-LAUNCH-001 mitigation deferred).

## 2. Layer Assignment

| Concern                          | Layer            | New / Existing | File                                  |
| :------------------------------- | :--------------- | :------------- | :------------------------------------ |
| `ApplicationObserving` protocol  | Domain           | NEW            | `Domain/Window/ApplicationObserving.swift` |
| `WindowPolicy` (no change)       | Domain           | existing       | `Domain/Window/WindowPolicy.swift`    |
| `ManagedWindow` (no change)      | Domain           | existing       | `Domain/Window/ManagedWindow.swift`   |
| `LaunchEvent` enum (EventBus payload) | Core        | NEW (extend `WindowEvent` in-place) | `Core/Events/WindowEvent.swift` (add cases) |
| `EventBus` (extend handlers for launch events) | Core | existing (extended) | `Core/Events/EventBus.swift` |
| `WindowPolicyManager.applyPolicy` impl | Core        | NEW impl       | `Core/Policy/WindowPolicyManager.swift` |
| `ApplicationObserver` concrete   | Infrastructure  | NEW            | `Infrastructure/macOS/ApplicationObserver.swift` |
| `WorkspaceObserver` impl         | Infrastructure  | NEW impl       | `Infrastructure/macOS/WorkspaceObserver.swift` |
| DI wiring                        | App              | NEW            | `App/AppDependencies.swift` (lazy var additions) |

**Rationale**: `ApplicationObserving` lives in Domain because it is a stable
abstraction over a flaky OS API. `ApplicationObserver` (concrete) lives in
Infrastructure because it owns `AXObserver` (an `OpaquePointer`) and bridges
C-callbacks to `@MainActor`. Domain never imports AppKit / Accessibility.

## 3. Protocol Seams

```text
┌─────────────────────────────────────────────────────────────────────┐
│ Domain                                                             │
│   protocol ApplicationObserving        // pure Sendable abstraction │
│   enum WindowPolicy                    // existing                  │
│   struct ManagedWindow                 // existing                  │
└───────────────┬─────────────────────────────────────────────────────┘
                │ implements
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Infrastructure                                                     │
│   final class ApplicationObserver : ApplicationObserving            │
│     - manages pid -> AXObserver map                                  │
│     - 10s per-pid timeout                                           │
│     - bridges C-callback → @MainActor Task                          │
│   final class WorkspaceObserver                                       │
│     - subscribes NSWorkspace.notifications                          │
│     - publishes WindowEvent.applicationLaunched(pid, bundleID)      │
└───────────────┬─────────────────────────────────────────────────────┘
                │ publishes
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Core                                                               │
│   @MainActor final class EventBus                                    │
│   @MainActor final class WindowPolicyManager                        │
│     - subscribes to .applicationLaunched                            │
│     - resolves policy → calls AccessibilityService.setFrame          │
│       using DisplayManaging.visibleFrame for .currentSpace          │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.1 `ApplicationObserving` protocol (Domain)

Defined in `Domain/Window/ApplicationObserving.swift`. See `contracts/ApplicationObserving.swift`.

- Pure `Sendable` protocol. No `AppKit`/`ApplicationServices` imports.
- Two methods:
  - `observe(pid:pid_t, bundleID:String?) async`
  - `stopObserving(pid:pid_t)`
- One async stream: `events -> AsyncStream<LaunchObservationEvent>`
- One published event variant: `LaunchObservationEvent.windowCreated(pid, windowID)`,
  `LaunchObservationEvent.timeout(pid)`.

### 3.2 `WindowEvent` extensions (Core)

Extend `enum WindowEvent` in `Core/Events/WindowEvent.swift` with two cases:

```swift
case applicationLaunched(pid_t, bundleID: String?)
case applicationWindowCreated(pid: pid_t, windowID: CGWindowID)
```

(Existing `case applicationLaunched(pid_t)` is replaced in-place — backward
compatible with `Hashable` synthesis; consumers recompile. Documented in
CHANGELOG.)

### 3.3 `WorkspaceObserver` surface (Infrastructure)

- `init(eventBus: EventBus)` (existing).
- `startObserving()` — subscribes to `NSWorkspace.shared.notificationCenter`
  for `NSWorkspace.didLaunchApplicationNotification` and
  `didActivateApplicationNotification`. (Existing `didTerminateApplicationNotification`
  subscription retained.)
- Handler extracts `NSRunningApplication` from `userInfo`, reads `processIdentifier`
  and `bundleIdentifier`, then publishes `WindowEvent.applicationLaunched(pid, bundleID:)`.
- On activate, calls `WindowPolicyManager.applyPolicy(for: window)` for the
  focused window if known.

### 3.4 `ApplicationObserver` surface (Infrastructure)

- `init(eventBus: EventBus, timeout: TimeInterval = 10.0, dedupWindow: TimeInterval = 5.0)`.
- Subscribes to `EventBus` for `.applicationLaunched`.
- Maintains `[pid_t: ObserverEntry]` where `ObserverEntry` holds:
  - `observer: AXObserver` (OpaquePointer wrapper)
  - `task: Task<Void, Never>` (timeout task)
  - `registeredAt: Date`
- On `.applicationLaunched(pid, _)`:
  1. If pid in `dedupWindow` (recent registration), return.
  2. Otherwise create `AXObserverCreate` with `@convention(c)` callback.
  3. `AXObserverAddNotification(observer, appElement, kAXWindowCreatedNotification, ...)`.
  4. Schedule timeout task: `Task { try await Task.sleep(timeout); cleanup(pid) }`.
- Callback handler: cast `elementRef` to `AXUIElement`, query
  `kAXWindowAttribute` for window id, then `Task { @MainActor in [weak self] in
  self?.publish(pid: pid, windowID: wid); self?.cleanup(pid: pid) }`.

## 4. Concurrency Model (Swift 6 strict)

| Component               | Isolation         | Notes                                                  |
| :---------------------- | :---------------- | :----------------------------------------------------- |
| `ApplicationObserving`  | `Sendable` proto  | Pure value types in/out                                |
| `ApplicationObserver`   | `@MainActor`      | Holds `AXObserver` (not `Sendable`); mutations on main  |
| `WorkspaceObserver`     | `@MainActor`      | Wraps `NSWorkspace.notificationCenter`                 |
| `EventBus`              | `@MainActor`      | Existing; unchanged isolation contract                 |
| `WindowPolicyManager`   | `@MainActor`      | Existing; subscribes via `@MainActor` closure          |
| `LaunchObservationEvent`| `Sendable` enum   | Value type, no closures                                |
| `WindowEvent`           | `Sendable` enum   | Already `Hashable`; ensure `Sendable` conformance       |
| AXObserver C-callback   | C context         | Wrap with `@Sendable` `Unmanaged.passUnretained(self)` or `Box<Sendable>` reference; bridge to main via `Task { @MainActor in }` |

**Bridging strategy** (ASM-LAUNCH-005):
- The C-callback receives `void* refCon` = boxed `MainActorBox`.
- Inside callback: extract box, `Task { @MainActor in await box.value.handle(...) }`.
- No shared mutable state across actor boundaries without `Sendable` proof.

## 5. Module Dependency Graph

```text
App
 └─ AppDependencies ─┬─→ Infrastructure/WorkspaceObserver
                     ├─→ Infrastructure/ApplicationObserver (NEW)
                     └─→ Core/WindowPolicyManager (extended applyPolicy)

Core
 ├─ EventBus ←── WindowPolicyManager (subscribes)
 ├─ WindowEvent (extended)
 └─ WindowPolicyManager.applyPolicy(for:) → Infrastructure/AccessibilityService
                                              Infrastructure/DisplayManaging

Infrastructure
 ├─ WorkspaceObserver ──→ Core/EventBus
 ├─ ApplicationObserver ──→ Core/EventBus
 └─ AccessibilityService (existing) ──→ AppKit
 └─ DisplayManaging (existing)         ──→ AppKit

Domain
 └─ ApplicationObserving (NEW protocol) — no AppKit imports
```

**Acyclic guarantee**: Domain has zero imports of Core / Infrastructure / App.
Core imports Domain. Infrastructure imports Domain + Core. App imports all.

## 6. Data Flow (happy path)

```text
1. User double-clicks app X
2. macOS posts NSWorkspace.didLaunchApplicationNotification
3. WorkspaceObserver (Infrastructure, @MainActor) extracts pid + bundleID
4. Publishes WindowEvent.applicationLaunched(pid, bundleID:)
5. ApplicationObserver (Infrastructure, @MainActor) receives event
6. Creates AXObserver, registers kAXWindowCreatedNotification for pid
7. Schedules 10s timeout cleanup
8. macOS creates app's first window; AXObserver callback fires (C context)
9. Callback bridges to @MainActor Task
10. ApplicationObserver reads window id, publishes
    WindowEvent.applicationWindowCreated(pid, windowID)
11. WindowPolicyManager (Core, @MainActor) receives event
12. Looks up policy (default .currentSpace)
13. Asks AccessibilityService to set frame using DisplayManaging.visibleFrame
14. Clears the AXObserver for pid
```

## 7. File-Level Change List

| #  | Action  | Path                                                       | Notes                          |
| :-- | :------ | :--------------------------------------------------------- | :---------------------------- |
| 1  | CREATE  | `Domain/Window/ApplicationObserving.swift`                | NEW protocol                  |
| 2  | EDIT    | `Core/Events/WindowEvent.swift`                            | Add 2 cases; mark `Sendable`   |
| 3  | EDIT    | `Core/Events/EventBus.swift`                              | No structural change          |
| 4  | EDIT    | `Core/Policy/WindowPolicyManager.swift`                    | Implement `applyPolicy` for `.currentSpace` |
| 5  | EDIT    | `Infrastructure/macOS/WorkspaceObserver.swift`             | Implement `startObserving`    |
| 6  | CREATE  | `Infrastructure/macOS/ApplicationObserver.swift`           | NEW concrete observer         |
| 7  | EDIT    | `App/AppDependencies.swift`                                | Add lazy `applicationObserver` + wire manager subscription |
| 8  | CREATE  | `.specify/features/.../contracts/ApplicationObserving.swift` | Standalone stub             |
| 9  | CREATE  | `.specify/features/.../contracts/LaunchEvent.swift`        | Standalone stub (event type contract) |

No changes to: `Domain/Window/WindowPolicy.swift`,
`Domain/Window/ManagedWindow.swift`, `Infrastructure/Accessibility/*`,
`Infrastructure/Display/*`, `App/FlowSnapApp.swift`, `App/AppDelegate.swift`
(delegate work optional; can route via `AppDependencies`).

## 8. Error Handling

- AXObserver creation fails (RISK-LAUNCH-001): log + emit
  `LaunchObservationEvent.failed(pid, reason: .observerCreationFailed)` and
  leave timeout task to clean up the empty entry.
- Callback raises `AXError`: log, no rethrow (callback cannot `throw`); the
  manager will fall back to default behavior on the next legitimate window.
- Window frame set fails: log; do not crash. macOS will display window at
  default position — partial-failure policy.

## 9. Testing Strategy (test IDs, *not test code*)

- TC-013-01 — `WorkspaceObserver` publishes
  `applicationLaunched(pid, bundleID)` on a fake `NSWorkspace` notification.
- TC-013-02 — `ApplicationObserver.observe(pid:)` registers an AXObserver
  (mock `AXObserverCreate` injected).
- TC-013-03 — Callback that produces `kAXWindowCreatedNotification` results in
  `applicationWindowCreated(pid, windowID)` event.
- TC-013-04 — Timeout at 10 s calls `cleanup(pid)` exactly once.
- TC-013-05 — Dedup within 5 s prevents re-registration.
- TC-013-06 — `WindowPolicyManager.applyPolicy(for:)` for `.currentSpace`
  invokes `AccessibilityService.setFrame` with `DisplayManaging.visibleFrame`.
- TC-013-07 — Source audit `grep -E "CGS|SLS" FlowSnap/Infrastructure/` returns
  no matches.

## 10. Confirmed Decisions (signed off by user)

| # | Question | Decision |
| :-- | :--- | :--- |
| 1 | `EventBus` `applicationLaunched` payload change | **In-place replace**: `applicationLaunched(pid_t, bundleID: String?)`. Hashable-breaking but in-tree-only (grep: 0 external consumers). CHANGELOG entry required. |
| 2 | `AXObserver` lifecycle after first window | **Auto-release** on `.windowCreated`. Matches 10 s timeout baseline and `.currentSpace` one-shot policy semantics. |
| 3 | Test scaffolding scope | **`MockApplicationObserver` skeleton produced now** under `FlowSnapTests/Mocks/`. Full test code authored in Phase 5 by test-authoring subagent. |