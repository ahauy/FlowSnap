# Functional Specification: Quake-Style Quick Scratchpad & Instant Window Toggle (US-SNAP-022)

## 1. Functional Requirements (`REQ-SCRATCH-###`)

- **`REQ-SCRATCH-001` (Assign & Detach Scratchpad Window)**:
  - The system SHALL allow the user to assign the currently focused window as the active Scratchpad via global shortcut (`ShortcutAction.assignScratchpad`, default: `Control + Option + Space`) or via the Menu Bar status item.
  - Upon assignment, the system SHALL store a `ScratchpadRecord` capturing the window's `CGWindowID`, `pid`, `bundleID`, `appName`, and `windowTitle`.
  - Assigning a new window SHALL immediately replace any previously assigned Scratchpad.
  - The system SHALL allow manual detaching of the Scratchpad via Menu Bar, transitioning state to `.unassigned`.
  - _Derived from_: `US-SNAP-022` (AC 1, AC 7), `BR-SCRATCH-001`, `ASM-SCRATCH-003`.

- **`REQ-SCRATCH-002` (Instant Summon & Zero-Shrink)**:
  - When the Scratchpad is hidden and the user triggers `ShortcutAction.toggleScratchpad` (default: `Option + Space`), the system SHALL:
    1. Snapshot the current frontmost application and focused window (`PreSummonFocus`).
    2. Raise the Scratchpad window to the frontmost layer using `kAXRaiseAction` (`AccessibilityServing.raise`).
    3. Activate the Scratchpad's owning application (`NSRunningApplication.activate(options: .activateIgnoringOtherApps)`).
  - The entire summon sequence SHALL complete within `< 50ms`.
  - The background application (e.g. Brave, VS Code) SHALL retain 100% of its size, position, and layout (Zero-Shrink).
  - _Derived from_: `US-SNAP-022` (AC 2, AC 4), `BR-SCRATCH-002`, `NFR-1`.

- **`REQ-SCRATCH-003` (Hybrid Dismiss Mechanism)**:
  - When the Scratchpad is visible and a dismiss event occurs (toggle shortcut, ESC key, or outside click):
    - If the Scratchpad application has only 1 open window: The system SHALL call `NSRunningApplication.hide()` to cleanly hide the process.
    - If the Scratchpad application has ≥ 2 open windows: The system SHALL NOT hide the entire application; instead, it SHALL demote the window layer, deactivate the application, and reactivate the previously focused application.
  - _Derived from_: `US-SNAP-022` (AC 3), `BR-SCRATCH-003`, `ASM-SCRATCH-001`.

- **`REQ-SCRATCH-004` (Accurate Pre-Summon Focus Restoration)**:
  - Upon dismissing the Scratchpad, the system SHALL restore keyboard and window focus to the application and window recorded in `PreSummonFocus`.
  - If the previously focused application has terminated or is unavailable, focus SHALL fall back gracefully to the next frontmost application managed by macOS.
  - Focus restoration SHALL complete within `< 50ms`.
  - _Derived from_: `US-SNAP-022` (AC 3), `BR-SCRATCH-004`, `ASM-SCRATCH-001`.

- **`REQ-SCRATCH-005` (Dual Dismiss Triggers — ESC & Click-Outside Blur)**:
  - The system SHALL dismiss the Scratchpad when the user presses `ESC`, provided that `dismissOnEsc == true` and the Scratchpad is the active key window.
  - The system SHALL dismiss the Scratchpad when the user clicks outside the window bounds, provided that `dismissOnBlur == true` in `PreferencesStore`.
  - The `ESC` monitor SHALL be local/conditional and SHALL NEVER intercept or consume `ESC` keystrokes destined for other applications.
  - _Derived from_: `US-SNAP-022` (AC 3, AC 6), `BR-SCRATCH-005`, `ASM-SCRATCH-002`.

