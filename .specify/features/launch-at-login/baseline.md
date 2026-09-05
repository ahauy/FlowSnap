# Domain Baseline: Launch FlowSnap at Login (US-SNAP-024)

> **Status**: SIGNED-OFF v1.0  
> **Feature**: `launch-at-login`  
> **Epic**: Sprint 7: Launch Automation & System Preferences  
> **Author**: Business Analyst (BA) Pipeline  
> **Date**: 2026-09-05

---

## 1. Executive Summary

FlowSnap is a native macOS productivity tool that must run continuously in the menu bar to intercept global window-snapping hotkeys. This feature integrates Apple's modern `SMAppService.mainApp` API (macOS 13+ ServiceManagement) to provide reliable automatic launch at user login, replacing inert `UserDefaults` storage with real two-way system state synchronization, approval detection, and robust error recovery.

---

## 2. Key Business Rules

1. **`BR-LAL-001` (System Single Source-of-Truth)**: FlowSnap derives its login item status directly from `SMAppService.mainApp.status` rather than unverified local cache.
2. **`BR-LAL-002` (Explicit Intent Toggle)**: Enabling the toggle calls `register()`. On success, `launchAtLogin` publishes `true`. On failure, the error is handled and `launchAtLogin` reverts to `false`.
3. **`BR-LAL-003` (Clean Deregistration)**: Disabling the toggle calls `unregister()`, returning status to `.notRegistered`.
4. **`BR-LAL-004` (Two-Way Synchronization)**: System login item status is polled and synchronized on store init, Settings appear, and app activation (`didBecomeActiveNotification`).
5. **`BR-LAL-005` (Approval Required Affordance)**: When status is `.requiresApproval`, the UI displays an informative status and a button to open macOS System Settings directly.
6. **`BR-LAL-006` (Zero Crash in Development)**: Uninstalled or unsigned debug builds reporting `.notFound` or registration errors are handled safely without crashing.

---

## 3. Finite State Machine

- `notRegistered` ──(register)──► `enabled`
- `enabled` ──(unregister)──► `notRegistered`
- `*` ──(external change / policy)──► `requiresApproval`
- `requiresApproval` ──(system approve + sync)──► `enabled`
- `register error` ──► `error(message)`

---

## 4. Scope Boundaries

- **In-Scope**:
  - `LaunchAtLoginManaging` protocol in Domain.
  - `SystemLaunchAtLoginManager` in Infrastructure wrapping `SMAppService.mainApp`.
  - `MockLaunchAtLoginManager` in Tests for unit testing.
  - Integration with `PreferencesStore`.
  - Dynamic `GeneralSettingsView` launch policy card with status indicators.
- **Out-of-Scope**:
  - Legacy `SMLoginItemSetEnabled` or helper launcher bundles.
  - Automatic silent registration without user consent.
