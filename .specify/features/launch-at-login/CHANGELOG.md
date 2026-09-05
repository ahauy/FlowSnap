# Changelog: launch-at-login (US-SNAP-024)

## [1.0.0] - 2026-09-05

### Added

- Domain protocol `LaunchAtLoginManaging` and `LaunchAtLoginStatus` enum (`.enabled`, `.notRegistered`, `.requiresApproval`, `.notFound`, `.error(String)`).
- `SystemLaunchAtLoginManager` wrapping `SMAppService.mainApp` with system settings navigation.
- `MockLaunchAtLoginManager` test double supporting simulated errors and status transitions.
- Two-way status synchronization in `PreferencesStore` on `NSApplication.didBecomeActiveNotification`.
- `GeneralSettingsView` launch policy card with approval warning indicator and "Open Login Items Settings" button.
- Comprehensive unit test suite `LaunchAtLoginManagerTests` (8 tests passing).
- Architecture Decision Record `adr/0017-launch-at-login-sm-app-service.md`.
- Technical documentation in `docs/features/launch-at-login/README.md`.
- End-user documentation in `docs/user-guides/launch-at-login.md`.