- **`REQ-SCRATCH-006` (Safe Lifecycle Detach & Ghost Avoidance)**:
  - The system SHALL observe `NSWorkspace.didTerminateApplicationNotification`. If the terminated PID matches the assigned Scratchpad, the system SHALL automatically invoke `detachScratchpad()`.
  - If an AX operation returns `kAXErrorInvalidUIElement` during summon or state check, the system SHALL immediately purge the invalid record and transition to `.unassigned`.
  - _Derived from_: `BR-SCRATCH-006`, `ASM-SCRATCH-003`, `RISK-SCRATCH-002`.

- **`REQ-SCRATCH-007` (Stage Manager & Desktop Spaces Co-existence)**:
  - Summoning the Scratchpad SHALL occur directly on the active Desktop Space and active Stage without triggering macOS space transition animations.
  - _Derived from_: `US-SNAP-022` (AC 5), `BR-SCRATCH-007`.

- **`REQ-SCRATCH-008` (Menu Bar Status & Quake Actions)**:
  - `MenuBarViewModel` SHALL expose the current Scratchpad status (assigned app name, window title, visibility state).
  - `MenuBarView` SHALL render action buttons: "Triệu hồi / Ẩn Scratchpad (`⌥Space`)" and "Hủy gán Scratchpad" when assigned; or "Gán cửa sổ hiện tại làm Scratchpad (`⌃⌥Space`)" when unassigned.
  - _Derived from_: `US-SNAP-022` (AC 7), `BR-SCRATCH-008`.

- **`REQ-SCRATCH-009` (Settings & Shortcut Customization)**:
  - `PreferencesStore` SHALL persist:
    - `scratchpadDismissOnBlur: Bool` (default: `false`)
    - `scratchpadDismissOnEsc: Bool` (default: `true`)
    - `ShortcutAction.toggleScratchpad` key combo (default: `Option + Space`)
    - `ShortcutAction.assignScratchpad` key combo (default: `Control + Option + Space`)
  - `SettingsView` SHALL provide UI toggles for dismiss behaviors and key recording controls.
  - _Derived from_: `US-SNAP-022` (AC 6).

---

## 2. Acceptance Scenarios

### `US-SNAP-022-01`: Instant Assignment and Detach

- **Given**: iTerm2 window (ID 201) is active and focused.
- **When**: User presses `⌃⌥Space` or clicks "Gán cửa sổ hiện tại làm Scratchpad" in Menu Bar.
- **Then**: `ScratchpadCoordinator.state` becomes `.visible(record:)` with `appName == "iTerm2"`.
- **And**: Menu Bar displays "Scratchpad: iTerm2".
- **When**: User clicks "Hủy gán Scratchpad" in Menu Bar.
- **Then**: `ScratchpadCoordinator.state` becomes `.unassigned`.

### `US-SNAP-022-02`: Instant Summon with Zero-Shrink

- **Given**: Scratchpad is assigned to iTerm2 and currently hidden (`.hidden(record)`).
- **And**: Brave is active and occupying the entire screen at (0, 0, 1920, 1080).
- **When**: User presses `⌥Space`.
- **Then**: Pre-summon focus is recorded as Brave (PID 500, Window 100).
- **And**: iTerm2 is raised and activated within `< 50ms`.
- **And**: Brave frame remains exactly (0, 0, 1920, 1080).

### `US-SNAP-022-03`: Instant Dismiss and Focus Restoration

- **Given**: Scratchpad (iTerm2) is visible and frontmost.
- **And**: Pre-summon focus belongs to Brave.
- **When**: User presses `⌥Space` again (or presses `ESC`).
- **Then**: iTerm2 is hidden via `NSRunningApplication.hide()`.
- **And**: Brave immediately receives frontmost focus in `< 50ms`.
- **And**: `ScratchpadCoordinator.state` becomes `.hidden(record)`.

### `US-SNAP-022-04`: App Termination Auto-Detach

- **Given**: Scratchpad is assigned to Calculator (PID 600).
- **When**: User quits Calculator (`⌘Q`).
- **Then**: `NSWorkspace.didTerminateApplicationNotification` fires.
- **And**: `ScratchpadCoordinator` transitions to `.unassigned`.
- **And**: Menu Bar updates to "Chưa gán Scratchpad".
