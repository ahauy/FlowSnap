# Functional Specification: Atomic Workspace Cross-Display Migration (US-DISP-017)

## 1. Functional Requirements (`REQ-MIG-###`)

- **`REQ-MIG-001` (Source & Target Display Resolution)**:
  - The system SHALL determine the source display (`sourceDisplay`) from the screen containing the current focused window's center, falling back to the current mouse cursor location (`NSEvent.mouseLocation`).
  - The system SHALL calculate the target display (`targetDisplay`) using `DisplayNavigating.nextDisplay` or `previousDisplay` based on the specified `MigrationDirection`.
  - If `displays.count <= 1` or `sourceDisplay.id == targetDisplay.id`, the migration SHALL return `.noOp(.singleDisplay)` with zero window displacement and no screen flicker.
  - _Derived from_: `US-DISP-017`, `BR-MIG-001`.

- **`REQ-MIG-002` (Active Workspace Resolution)**:
  - The system SHALL identify the active workspace on `sourceDisplay` by inspecting `WorkspaceManager.activeWorkspace` or matching visible managed windows against saved workspace configurations.
  - If no active workspace is detected on `sourceDisplay`, the migration SHALL return `.noOp(.noActiveWorkspace)` fail-soft.
  - _Derived from_: `US-DISP-017`, `BR-MIG-002`.

- **`REQ-MIG-003` (Proportional Geometric Frame Scaling)**:
  - The system SHALL scale each window frame belonging to the active workspace from `sourceDisplay.visibleFrame` to `targetDisplay.visibleFrame` using `RelativeFrameScaler.scale(frame:from:to:)`.
  - The relative spatial split ratios (e.g. 50/50, 70/30, 3-column) and collinear shared boundaries SHALL be proportionally preserved within `targetDisplay.visibleFrame`.
  - _Derived from_: `US-DISP-017`, `BR-MIG-003`, `US-DISP-015`.

- **`REQ-MIG-004` (Move Ordering & Stage Manager Cohesion)**:
  - When Stage Manager is active (`isStageManagerEnabled == true`):
    - The system SHALL move the Anchor window (first placement) to `targetDisplay` first and activate it.
    - The system SHALL apply a Staggered IPC delay (40ms) between subsequent window moves.
    - The system SHALL invoke `AccessibilityServing.raise(element:)` via `kAXRaiseAction` on secondary windows without calling `app.activate()`, preserving single Stage cohesion on `targetDisplay`.
  - When Stage Manager is inactive:
    - The system SHALL execute a 2-Phase Move Order: Phase 1 moves shrinking windows (target area <= source area), Phase 2 moves expanding windows (target area > source area), preventing WindowServer spatial clamping collisions.
  - _Derived from_: `US-DISP-017`, `BR-MIG-004`, `US-WORK-018`.

- **`REQ-MIG-005` (Post-Migration Focus & Divider Handoff)**:
  - The system SHALL warp the mouse cursor to the geometric center of the primary window on `targetDisplay` using `CursorWarping`.
  - The system SHALL re-assert keyboard focus on the primary window on `targetDisplay`.
  - The system SHALL transfer the active divider boundary (`AdaptiveDividerCoordinator`) to `targetDisplay` and invalidate divider overlays on `sourceDisplay`.
  - _Derived from_: `US-DISP-017`, `BR-MIG-005`.

- **`REQ-MIG-006` (Global Hotkey & Menu Dispatch)**:
  - The system SHALL register global hotkeys `⌃⌥⇧⌘→` (Move Workspace to Next Display) and `⌃⌥⇧⌘←` (Move Workspace to Previous Display).
  - The system SHALL expose corresponding `ShortcutAction` items (`.moveWorkspaceNextDisplay`, `.moveWorkspacePreviousDisplay`) and dispatch `WindowCommand.migrateWorkspace(direction)`.
  - _Derived from_: `US-DISP-017`, `ASM-MIG-005`.

---

## 2. Acceptance Scenarios

### `US-DISP-017-01`: 2-Window Migration to Next Display (Stage Manager OFF)

- **Given**: Two connected displays (Display 1 and Display 2), Stage Manager is OFF.
- **And**: A Workspace with 2 windows (Editor 60%, Browser 40%) is active on Display 1.
- **When**: User triggers `⌃⌥⇧⌘→` (`moveWorkspaceNextDisplay`).
- **Then**: Both windows are scaled via `RelativeFrameScaler` to Display 2.
- **And**: 2-phase move ordering is applied to prevent frame collisions.
- **And**: Mouse cursor is warped to Editor's center on Display 2.
- **And**: `AdaptiveDividerCoordinator` is re-anchored to Display 2.

### `US-DISP-017-02`: Multi-Window Migration with Stage Manager ON

- **Given**: Two connected displays, Stage Manager is ON (`GloballyEnabled = 1`).
- **And**: A Workspace with 2 windows is active on Display 1.
- **When**: User triggers `⌃⌥⇧⌘→`.
- **Then**: Window 1 is moved first to Display 2.
- **And**: After 40ms stagger delay, Window 2 is moved and raised via `kAXRaiseAction`.
- **And**: Both windows appear together on a single Stage on Display 2 without being pushed to the Stage Manager strip.

### `US-DISP-017-03`: Single Monitor Safe No-op

- **Given**: Only 1 display connected (`displays.count == 1`).
- **When**: User triggers `⌃⌥⇧⌘→` or `⌃⌥⇧⌘←`.
- **Then**: Migration returns `.noOp(.singleDisplay)` immediately without UI freeze or window movement.
