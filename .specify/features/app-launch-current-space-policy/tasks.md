# Tasks — App Launch Observer & Current Space Policy (US-WORK-013)

> Dependency-ordered breakdown. Each task is atomic, ≤ 50 LOC, and references
> a TC-013-* test ID. Ordering: Data → Logic → Service → Wiring → Tests → Docs.
> Implementation is delegated to `implementation-orchestrator` (Phase 5).

## Phase A — Data (Domain/Core types)

### T-013-A1 — Add `ApplicationObserving` protocol + defaults
- **File**: `FlowSnap/Domain/Window/ApplicationObserving.swift`
- **LOC cap**: 50
- **Deps**: none
- **Acceptance**: file compiles; matches `contracts/ApplicationObserving.swift`
  surface; no AppKit / ApplicationServices imports.
- **Verifies**: TC-013-02 (mock-implementable)

### T-013-A2 — Add `LaunchObservationEvent` + `AXErrorCode` + `LaunchObservationFailure`
- **File**: `FlowSnap/Domain/Window/LaunchObservationEvent.swift`
- **LOC cap**: 50
- **Deps**: T-013-A1
- **Acceptance**: all `Sendable`; matches `contracts/LaunchEvent.swift`.
- **Verifies**: TC-013-03 (event round-trip)

### T-013-A3 — Extend `WindowEvent` with `applicationWindowCreated`
- **File**: `FlowSnap/Core/Events/WindowEvent.swift`
- **LOC cap**: 50
- **Deps**: none
- **Acceptance**: gains `Sendable`; replaces
  `applicationLaunched(pid_t)` with `applicationLaunched(pid_t, bundleID: String?)`;
  adds `applicationWindowCreated(pid:windowID:)`; existing call sites in
  WorkspaceObserver updated.
- **Verifies**: TC-013-01

## Phase B — Logic (Core)

### T-013-B1 — Implement `WindowPolicyManager.applyPolicy` for `.currentSpace` + `.currentDisplay`
- **File**: `FlowSnap/Core/Policy/WindowPolicyManager.swift`
- **LOC cap**: 50
- **Deps**: T-013-A3
- **Change**: replace stub body; resolve `ManagedWindow` from `windowID` via
  `AccessibilityService`, compute target frame from
  `DisplayManaging.visibleFrame`, call `AccessibilityService.setFrame(_:for:)`.
- **Acceptance**: only `.currentSpace` and `.currentDisplay` apply frames; other
  policies remain no-op (US-WORK-014).
- **Verifies**: TC-013-06

### T-013-B2 — Subscribe `WindowPolicyManager` to `applicationWindowCreated`
- **File**: `FlowSnap/Core/Policy/WindowPolicyManager.swift`
- **LOC cap**: 50
- **Deps**: T-013-B1
- **Change**: new method `handle(event:)`; idempotent subscribe in `init`.
- **Verifies**: TC-013-06

## Phase C — Service (Infrastructure)

### T-013-C1 — Implement `WorkspaceObserver.startObserving`
- **File**: `FlowSnap/Infrastructure/macOS/WorkspaceObserver.swift`
- **LOC cap**: 50
- **Deps**: T-013-A3
- **Change**: subscribe to
  `NSWorkspace.didLaunchApplicationNotification`,
  `didActivateApplicationNotification`,
  `didTerminateApplicationNotification`; publish `WindowEvent.applicationLaunched(pid, bundleID:)`.
- **Acceptance**: notifications stored in `NSObjectProtocol` tokens for clean
  removal in `stopObserving`.
- **Verifies**: TC-013-01

### T-013-C2 — AXObserver callback bridging utility
- **File**: `FlowSnap/Infrastructure/macOS/AXObserverBridge.swift`
- **LOC cap**: 50
- **Deps**: none
- **Change**: typed `@Sendable` `Box<T: Sendable>` wrapper for C-callback
  `refCon`; helper that bridges to `Task { @MainActor in }`.
- **Verifies**: TC-013-03

### T-013-C3 — `ApplicationObserver` init + state table
- **File**: `FlowSnap/Infrastructure/macOS/ApplicationObserver.swift`
- **LOC cap**: 50
- **Deps**: T-013-C2
- **Change**: `init(eventBus:timeout:dedupWindow:)`; `private var entries: [pid_t: Entry]`;
  `Entry { observer: AXObserver, timeoutTask: Task<Void, Never>, registeredAt: Date }`.
