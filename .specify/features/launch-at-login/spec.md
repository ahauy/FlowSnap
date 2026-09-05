# Specification: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: `launch-at-login`
- **Story ID**: `US-SNAP-024`
- **Parent Epic**: Sprint 7: Launch Automation & System Preferences
- **Status**: Ready for Planning
- **Date**: 2026-09-05

---

## 1. Overview & Context

FlowSnap is a native macOS productivity tool that must run continuously in the background to intercept global hotkeys and manage window layouts. Currently, `PreferencesStore` only stores an inert `launchAtLogin: Bool` in `UserDefaults`. When users restart or log into their Mac, FlowSnap does not automatically launch.

This specification defines the technical integration with macOS 13+ ServiceManagement framework (`SMAppService.mainApp`), replacing the static boolean with an active system service integration, two-way status synchronization, and responsive settings UI.

---

## 2. Requirements & Traceability

### `REQ-LAL-001`: Protocol-based Service Abstraction

FlowSnap shall define a domain protocol `LaunchAtLoginManaging` providing:

- `currentStatus() -> LaunchAtLoginStatus`
- `register() throws`
- `unregister() throws`
- `openSystemSettings()`
  _Derived from: `US-SNAP-024`, `BR-LAL-001`, `BR-LAL-006`_

### `REQ-LAL-002`: System Implementation via SMAppService

FlowSnap shall implement `SystemLaunchAtLoginManager` in `Infrastructure/Services` wrapping `SMAppService.mainApp`:

- Maps `SMAppService.Status.enabled` -> `.enabled`
- Maps `SMAppService.Status.notRegistered` -> `.notRegistered`
- Maps `SMAppService.Status.requiresApproval` -> `.requiresApproval`
- Maps `SMAppService.Status.notFound` -> `.notFound`
- Catches any thrown system errors from `register()` / `unregister()` and maps them to `.error(String)`
  _Derived from: `BR-LAL-001`, `BR-LAL-002`, `BR-LAL-003`, `BR-LAL-006`_

### `REQ-LAL-003`: Two-Way Status Synchronization

`PreferencesStore` shall own an instance of `LaunchAtLoginManaging`, query `currentStatus()` on initialization, and provide `refreshLaunchAtLoginStatus()`:

- `launchAtLogin` publishes `true` if and only if status is `.enabled`.
- Publishes `launchAtLoginStatus: LaunchAtLoginStatus` for fine-grained UI observation.
- Automatically synchronizes when `NSApplication.didBecomeActiveNotification` fires.
  _Derived from: `BR-LAL-001`, `BR-LAL-004`_

### `REQ-LAL-004`: Settings UI Affordance & Navigation

`GeneralSettingsView` shall display:

- A `Toggle("Launch FlowSnap at login", ...)` in the Launch Policy card.
- If status is `.requiresApproval`, an inline warning card with an "Open System Settings" button that directs the user to `x-apple.systempreferences:com.apple.LoginItems-Settings.extension`.
- If status is `.error(...)` or `.notFound`, a subtle informational hint indicating registration status.
  _Derived from: `BR-LAL-005`_

### `REQ-LAL-005`: Dependency Injection & Test Isolation

`AppDependencies` shall inject `SystemLaunchAtLoginManager` into `PreferencesStore`. Tests shall inject `MockLaunchAtLoginManager` to guarantee 100% deterministic testing without altering the host macOS system.
_Derived from: `NFR-Testability`_
