# Functional Specification: Stage Manager Multi-Window Auto-Grouping (US-WORK-017)

## 1. Functional Requirements (`REQ-SMA-###`)

- **`REQ-SMA-001` (Stage Manager State Detection)**:
  - The system SHALL query the system preference `com.apple.WindowManager` key `GloballyEnabled` via `StageManagerDetecting` to determine whether macOS Stage Manager is currently active.
  - The query SHALL be performed dynamically on each workspace restore pass without permanent caching, ensuring immediate adaptation when the user toggles Stage Manager in Control Center.
  - If preference reading fails or returns an unexpected format, the system SHALL default to `false` (standard restore).
  - _Derived from_: `US-WORK-017`, `ASM-SMA-003`, `BR-SMA-001`.

- **`REQ-SMA-002` (Anchor App Activation)**:
  - When Stage Manager is active (`isStageManagerEnabled == true`), the system SHALL designate the first placement in `workspace.orderedPlacements` as the **Anchor App**.
  - The system SHALL move the Anchor App to its designated frame and activate it using `launcher.reveal(bundleID:)` (which invokes `NSRunningApplication.activate(options: [.activateAllWindows])`).
  - _Derived from_: `US-WORK-017`, `ASM-SMA-001`, `BR-SMA-002`.

- **`REQ-SMA-003` (Secondary Window Placement & `kAXRaiseAction` Staging)**:
  - When Stage Manager is active, for all placements after the Anchor App (`placements.dropFirst()`):
    - The system SHALL unhide the application if it is hidden (`app.unhide()`).
    - The system SHALL move each window to its target layout frame via `WindowManager.move()`.
    - The system SHALL raise each placed window to the current Stage using `AccessibilityServing.raise(element:)` (which sends `kAXRaiseAction` via `AXUIElementPerformAction`).
    - The system SHALL STRICTLY NOT invoke `app.activate()` or `launcher.reveal()` for secondary placements, preventing macOS WindowServer from initiating a Stage swap.
  - _Derived from_: `US-WORK-017`, `ASM-SMA-001`, `BR-SMA-003`.

- **`REQ-SMA-004` (Primary Window Keyboard Focus Lock)**:
  - After all windows in the workspace have been moved and staged, the system SHALL send a final `raise` command to the primary window of the Anchor App.
  - This ensures that primary keyboard focus is firmly retained by the user's primary application (e.g. Code editor).
  - _Derived from_: `ASM-SMA-002`, `BR-SMA-004`.

- **`REQ-SMA-005` (Graceful Fallback on Inactive Stage Manager)**:
  - When Stage Manager is inactive (`isStageManagerEnabled == false`), the system SHALL execute the standard restore workflow (calling `launcher.reveal()` sequentially for all placed applications).
  - _Derived from_: `BR-SMA-005`.

- **`REQ-SMA-006` (Accessibility Serving Raise Interface)**:
  - The `AccessibilityServing` protocol SHALL expose `raise(element: AXUIElement) -> Bool` and `raise(window: ManagedWindow) -> Bool` to abstract `kAXRaiseAction` behind a mockable seam.
  - _Derived from_: `BR-SMA-003`, `ADR-0013`.

---

## 2. Acceptance Scenarios

### `US-WORK-017-01`: Multi-Window Restore with Stage Manager Active

- **Given**: Stage Manager is enabled (`GloballyEnabled = 1`).
- **And**: A Workspace has 2 placements: App A (VS Code, 60% Left) and App B (Chrome, 40% Right).
- **When**: `WorkspaceManager.restore(workspace:)` is executed.
- **Then**: App A is moved to 60% Left and activated via `launcher.reveal()`.
- **And**: App B is moved to 40% Right and brought to the active stage via `kAXRaiseAction`.
- **And**: `app.activate()` is NOT called for App B.
- **And**: Both App A and App B are visible side-by-side on the same Stage.
- **And**: Keyboard focus is on App A's window.

### `US-WORK-017-02`: Multi-Window Restore with Stage Manager Inactive

- **Given**: Stage Manager is disabled (`GloballyEnabled = 0`).
- **And**: A Workspace has 2 placements: App A and App B.
- **When**: `WorkspaceManager.restore(workspace:)` is executed.
- **Then**: Both App A and App B are moved and revealed via `launcher.reveal()`.

### `US-WORK-017-03`: Single-App Workspace with Stage Manager Active

- **Given**: Stage Manager is enabled.
- **And**: A Workspace has only 1 placement: App A (Maximize).
- **When**: `WorkspaceManager.restore(workspace:)` is executed.
- **Then**: App A is moved and revealed as the sole Anchor App.

### `US-WORK-017-04`: Secondary App Hidden (Cmd+H)

- **Given**: Stage Manager is enabled.
- **And**: App B is currently hidden (`isHidden == true`).
- **When**: Workspace is restored.
- **Then**: App B is unhidden, repositioned, and raised via `kAXRaiseAction` without triggering a Stage swap.