- **Verifies**: TC-013-02

### T-013-C4 — `ApplicationObserver.observe(pid:)` registration path
- **File**: `FlowSnap/Infrastructure/macOS/ApplicationObserver.swift` (same file, edit)
- **LOC cap**: 50
- **Deps**: T-013-C3, T-013-B2
- **Change**: dedup check → `AXObserverCreate` →
  `AXObserverAddNotification(..., kAXWindowCreatedNotification, ...)`
  → schedule timeout → update entry.
- **Verifies**: TC-013-02, TC-013-05

### T-013-C5 — AXObserver C-callback → event publish
- **File**: `FlowSnap/Infrastructure/macOS/ApplicationObserver.swift` (same file, edit)
- **LOC cap**: 50
- **Deps**: T-013-C4
- **Change**: callback reads `kAXWindowAttribute` → publishes
  `LaunchObservationEvent.windowCreated` and `WindowEvent.applicationWindowCreated`.
- **Verifies**: TC-013-03

### T-013-C6 — Timeout cleanup
- **File**: `FlowSnap/Infrastructure/macOS/ApplicationObserver.swift` (same file, edit)
- **LOC cap**: 50
- **Deps**: T-013-C5
- **Change**: 10 s timeout task publishes `.timeout` and removes entry.
- **Verifies**: TC-013-04

### T-013-C7 — `stopObserving(pid:)` and `stopObservingAll()`
- **File**: `FlowSnap/Infrastructure/macOS/ApplicationObserver.swift` (same file, edit)
- **LOC cap**: 50
- **Deps**: T-013-C6
- **Change**: cancel timeout task, `CFRelease(observer)`, remove entry; finish
  `AsyncStream` on `stopObservingAll()`.
- **Verifies**: TC-013-04

## Phase D — Wiring (App)

### T-013-D1 — Register observer in `AppDependencies`
- **File**: `FlowSnap/App/AppDependencies.swift`
- **LOC cap**: 50
- **Deps**: T-013-C7, T-013-B2
- **Change**: add `lazy var applicationObserver: ApplicationObserving`; wire
  `WindowPolicyManager.subscribe(to: eventBus)`; call
  `workspaceObserver.startObserving()` in `init` (or via `applicationDidFinishLaunching`).
- **Verifies**: TC-013-01, TC-013-06

## Phase E — Tests (assigned to `FlowSnapTests` subagent; no code here)

| Task  | File                                              | Verifies       |
| :---- | :------------------------------------------------ | :------------- |
| T-013-E1 | `FlowSnapTests/Mocks/MockApplicationObserver.swift` | TC-013-02..05 |
| T-013-E2 | `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift` (extend) | TC-013-06 |
| T-013-E3 | `FlowSnapTests/Infrastructure/WorkspaceObserverTests.swift` | TC-013-01 |
| T-013-E4 | `FlowSnapTests/Infrastructure/ApplicationObserverTests.swift` | TC-013-02..05 |
| T-013-E5 | CI grep gate: `! grep -RE "CGS|SLS" FlowSnap/Infrastructure/` | TC-013-07 |

## Phase F — Docs (assigned to `tech-doc-architect`; not in scope for this plan)

- `docs/features/app-launch-current-space-policy/README.md`
- `docs/user-guides/app-launch-current-space-policy.md`
- These are *post-implementation* (Phase 6 Step 2) and require running
  Playwright screenshots; not produced here.

## Dependency DAG

```text
T-013-A1 ── T-013-A2
   │
   ▼
T-013-A3 ──┬── T-013-B1 ── T-013-B2
           │
           └── T-013-C1
                │
                ▼
              T-013-C2 ── T-013-C3 ── T-013-C4 ── T-013-C5 ── T-013-C6 ── T-013-C7
                                                                             │
                                                                             ▼
                                                                       T-013-D1
                                                                             │
                                                                             ▼
                                                                       T-013-E1..E5
```

## Total LOC Budget (implementation only)

| Component                       | Budget |
| :------------------------------ | :----: |
| Domain protocols + types        | 100    |
| WindowEvent + WindowPolicyManager | 100  |
| WorkspaceObserver               | 50     |
| AXObserverBridge                | 50     |
| ApplicationObserver (4 edits)   | 200    |
| AppDependencies wiring          | 50     |
| **Total**                       | **≤ 550** |

This stays within `00-tech-context.md` estimate of "~400–600 lines".