# Specification: Per-App Window Policies & Smart Floating Stack (US-WORK-014)

- **Feature Slug**: `per-app-rules-floating-stack`
- **Specification Version**: 1.0.0
- **Traceability**: Derived from `docs/PRODUCT_BACKLOG_ROADMAP.md` (EPIC 12 / US-WORK-014) & `01-elicitation.md`

---

## 1. Functional Requirements

### REQ-POLICY-001: Per-App Rule Management & Priority Precedence

- **Description**: The system must maintain a registry of per-app window policies identified by macOS `bundleIdentifier`.
- **Derived from**: `BR-POLICY-001`, `ASM-POLICY-001`
- **Details**:
  - When resolving the policy for a window, `WindowPolicyManager` checks if an `AppPolicyRule` exists for `window.bundleIdentifier`.
  - If a rule exists, its specific `policy` is applied.
  - If no rule is configured, `defaultPolicy` (`.currentSpace`) is applied.
  - Rules are stored and loaded from `PreferencesStore`.

### REQ-POLICY-002: Floating Window Layout Exemption

- **Description**: Windows belonging to applications configured with `.floating` must remain untouched by grid layout operations.
- **Derived from**: `BR-POLICY-002`, `ASM-POLICY-001`
- **Details**:
  - When applying snap operations, workspace restore, or automatic split-screen calculations, windows of floating applications are excluded from candidate resizing lists.
  - The window retains its user-placed position and size.

### REQ-POLICY-003: Clamped Display-Aware Position Restoration

- **Description**: Windows configured with `.rememberPosition` must restore their last saved frame, clamped to the active display bounds.
- **Derived from**: `BR-POLICY-003`, `ASM-POLICY-002`
- **Details**:
  - `RememberedFrameStore` records the `CGRect` of a window upon dismissal/close.
  - Upon window appearance, the saved frame is retrieved and clamped to ensure:
    - Minimum 80% visibility within `display.visibleFrame`.
    - No clipping into the Menu Bar or Dock.
    - Width and height do not exceed display visible bounds.
  - Clamped coordinates are applied via `AccessibilityService.setFrame`.

### REQ-POLICY-004: Assigned Canonical Layout Zone

- **Description**: Windows configured with `.assignedLayout(LayoutZone)` must automatically snap to the assigned zone upon creation.
- **Derived from**: `BR-POLICY-005`, `ASM-POLICY-003`
- **Details**:
  - Supported zones: `.leftHalf`, `.rightHalf`, `.topHalf`, `.bottomHalf`, `.maximize`, `.topLeft`, `.topRight`, `.bottomLeft`, `.bottomRight`, `.leftTwoThirds`, `.rightOneThird`.
  - Target frame is computed by `LayoutEngine.calculateFrame` for the target display's `visibleFrame` and applied via `AccessibilityService.setFrame`.

### REQ-POLICY-005: Smart Focus Restoration on Floating Dismissal

- **Description**: Closing or dismissing a floating window automatically returns focus to the underlying active window.
- **Derived from**: `BR-POLICY-004`, `ASM-POLICY-001`
- **Details**:
  - `SmartFocusStack` records the active window history.
  - When a floating application closes or is hidden, the previous valid window in the stack is brought to focus via `AccessibilityService.setFocus`.

### REQ-POLICY-006: Settings Application Rules Management UI

- **Description**: The Settings window must offer an intuitive tab for configuring per-app rules.
- **Derived from**: `01-elicitation.md`
- **Details**:
  - Displays configured rules with app icon, name, bundleID, and policy dropdown.
  - Provides an "Add Application" flow allowing selection from running apps or installed apps.
  - Allows removing and editing existing rules with immediate persistence.

---

## 2. User Stories & Acceptance Scenarios

### US-WORK-014-01: App-Specific Rule Precedence

- **Given** an application with bundle ID `"com.microsoft.VSCode"` is assigned policy `.assignedLayout(.leftTwoThirds)`
- **And** the default system policy is `.currentSpace`
- **When** VS Code creates a new window
- **Then** `WindowPolicyManager` resolves the policy as `.assignedLayout(.leftTwoThirds)`
- **And** repositions the window to the left 70% zone of the current display.

### US-WORK-014-02: Floating Window Immunity & Focus Restoration

- **Given** Telegram (`"ru.keepcoder.Telegram"`) is configured with `.floating`
- **And** a Safari window is currently focused and tiled on the screen
- **When** Telegram is activated and opened on top of Safari
- **Then** Safari's position and size remain completely unchanged
- **When** Telegram is closed or hidden
- **Then** focus automatically returns to the Safari window.

### US-WORK-014-03: Remembered Position Multi-Monitor Clamping

- **Given** an app (`"com.spotify.client"`) was previously closed at position `(X: 2000, Y: 100, W: 800, H: 600)` on an external 4K monitor
- **When** the external monitor is disconnected and the app is reopened on a 1440x900 laptop screen
- **Then** the window frame is clamped inside the 1440x900 visible frame
- **And** appears fully visible on screen rather than lost in coordinates > 1440.

### US-WORK-014-04: Reactive Application Rules Configuration UI

- **Given** the user opens Settings > Applications tab
- **When** the user clicks "Add Application" and selects an application
- **And** selects policy "Floating"
- **Then** the rule is saved immediately to `PreferencesStore`
- **And** subsequent windows of that application adopt the `.floating` policy.
