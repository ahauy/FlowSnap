# 06 - User Stories: Launch FlowSnap at Login (US-SNAP-024)

- **Feature**: Launch FlowSnap at Login Integration
- **Story ID**: `US-SNAP-024`
- **Slug**: `launch-at-login`
- **Date**: 2026-09-05
- **Status**: Complete

---

## User Stories & Acceptance Criteria

### `US-LAL-001`: User registers FlowSnap to launch at login

**As a** Mac user who relies on FlowSnap for window management  
**I want** FlowSnap to start automatically whenever I log in to macOS  
**So that** my window snapping hotkeys and layouts are immediately available without manual intervention.

- **Scenario 1 (Happy Path - Registration)**:
  - **Given** FlowSnap is not currently registered as a login item (status is `.notRegistered`)
  - **When** I toggle "Launch FlowSnap at login" to ON in Settings > General
  - **Then** `LaunchAtLoginManaging.register()` is invoked
  - **And** the status becomes `.enabled`
  - **And** the toggle remains ON.

---

### `US-LAL-002`: User unregisters FlowSnap from launch at login

**As a** Mac user  
**I want** to disable automatic startup  
**So that** FlowSnap does not launch automatically when I log in if I prefer manual control.

- **Scenario 1 (Happy Path - Unregistration)**:
  - **Given** FlowSnap is currently registered as a login item (status is `.enabled`)
  - **When** I toggle "Launch FlowSnap at login" to OFF in Settings > General
  - **Then** `LaunchAtLoginManaging.unregister()` is invoked
  - **And** the status becomes `.notRegistered`
  - **And** the toggle remains OFF.

---

### `US-LAL-003`: Two-way status synchronization with macOS System Settings

**As a** Mac user  
**I want** FlowSnap to accurately reflect changes made outside the app (in macOS System Settings > Login Items)  
**So that** the UI never displays a misleading state.

- **Scenario 1 (External status change detection)**:
  - **Given** FlowSnap was enabled as a login item
  - **When** the user disables or removes FlowSnap in macOS System Settings > General > Login Items
  - **And** FlowSnap receives focus (`NSApplication.didBecomeActiveNotification`) or General Settings appears
  - **Then** FlowSnap refreshes its status from `LaunchAtLoginManaging.currentStatus()`
  - **And** the toggle updates to reflect the actual system state.

---

### `US-LAL-004`: Handling `.requiresApproval` and navigating to System Settings

**As a** Mac user whose organization or system settings requires explicit approval for login items  
**I want** FlowSnap to notify me if my login item needs approval  
**So that** I can easily approve it in macOS System Settings.

- **Scenario 1 (Approval Required State)**:
  - **Given** macOS sets the status of FlowSnap to `.requiresApproval`
  - **When** I view Settings > General > Launch Policy
  - **Then** a warning indicator explains that approval is required in macOS System Settings
  - **And** an "Open macOS System Settings" button is provided
  - **When** I click the button
  - **Then** macOS System Settings opens to the Login Items pane (`x-apple.systempreferences:com.apple.LoginItems-Settings.extension`).

---

### `US-LAL-005`: Safe failure handling in development / uninstalled environments

**As a** developer or tester running FlowSnap from Xcode  
**I want** registration errors or `.notFound` status to be handled gracefully  
**So that** the application does not crash or throw unhandled exceptions.

- **Scenario 1 (Registration throws or returns `.notFound`)**:
  - **Given** FlowSnap is running from an uninstalled path where `SMAppService.mainApp.register()` throws
  - **When** the registration fails
  - **Then** the error is caught gracefully
  - **And** status is set to `.error(message)` or `.notFound`
  - **And** the toggle reverts to OFF without causing an app crash.
