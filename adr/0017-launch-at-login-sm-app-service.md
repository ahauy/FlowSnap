# ADR-0017: Use SMAppService for Launch at Login Lifecycle Management

- **Status:** Accepted
- **Date:** 2026-09-05
- **Deciders:** Engineering Team, Product Owner
- **Technical context:** FlowSnap requires background auto-start upon macOS user login to maintain global hotkey bindings and window management responsiveness.

## Context

Prior to this decision, FlowSnap held a legacy `launchAtLogin` boolean in `UserDefaults`. This flag did not interact with macOS service management; users had to manually start FlowSnap upon system reboot. Furthermore, changes made by users in macOS System Settings > Login Items were invisible to FlowSnap.

On macOS 13.0+, Apple deprecated legacy login item mechanisms (such as `SMLoginItemSetEnabled` and helper login bundles) in favor of `SMAppService.mainApp`. `SMAppService` provides modern registration, deregistration, and status reporting (`.enabled`, `.notRegistered`, `.requiresApproval`, `.notFound`).

## Decision

1. Adopt Apple's `SMAppService.mainApp` as the single authoritative mechanism for launch-at-login management.
2. Abstract all system calls behind a `Sendable` domain protocol `LaunchAtLoginManaging` and domain status enum `LaunchAtLoginStatus`.
3. Integrate `LaunchAtLoginManaging` into `PreferencesStore`, ensuring the system state is the source of truth, and subscribe to `NSApplication.didBecomeActiveNotification` for automatic two-way status synchronization.
4. When macOS reports `.requiresApproval`, display an informative warning in `GeneralSettingsView` with a direct button link to `x-apple.systempreferences:com.apple.LoginItems-Settings.extension`.

## Consequences

- **Positive**:
  - Native macOS 14+ compliance with zero deprecated APIs.
  - Zero auxiliary helper applications (`FlowSnapLauncher.app`) required in the bundle.
  - Two-way status synchronization ensures the UI toggle always reflects the genuine macOS system state.
  - Test isolation via `MockLaunchAtLoginManager` allows 100% test coverage without touching host system preferences.
- **Negative / Trade-offs**:
  - Requires macOS 13.0+ (FlowSnap target is macOS 14.0+, so this is acceptable).
  - Development / unsigned debug builds from DerivedData may report `.notFound` or throw errors; handled gracefully via domain status enum.

### Alternatives considered

1. **Legacy Helper App (`SMLoginItemSetEnabled`)**: Requires extra target, bundle packaging, and deprecated API. Rejected.
2. **AppleScript / LaunchAgents plist**: Fragile, triggers macOS background item alerts, violates App Sandbox/Hardened Runtime best practices. Rejected.

## Related

- `CONTEXT.md` entry: `LaunchAtLoginManaging`, `LaunchAtLoginStatus`, `SystemLaunchAtLoginManager`
- Feature folder: `.specify/features/launch-at-login/`
