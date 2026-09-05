# 05 - Risk & Contradiction Scan: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: Launch FlowSnap at Login Integration
- **Story ID**: `US-SNAP-024`
- **Slug**: `launch-at-login`
- **Date**: 2026-09-05
- **Status**: Complete

---

## 1. Risk Register

| Risk ID        | Description                                                                                 | Severity | Likelihood      | Mitigation Strategy                                                                                                                                                        |
| :------------- | :------------------------------------------------------------------------------------------ | :------- | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RISK-LAL-001` | Xcode debug runs / uninstalled binaries fail `SMAppService` registration with system error. | Low      | High (Dev only) | Catch all registration errors gracefully in `SystemLaunchAtLoginManager`; map to `.error` or `.notFound` without crashing. Use `MockLaunchAtLoginManager` for test suites. |
| `RISK-LAL-002` | External change in macOS System Settings > Login Items desynchronizes FlowSnap toggle.      | Medium   | Medium          | Implement active two-way sync on `NSApplication.didBecomeActiveNotification` and Settings view `.onAppear` (`BR-LAL-004`).                                                 |
| `RISK-LAL-003` | User disabled login item in macOS settings resulting in `.requiresApproval`.                | Medium   | Medium          | Detect `.requiresApproval`, render informative warning badge in UI, and provide one-click button to open System Settings (`BR-LAL-005`).                                   |

---

## 2. Contradiction & Compatibility Scan

- **Contradiction with legacy `UserDefaults`**: Legacy code stored a raw `launchAtLogin` boolean. With SMAppService, the system is the source of truth (`BR-LAL-001`). If `UserDefaults` had `true` but system is `.notRegistered`, the system status takes precedence to prevent unauthorized background registration prompts on launch (Confirmed in Stage 2 Elicitation Interview).
- **macOS Version Compatibility**: `SMAppService` requires macOS 13.0+. FlowSnap deployment target is macOS 14.0+, so compatibility is 100% assured with zero legacy fallback code required.

---

## 3. Scope Lock (MoSCoW)

- **Must-Have**:
  - `LaunchAtLoginManaging` protocol and `SystemLaunchAtLoginManager` wrapping `SMAppService.mainApp`.
  - `LaunchAtLoginStatus` domain enum (`.enabled`, `.notRegistered`, `.requiresApproval`, `.notFound`, `.error`).
  - Integration with `PreferencesStore` as `@MainActor` coordinator.
  - UI in `GeneralSettingsView` reflecting real status, `.requiresApproval` warning, and "Open System Settings" button.
  - Comprehensive unit test suite (`LaunchAtLoginManagerTests`).
- **Won't-Have (v1.0)**:
  - Deprecated `SMLoginItemSetEnabled` or helper launcher app (`FlowSnapLauncher.app`).
  - Silent auto-registration on app launch without explicit user toggle.
