# 01 - Elicitation Interview: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: Launch FlowSnap at Login Integration
- **Story ID**: `US-SNAP-024`
- **Slug**: `launch-at-login`
- **Date**: 2026-09-05
- **Status**: Completed & Confirmed

---

## 1. Context & Business Problem

FlowSnap is a background productivity utility that needs to be active as soon as the user logs in to macOS. Currently, `PreferencesStore` only maintains an inert boolean flag (`launchAtLogin`) in `UserDefaults`. Users must manually launch FlowSnap after every system reboot or login. Furthermore, if a user disables login items in macOS System Settings, the application has no awareness of this state change.

---

## 2. Interactive Interview Transcript

### Question 1: Migration & Authoritative Source-of-Truth

- **Context**: How should FlowSnap handle migration and synchronization between existing `UserDefaults` (`launchAtLogin`) and macOS `SMAppService.mainApp.status` on first launch?
- **Options Considered**:
  - _Option A (Recommended)_: System as authoritative source-of-truth: Adopt `SMAppService.status == .enabled` as actual state; do not trigger unexpected background registration prompts on launch.
  - _Option B_: Attempt automatic one-time migration: If legacy `launchAtLogin` in `UserDefaults` is `true` but system status is `.notRegistered`, automatically attempt `register()` once at app startup.
- **User Decision**: **Option A** — System `SMAppService.status` is the single source-of-truth. Do not make unprompted registration calls on startup.

### Question 2: UI Presentation for Approval Required & Development Environments

- **Context**: How should the UI in General Settings present the state when macOS requires user approval (`.requiresApproval`) or when running in an uninstalled/development environment (`.notFound`)?
- **Options Considered**:
  - _Option A (Recommended)_: Inline warning card with an "Open macOS System Settings" button directly below the toggle, plus clear status message when in development mode.
  - _Option B_: Display a modal alert dialog whenever the user turns on the toggle if approval is needed or if registration fails.
- **User Decision**: **Option A** — Inline warning card with direct link button (`x-apple.systempreferences:com.apple.LoginItems-Settings.extension`), adhering to macOS HIG without intrusive popups.

---

## 3. Explicit Assumptions (ASM)

- `ASM-LAL-001`: FlowSnap targets macOS 14.0+ where `SMAppService.mainApp` is fully supported and preferred over deprecated `SMLoginItemSetEnabled` or helper launcher bundles.
- `ASM-LAL-002`: Development builds running from Xcode DerivedData or without Developer ID signing may return `SMAppService.Status.notFound` or throw when registering. The application will catch this gracefully, expose a diagnostic state, and avoid crashing.
- `ASM-LAL-003`: Two-way status synchronization will trigger on: (1) `PreferencesStore` initialization, (2) `GeneralSettingsView` `.onAppear`, and (3) `NSApplication.didBecomeActiveNotification`.
