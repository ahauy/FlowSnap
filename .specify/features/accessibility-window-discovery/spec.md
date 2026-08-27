# Feature Specification: Accessibility & Focused Window Discovery (US-SNAP-001)

- **Feature**: `accessibility-window-discovery`
- **Slug**: `accessibility-window-discovery`
- **Epic**: `EPIC-01: Accessibility Permission & Focused Window Discovery`
- **Target Sprint**: Sprint 1
- **Status**: Ready for Planning
- **Derived from**: [baseline.md](baseline.md) (SIGNED-OFF v1.0)

---

## 1. Feature Overview

FlowSnap is a native macOS window management utility that enables instant window snapping and workspace restoration. To interact with third-party application windows without private APIs, FlowSnap relies on the macOS Accessibility API (`AXUIElement`).

This feature implements the foundational accessibility and window discovery infrastructure:

1. Detecting whether FlowSnap has been granted Accessibility trust (`AXIsProcessTrustedWithOptions`) and guiding untrusted users via a direct link to System Settings, automatically detecting when permission is granted without requiring an app relaunch.
2. Querying the focused window of the frontmost application (`kAXFocusedWindowAttribute`) and safely extracting its geometric coordinates (`kAXPositionAttribute`, `kAXSizeAttribute`), process ID, bundle identifier, and window title with robust fallbacks.
3. Classifying windows into semantic `WindowKind` categories (`.normal`, `.dialog`, `.sheet`, `.system`, `.unsupported`) so subsequent snap operations only touch resizable standard application windows.

---

## 2. Functional Requirements

### **REQ-SNAP-001: Accessibility Trust & Recovery Routing**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-SNAP-001`, `ASM-SNAP-001`, `US-SNAP-001a`
- The system must provide a non-blocking method `isTrusted -> Bool` checking `AXIsProcessTrustedWithOptions(nil)`.
- If untrusted, the system must provide `openSystemSettings()` routing directly to `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
- The system must observe `NSApplication.didBecomeActiveNotification` and poll every 1s while active to detect when trust is granted without restarting.

### **REQ-SNAP-002: Focused Window Detection & Metadata Extraction**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-SNAP-001`, `BR-SNAP-003`, `BR-SNAP-004`, `ASM-SNAP-003`, `US-SNAP-001b`
- The system must query `NSWorkspace.shared.frontmostApplication` and obtain its `AXUIElement` representation.
- The system must read `kAXFocusedWindowAttribute`. If no window is active/open, it must return `nil` safely.
- The system must extract `kAXPositionAttribute` and `kAXSizeAttribute` into `CGRect`.
- If `kAXTitleAttribute` is empty or missing, the system must fallback to `NSRunningApplication.localizedName` or `"Unknown Window"`.

### **REQ-SNAP-003: Window Kind Semantic Classification**

- **Priority**: Must-Have (P0)
- **Derived from**: `BR-SNAP-002`, `ASM-SNAP-002`, `US-SNAP-001c`
- The system must classify windows based on `kAXRoleAttribute` and `kAXSubroleAttribute`:
  - `.normal`: `kAXWindowRole` + `kAXStandardWindowSubrole` with resizable size.
  - `.dialog`: `kAXWindowRole` + `kAXDialogSubrole` or `kAXSystemDialogSubrole`.
  - `.sheet`: `kAXSheetRole`.
  - `.system`: Menubar, Dock, Spotlight, or Notification Center elements.
  - `.unsupported`: Elements lacking geometric or settable attributes.

---

## 3. User Scenarios & Acceptance Criteria

### Scenario 1: Verify Trusted Permission

- **Given** macOS Accessibility permission is granted to FlowSnap
- **When** `AccessibilityService.isTrusted` is evaluated
- **Then** it returns `true`.

### Scenario 2: Handle Untrusted State & System Routing

- **Given** macOS Accessibility permission is NOT granted
- **When** the user triggers permission check or clicks "Open Settings"
- **Then** `isTrusted` is `false`, and macOS opens `Privacy & Security > Accessibility`.

### Scenario 3: Query Active Focused Standard Window

- **Given** a standard application (e.g. Safari) is frontmost with an active window
- **When** `focusedWindow()` is called
- **Then** a `ManagedWindow` is returned with `kind == .normal`, valid frame coordinates, and `isResizable == true`.

### Scenario 4: Query Frontmost App with No Windows

- **Given** the active application has closed all its windows
- **When** `focusedWindow()` is called
- **Then** it returns `nil` safely without error or crash.

### Scenario 5: Filter Modal Sheets & Dialogs

- **Given** an open file dialog or alert sheet is focused
- **When** the window is inspected
- **Then** `kind` is `.dialog` or `.sheet` and marked non-snappable.

---

## 4. Success Criteria

1. **Latency**: Focused window discovery latency P95 < 10ms.
2. **Reliability**: 0 unhandled AX exceptions, crashes, or dangling CoreFoundation pointers.
3. **Accuracy**: 100% accurate classification between `.normal` vs non-standard windows.
4. **Test Coverage**: 100% unit test coverage for domain models, error handling, and mock accessibility service.
