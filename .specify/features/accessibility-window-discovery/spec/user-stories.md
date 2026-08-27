# User Stories: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Feature**: `accessibility-window-discovery`
- **Epic**: `EPIC-01: Accessibility Permission & Focused Window Discovery`
- **Sprint**: Sprint 1

---

### US-SNAP-001a: Accessibility Permission Verification & System Settings Routing

**As a** FlowSnap user  
**I want** FlowSnap to verify its macOS Accessibility permissions and provide a one-click button to System Settings  
**So that** I can grant necessary OS privileges without confusion or manually searching through macOS settings menus.

**Derived from**: BR-SNAP-001, ASM-SNAP-001  
**Traces to**: REQ-SNAP-001

#### Acceptance Criteria

- **Scenario 1 (Happy Path - Already Trusted)**
  - **Given** FlowSnap has been granted Accessibility permission in macOS Settings
  - **When** `AccessibilityService.isTrusted` is queried
  - **Then** it returns `true` and no prompt alert is shown.
- **Scenario 2 (Permission Not Granted)**
  - **Given** FlowSnap does NOT have Accessibility permission
  - **When** `AccessibilityService.isTrusted` is queried
  - **Then** it returns `false`.
- **Scenario 3 (Deep Link to System Settings)**
  - **Given** FlowSnap is untrusted
  - **When** user triggers permission request or clicks "Open Settings"
  - **Then** macOS System Settings opens directly to `Privacy & Security > Accessibility`.
- **Scenario 4 (Dynamic Permission Recovery)**
  - **Given** FlowSnap was untrusted while running
  - **When** user enables FlowSnap in System Settings and switches back to FlowSnap
  - **Then** FlowSnap automatically detects `isTrusted == true` without requiring an application relaunch.

---

### US-SNAP-001b: Active Focused Window Detection & Metadata Extraction

**As a** window management engine  
**I want** to query the frontmost application and read its focused window attributes  
**So that** FlowSnap can obtain an accurate geometric and process identity snapshot.

**Derived from**: BR-SNAP-001, BR-SNAP-003, BR-SNAP-004, ASM-SNAP-003  
**Traces to**: REQ-SNAP-002

#### Acceptance Criteria

- **Scenario 1 (Happy Path - Focused Standard Window)**
  - **Given** an application (e.g. TextEdit or Safari) has an active, focused standard window
  - **When** `AccessibilityService.focusedWindow()` is invoked
  - **Then** it returns a `ManagedWindow` with correct `pid`, `title`, non-empty `frame: CGRect`, and `isResizable: true`.
- **Scenario 2 (Edge Case - Headless or Missing Window Title)**
  - **Given** an active application window has an empty `kAXTitleAttribute`
  - **When** `AccessibilityService.focusedWindow()` is invoked
  - **Then** `ManagedWindow.title` falls back to `NSRunningApplication.localizedName` rather than an empty string.
- **Scenario 3 (Edge Case - Frontmost Application Has No Windows)**
  - **Given** the frontmost application has closed or minimized all its windows
  - **When** `AccessibilityService.focusedWindow()` is invoked
  - **Then** it returns `nil` safely without throwing an unhandled exception or crashing.

---

### US-SNAP-001c: Window Classification & Non-Standard Window Isolation

**As a** snap layout coordinator  
**I want** to classify windows into `WindowKind` (.normal, .dialog, .sheet, .system, .unsupported)  
**So that** FlowSnap only manipulates valid resizable document/app windows and avoids breaking dialogs or system panels.

**Derived from**: BR-SNAP-002, ASM-SNAP-002  
**Traces to**: REQ-SNAP-003

#### Acceptance Criteria

- **Scenario 1 (Standard Window Classification)**
  - **Given** a window with `kAXRoleAttribute == kAXWindowRole` and `kAXSubroleAttribute == kAXStandardWindowSubrole`
  - **When** the window is inspected
  - **Then** its `kind` is `.normal` and `isResizable` is `true`.
- **Scenario 2 (Modal Dialog & Sheet Classification)**
  - **Given** an open file/save dialog or sheet
  - **When** the window is inspected
  - **Then** its `kind` is `.dialog` or `.sheet` and it is flagged as not eligible for standard snap operations.
- **Scenario 3 (System Elements Exclusion)**
  - **Given** a system element (Spotlight search or Menubar extra) is focused
  - **When** the window is inspected
  - **Then** its `kind` is `.system` or `.unsupported`.
