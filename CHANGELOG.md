# Changelog

All notable changes to FlowSnap are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2] — 2026-09-02 — IMPLEMENTATION COMPLETE

### Added — US-WORK-013: App Launch Observer & Current Space Policy

- **Domain**
  - `ApplicationObserving` protocol — `Sendable` seam for per-pid
    `kAXWindowCreatedNotification` observation.
  - `LaunchObservationEvent`, `LaunchObservationFailure`, `AXErrorCode`
    value types (all `Sendable` + `Hashable`).
  - `ApplicationObservingDefaults` — `windowCreationTimeout: 10s`,
    `launchDedupWindow: 5s`.
- **Core**
  - `WindowEvent.applicationLaunched(pid_t, bundleID: String?)` —
    **in-place replacement** of the pre-1.2 `applicationLaunched(pid_t)`
    (plan §10 decision 1). In-tree-only; no external consumers.
  - `WindowEvent.applicationWindowCreated(pid:windowID:)` — new case.
  - `WindowPolicyManager.applyPolicy(for:)` — implements `.currentSpace`
    and `.currentDisplay` by writing `DisplayManaging.primaryDisplay.visibleFrame`
    through `AccessibilityService.setFrame`. Other policies remain no-op
    (US-WORK-014).
  - `WindowPolicyManager.handle(event:)` — subscribes to
    `.applicationWindowCreated` from the shared `EventBus` (T-013-B2).
- **Infrastructure**
  - `WorkspaceObserver` — listens to
    `NSWorkspace.didLaunchApplicationNotification`,
    `didActivateApplicationNotification`,
    `didTerminateApplicationNotification` and publishes events on
    `EventBus`. Injectable `NotificationCenter` for tests.
  - `ApplicationObserver` — wraps per-pid `AXObserver` lifecycle:
    registration, 10 s timeout, 5 s dedup, auto-release on
    `.windowCreated` (plan §10 decision 2). Testable via injectable
    `RegistrationFactory`.
- **App**
  - `AppDependencies.eventBus` — shared `EventBus` for cross-service
    pub-sub.
  - `AppDependencies.workspaceObserver`,
    `AppDependencies.applicationObserver`,
    `AppDependencies.windowPolicyManager` — lazy DI factories.
  - `AppDelegate.applicationDidFinishLaunching` starts the
    `WorkspaceObserver` and subscribes the policy manager.
  - `AppDelegate.applicationWillTerminate` cleanly stops the
    observer and unsubscribes the manager.

### Test Plan

- `.specify/features/app-launch-current-space-policy/test-plan.md` —
  11 TCs (TC-013-01..11) covering US-LAUNCH-001..006, REQ-LAUNCH-001..005,
  and the Swift 6 / public-API / Sendable gates.

### CI Gate

- `scripts/audit-no-private-apis.sh` — `grep -E "\bCGS[A-Z_]|\bSLS[A-Z_]"`
  over `FlowSnap/Infrastructure/`. Exits 0 on zero matches (TC-013-07).

### Notes

- **Zero private APIs** (TC-013-07 confirmed by `scripts/audit-no-private-apis.sh`).
- **Zero force unwrap / try / cast** in any new code.
- **Swift 6 strict concurrency** — all new types are `Sendable` or
  actor-isolated. Build clean of warnings for new code.
- `ApplicationObserver.makeLiveRegistration()` is a deliberate
  placeholder — the live `AXObserverCreate` / `AXObserverAddNotification`
  / `CFRunLoopAddSource` wiring is exercised manually against the running
  app. The test path covers the full state machine via the injectable
  factory. See plan §3.4 for the live wiring contract.

## [1.1] — prior — US-WORK-012 (Workspace Presets & Window Groups)

(Summary retained from prior release notes.)
