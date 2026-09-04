# Functional Specification: Universal Always-On-Top Pinning & Stage Manager Launch Co-existence (US-SNAP-021)

## 1. Functional Requirements (`REQ-PIN-###`)

- **`REQ-PIN-001` (Toggle Pin State)**:
  - The system SHALL allow the user to toggle the pinning state of the currently focused window via a global hotkey (`⌃⌥P`) or Menu Bar status item.
  - If the focused window is currently unpinned, the system SHALL pin it, append its identity to `pinnedWindows` at the top of the LIFO order, and trigger visual feedback.
  - If the focused window is already pinned, the system SHALL unpin it, remove it from `pinnedWindows`, and restore standard OS window layering.
  - _Derived from_: `US-SNAP-021` (AC 1), `ASM-PIN-001`, `BR-PIN-001`.

- **`REQ-PIN-002` (Dynamic LIFO Z-Stacking)**:
  - The system SHALL support an unlimited number of concurrently pinned windows.
  - Pinned windows SHALL always be kept in a higher visual layering plane than non-pinned windows.
  - When multiple windows are pinned, the most recently focused or pinned window SHALL be placed above earlier pinned windows according to a Last-In-First-Out (LIFO) order.
  - _Derived from_: `US-SNAP-021` (AC 2, AC 3), `ASM-PIN-001`, `BR-PIN-002`.

- **`REQ-PIN-003` (Active Re-assertion Coordination)**:
  - When the user activates or focuses an unpinned background application (observed via `NSWorkspace.didActivateApplicationNotification` or `kAXFocusedWindowChangedNotification`), `WindowPinningCoordinator` SHALL re-assert all pinned windows from bottom to top of the LIFO stack using `kAXRaiseAction` (`AXUIElementPerformAction(element, kAXRaiseAction)`).
  - The system SHALL NEVER invoke `activate()` or steal keyboard/text focus from the underlying application during re-assertion.
  - _Derived from_: `US-SNAP-021` (AC 2), `ASM-PIN-001`, `BR-PIN-003`.

- **`REQ-PIN-004` (System Modal Safety & Exemption)**:
  - The system SHALL detect if the active window belongs to critical macOS system security services (such as `com.apple.SecurityAgent`, `com.apple.CoreAuthUI`, Touch ID, Keychain, or modal permission dialogs).
  - If a system modal is active, the system SHALL suspend re-assertion until the modal dialog is dismissed, preventing security dialogs from being obscured.
  - _Derived from_: `US-SNAP-021` (AC 5), `BR-PIN-004`, `RISK-PIN-002`.

- **`REQ-PIN-005` (Local Space Scoping)**:
  - Pinned windows SHALL remain strictly localized to the Desktop Space where they were pinned.
  - Pinned windows SHALL NOT automatically follow the user or stick across Desktop Spaces when the user switches spaces.
  - _Derived from_: `US-SNAP-021` (AC 4), `BR-PIN-005`.

- **`REQ-PIN-006` (Stage Manager Launch Co-existence)**:
  - When Stage Manager is enabled (`isStageManagerEnabled == true`) and `stageManagerLaunchCoexistenceEnabled == true`, the system SHALL intercept newly launched applications via `NSWorkspace.didLaunchApplicationNotification`.
  - The system SHALL snapshot all visible windows on the active Stage prior to app presentation.
  - Using `ApplicationObserving`, the system SHALL wait for the new application's first window creation (`kAXWindowCreatedNotification`) with a 5.0-second timeout.
  - Upon window appearance, the system SHALL perform coordinated `kAXRaiseAction` calls across the previous Stage windows, merging the newly launched window and existing windows onto the active Stage without sidebar ejection.
  - _Derived from_: `US-SNAP-021` (AC 6), `ASM-PIN-002`, `BR-PIN-006`.

- **`REQ-PIN-007` (Automatic Window Lifecycle Cleanup)**:
  - The system SHALL listen for `NSWorkspace.didTerminateApplicationNotification` and immediately remove any pinned windows belonging to terminated processes.
  - If a `kAXRaiseAction` or query returns `kAXErrorInvalidUIElement`, the system SHALL automatically purge the dead window record from `pinnedWindows`.
  - _Derived from_: `BR-PIN-007`, `RISK-PIN-003`.

- **`REQ-PIN-008` (HUD Feedback & Menu Bar Synchronization)**:
  - The system SHALL trigger a 1.0-second HUD Toast on toggle action (e.g. `📌 Pinned [AppName]` or `Bỏ ghim [AppName]`).
  - `MenuBarViewModel` SHALL display the active pinned window count and provide an interactive dropdown showing each pinned window with individual and bulk unpin controls.
  - _Derived from_: `US-SNAP-021` (AC 8), `ASM-PIN-003`, `BR-PIN-008`.

- **`REQ-PIN-009` (Settings & Shortcut Customization)**:
  - The system SHALL expose a toggle in `PreferencesStore` (`stageManagerLaunchCoexistenceEnabled`, default: `true`) editable via `SettingsView`.
  - The global hotkey for `ShortcutAction.togglePinFocusedWindow` SHALL default to `⌃⌥P` and be customizable via `ShortcutRecorderField`.
  - _Derived from_: `US-SNAP-021` (AC 7).

---

## 2. Acceptance Scenarios

### `US-SNAP-021-01`: Pin & Unpin Focused Window via Shortcut

- **Given**: Window A (TextEdit, ID 101) has focus.
- **When**: User presses `⌃⌥P`.
- **Then**: Window A is added to `WindowPinningCoordinator.pinnedWindows`.
- **And**: HUD Toast displays "Pinned TextEdit" for 1.0s.
- **When**: User presses `⌃⌥P` again while Window A is focused.
- **Then**: Window A is removed from `pinnedWindows` and HUD Toast displays "Unpinned TextEdit".

### `US-SNAP-021-02`: LIFO Z-Stacking across Multiple Pinned Windows

- **Given**: Window A (ID 101) is pinned.
- **When**: User focuses Window B (ID 102) and presses `⌃⌥P`.
- **Then**: Both Window A and Window B are pinned.
- **And**: Window B is positioned at the top of the pinned LIFO stack.
- **When**: User clicks Window C (unpinned background window).
- **Then**: Window A is raised via `kAXRaiseAction`, then Window B is raised via `kAXRaiseAction`.
- **And**: Window C remains focused, while Window B is on top of Window A, and both are on top of Window C.

### `US-SNAP-021-03`: Stage Manager Launch Co-existence on App Open

- **Given**: Stage Manager is enabled and launch co-existence is active.
- **And**: Active Stage contains App X and App Y.
- **When**: User launches App Z from Spotlight.
- **Then**: System snapshots [App X, App Y], observes App Z launch until window creation, and raises [App X, App Y] onto the stage.
- **And**: App Z joins the current Stage alongside App X and App Y without pushing them to the sidebar strip.
