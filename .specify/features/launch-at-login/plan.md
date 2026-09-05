# Technical Plan: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: `launch-at-login`
- **Story ID**: `US-SNAP-024`
- **Date**: 2026-09-05

---

## 1. Architectural Strategy

We adhere to the Ousterhout Deep Module and Dependency Injection principles:

1. **Domain Layer**: Clean, pure protocol `LaunchAtLoginManaging` and value type `LaunchAtLoginStatus`. Zero AppKit / ServiceManagement imports in pure domain types.
2. **Infrastructure Layer**: Concrete `SystemLaunchAtLoginManager` importing `ServiceManagement` and `AppKit`, wrapping `SMAppService.mainApp` and handling `openSystemSettings()`.
3. **Application & State Layer**: `PreferencesStore` coordinates the login item lifecycle, maintaining `@Published var launchAtLogin` and `@Published var launchAtLoginStatus`. It listens to `NSApplication.didBecomeActiveNotification` to trigger auto-synchronization when returning from System Settings.
4. **UI Layer**: `GeneralSettingsView` binds directly to `PreferencesStore.launchAtLoginBinding`, rendering an inline notification banner and action button if `.requiresApproval` or error occurs.
5. **Testing Layer**: `MockLaunchAtLoginManager` simulates all status branches, transitions, exceptions, and settings openings with zero external system side effects.

---

## 2. File Modification & Creation Inventory

| File                                                                | Layer          | Action     | Responsibility                                                 |
| :------------------------------------------------------------------ | :------------- | :--------- | :------------------------------------------------------------- |
| `FlowSnap/Domain/Services/LaunchAtLoginManaging.swift`              | Domain         | **NEW**    | Contract protocol & `LaunchAtLoginStatus` enum                 |
| `FlowSnap/Infrastructure/Services/SystemLaunchAtLoginManager.swift` | Infrastructure | **NEW**    | `SMAppService.mainApp` wrapper + System Settings opener        |
| `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift`        | Infrastructure | **MODIFY** | Injects manager, performs two-way sync & handles state updates |
| `FlowSnap/UI/Settings/GeneralSettingsView.swift`                    | UI             | **MODIFY** | Enhances Launch Policy card with status badge & action button  |
| `FlowSnap/App/AppDependencies.swift`                                | App            | **MODIFY** | Centralizes DI for `LaunchAtLoginManaging`                     |
| `FlowSnapTests/Mocks/MockLaunchAtLoginManager.swift`                | Tests          | **NEW**    | Mock implementation for test doubles                           |
| `FlowSnapTests/Infrastructure/LaunchAtLoginManagerTests.swift`      | Tests          | **NEW**    | Unit test suite covering all AC scenarios                      |
| `adr/0017-launch-at-login-sm-app-service.md`                        | Architecture   | **NEW**    | Immutable ADR documenting SMAppService decision                |

---

## 3. Concurrency & Thread Safety

- `LaunchAtLoginManaging` is declared as `Sendable`.
- `PreferencesStore` is isolated to `@MainActor`. All published property updates happen strictly on the main runloop.
- `NotificationCenter.default.addObserver` for `didBecomeActiveNotification` dispatches updates safely to `@MainActor`.
