# Functional Specification: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-019)

## 1. Requirements (`REQ-FSE-###`)

- **`REQ-FSE-001` (Three-Tier Escape Strategy)**:
  - The system SHALL attempt to exit macOS Native Full Screen for any window using a three-tier cascade:
    1. Tier 0: Direct `AXFullscreen` / `AXFullScreen = false` attribute write.
    2. Tier 1: Interactive press of the window's full screen button (`kAXFullScreenButtonAttribute` + `kAXPressAction`).
    3. Tier 2: Synthesized macOS full screen shortcut (`Control + Command + F`) via `CGEvent` to the target process PID.
  - _Derived from_: `US-WORK-019`, `ASM-FSE-001`, `BR-FSE-001`.

- **`REQ-FSE-002` (Fast-Path Optimization for Standard Cocoa Apps)**:
  - If Tier 0 succeeds, the system SHALL immediately complete the signal phase without querying the UI tree or dispatching keyboard events.
  - _Derived from_: `ASM-FSE-001`, `BR-FSE-001`.

- **`REQ-FSE-003` (Target Process Activation Prior to CGEvent)**:
  - When Tier 2 is triggered, the system SHALL activate the target application process using `NSRunningApplication.activate(options: [.activateIgnoringOtherApps])` and wait 50ms before posting the `⌃⌘F` keystroke sequence.
  - _Derived from_: `ASM-FSE-002`, `BR-FSE-002`, `RISK-FSE-002`.

- **`REQ-FSE-004` (Adaptive Transition Polling Loop)**:
  - After any escape tier sends its trigger signal, the system SHALL poll the target window's state every 100ms for up to 800ms.
  - If the window transitions out of full screen mode before 800ms, the system SHALL return immediately (early return).
  - _Derived from_: `ASM-FSE-003`, `BR-FSE-003`.

- **`REQ-FSE-005` (Non-Destructive Failure Resilience)**:
  - If all three tiers fail to exit full screen within the 800ms ceiling, the system SHALL log a diagnostic failure without throwing an unhandled error or interrupting other window placements in the workspace pass.
  - _Derived from_: `BR-FSE-004`, `RISK-FSE-003`.

- **`REQ-FSE-006` (Seam & Interface Integration)**:
  - The escape functionality SHALL be encapsulated behind `FullScreenEscapeCoordinating` and integrated into `AccessibilityServing.exitFullScreen`, `WindowManager.move`, and `WorkspaceManager+Restore`.
  - _Derived from_: `US-WORK-019`, `ADR-0012`.

---

## 2. User Stories & Acceptance Scenarios

### `US-WORK-019-01`: Standard Cocoa Native Window Escape (Safari / Finder / TextEdit)

- **Given**: A standard Cocoa window is in macOS Full Screen mode.
- **When**: FlowSnap initiates `exitFullScreen(window, element)`.
- **Then**: Tier 0 (`AXFullscreen = false`) succeeds within < 2ms.
- **And**: FlowSnap enters the adaptive polling loop and returns as soon as the space exit animation completes.

### `US-WORK-019-02`: Electron / Chromium Application Escape (VS Code / Brave / Antigravity)

- **Given**: An Electron window is in macOS Full Screen mode and returns `cannotComplete` on `AXFullscreen = false`.
- **When**: FlowSnap initiates `exitFullScreen(window, element)`.
- **Then**: Tier 0 fails, and FlowSnap cascades to Tier 1.
- **And**: FlowSnap queries `kAXFullScreenButtonAttribute` and executes `kAXPressAction`.
- **And**: The window exits full screen back to Desktop Space.

### `US-WORK-019-03`: Custom App Escape via Synthesized `⌃⌘F` Keystroke

- **Given**: A window is in Full Screen mode where attribute write fails and no AX Full Screen button element is present.
- **When**: FlowSnap initiates `exitFullScreen(window, element)`.
- **Then**: Tier 0 and Tier 1 fail, and FlowSnap cascades to Tier 2.
- **And**: FlowSnap activates the target application and posts `⌃⌘F` via `CGEvent` to the target PID.
- **And**: WindowServer triggers the full screen exit.

### `US-WORK-019-04`: Early Return via Adaptive Polling

- **Given**: An escape trigger has been sent to a window.
- **When**: The window exits full screen at 300ms.
- **Then**: FlowSnap detects the exit and terminates the wait at 300ms instead of waiting for the full 800ms ceiling.
