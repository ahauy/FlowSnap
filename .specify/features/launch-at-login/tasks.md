# Tasks: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: `launch-at-login`
- **Story ID**: `US-SNAP-024`
- **Date**: 2026-09-05

---

## Task Breakdown

### Phase 1: Architecture & ADR

- [x] `TASK-LAL-001`: Create `adr/0017-launch-at-login-sm-app-service.md` documenting the architecture decision for `SMAppService.mainApp`.

### Phase 2: Domain Contracts & Test Doubles

- [x] `TASK-LAL-002`: Create `FlowSnap/Domain/Services/LaunchAtLoginManaging.swift` with `LaunchAtLoginStatus` enum and `LaunchAtLoginManaging` protocol.
- [x] `TASK-LAL-003`: Create `FlowSnapTests/Mocks/MockLaunchAtLoginManager.swift` with full status stubbing, failure simulation, and invocation tracking.

### Phase 3: Infrastructure Service Implementation

- [x] `TASK-LAL-004`: Create `FlowSnap/Infrastructure/Services/SystemLaunchAtLoginManager.swift` implementing `LaunchAtLoginManaging` via `SMAppService.mainApp` and URL opening for macOS System Settings.

### Phase 4: PreferencesStore Integration

- [x] `TASK-LAL-005`: Update `PreferencesStore.swift` to accept `LaunchAtLoginManaging`, publish `launchAtLoginStatus`, implement `refreshLaunchAtLoginStatus()`, observe `NSApplication.didBecomeActiveNotification`, and coordinate registration on `setLaunchAtLogin`.
- [x] `TASK-LAL-006`: Update `AppDependencies.swift` to register `SystemLaunchAtLoginManager` and inject it into `PreferencesStore`.

### Phase 5: Settings UI Enhancement

- [x] `TASK-LAL-007`: Update `GeneralSettingsView.swift` Launch Policy section with live status badge, warning message when `.requiresApproval`, and "Open macOS System Settings" action button.

### Phase 6: Test Suite (TDD)

- [x] `TASK-LAL-008`: Create `FlowSnapTests/Infrastructure/LaunchAtLoginManagerTests.swift` testing registration, unregistration, two-way sync, approval required, and error handling.
- [x] `TASK-LAL-009`: Run `xcodebuild test` and verify 100% test pass rate with zero regressions.
