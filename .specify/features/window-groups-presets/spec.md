# Feature Specification: Window Groups & Workspace Presets (US-WORK-012)

**Feature Slug:** `window-groups-presets`  
**Feature Branch:** `feat/window-groups-presets`  
**Baseline:** `.specify/features/window-groups-presets/baseline.md` (SIGNED-OFF v1.0)  
**Status:** Approved Specification — Ready for Implementation  
**Created:** 2026-09-01

---

## 1. Technical Scope & Boundaries

### In Scope (Must-Have / Should-Have)

- **Built-in Presets Factory (`BuiltinPresetFactory`)**: 4 immutable curated workflow presets (`Coding` 60/25/15, `Research` 50/25/25, `Writing` 70/30, `Design` 70/30) with relative layout ratios, zone anchors, app categories, and default keyboard shortcuts.
- **Smart App Category Fallback Resolution**: Resolution engine for preset slots prioritizing (1) Running candidate app matching category chain, (2) Installed candidate app on macOS via `NSWorkspace.urlForApplication(withBundleIdentifier:)`, (3) Asynchronous launch with bounded ≤ 10.0s AX window wait, (4) Graceful slot skipping with `SkipReason.notInstalled` or `SkipReason.launchTimeout`.
- **Display-Aware Geometry Computation**: Dynamically calculating target window frames against the active display's `visibleBounds` at restore time with user-configured window gap support (`PreferencesStore.windowGap`).
- **Global Hotkey Dispatch & Collision Prevention**: Global shortcuts for presets (`⌃⌥C`, `⌃⌥R`, `⌃⌥W`, `⌃⌥D`) routed via `GlobalHotkeyManager` → `CommandDispatcher.dispatch(.restorePreset(id))` with latest-wins debouncing. `ShortcutRecorderField` pre-validates against standard snap actions (`ShortcutAction.allCases`) and active presets.
- **Window Group Core Entity & Coordination Engine (`WindowGroupManager`)**: Dynamic `@MainActor` coordinator managing linked window groups (minimum 2 `CGWindowID` members), synchronizing minimize/un-minimize, focus with relative z-order preservation, and spatial move/snap displacement.
- **Re-Entrancy & Echo Loop Guard**: Generation token and `isSynchronizing` locking mechanism preventing cyclic AX notification echoes during programmatic group dispatch.
- **Dynamic Lifecycle Auto-Pruning**: Automatic removal of closed windows upon `kAXUIElementDestroyedNotification` and automatic dissolution of groups when member count falls below 2.
- **UI Integration**:
  - **Settings > Presets Gallery**: Visual schematic cards, slot details, shortcut recorders, collision alerts, and 1-click "Apply" button.
  - **Settings > Window Groups**: Active groups list with member count, app icons, sync option toggles, and "Ungroup" action.
  - **Menu Bar Popover**: "Presets" submenu with direct trigger and keyboard shortcut badges.
  - **Toast / Banner**: Non-blocking `RestoreSummary` banner ("Restored Coding Preset (3/3 windows)").

### Out of Scope (Locked by Baseline MoSCoW)

- **Cross-Space / Mission Control Window Movement**: Moving windows across macOS Mission Control Spaces via private CGS APIs (strictly forbidden by Zero Private API policy).
- **Native Tab Merging**: Forcing separate application windows into a unified native tab bar (requires undocumented AppKit hooks).
- **Cloud Sync / Remote Catalog**: Synchronizing presets across multiple machines or cloud repositories (local-first design).
- **App Launch Space Preservation**: Trapping newly launched apps to the current Space (deferred to Epic 11 / `US-WORK-013`).

---

## 2. User Scenarios & Testing

### User Story 1 — Activate Built-in Workflow Presets (Priority: P1) 🎯 MVP

**As a** Mac software engineer or knowledge worker,  
**I want** to trigger curated workflow presets (Coding, Research, Writing, Design) via global hotkeys or the Menu Bar,  
**So that** my entire multi-window layout configures itself instantly without manual dragging and snapping.

**Why this priority**: Core value proposition enabling instant multi-window arrangement with standard macOS developer workflows.

**Independent Test**: Can be tested end-to-end by pressing `⌃⌥C` with VS Code, Chrome, and Terminal open and verifying all 3 windows frame correctly in the 60/25/15 layout.

**Acceptance Scenarios**:

1. **Given** VS Code, Chrome, and Terminal are running on the active display,  
   **When** I press `⌃⌥C` (Control + Option + C),  
   **Then** `CommandDispatcher` routes the command to `.restorePreset("builtin.coding")`,  
   **And** VS Code is positioned in the left 60% zone (`.left60_40`),  
   **And** Chrome is positioned in the top-right 25% zone (`.topRight`),  
   **And** Terminal is positioned in the bottom-right 15% zone (`.bottomRight`),  
   **And** a non-blocking toast surfaces "Restored Coding Preset (3/3 windows)".

2. **Given** Safari and Apple Notes are running,  
   **When** I open the Menu Bar popover and click "Presets > Research",  
   **Then** Safari takes the left half (`.leftHalf`, 50%),  
   **And** Apple Notes takes the top right (`.topRight`, 25%),  
   **And** a secondary browser window takes the bottom right (`.bottomRight`, 25%).

3. **Given** FlowSnap is running on a 34" ultrawide external display,  
   **When** I trigger the "Writing" preset (`⌃⌥W`),  
   **Then** the document editor is framed in the left 70% zone (`.left70_30`) and the reference browser in the right 30% zone (`.rightOneThird`),  
   **And** all window dimensions are computed from the external display's `visibleBounds`.

---

### User Story 2 — Smart App Category Fallback & Resilient Launch (Priority: P2)

**As a** Mac user with a customized software stack,  
**I want** presets to resolve alternative applications when default apps are missing,  
**So that** presets work seamlessly regardless of whether I use VS Code, Xcode, Chrome, or Safari.

**Why this priority**: Guarantees presets work out-of-the-box on clean macOS installs and custom setups without hardcoded app requirements.

**Independent Test**: Can be tested by invoking the Coding preset on a system without VS Code installed, verifying Xcode or TextEdit is launched and positioned within the 10.0s timeout.

**Acceptance Scenarios**:

1. **Given** the Coding preset prefers VS Code, but VS Code is not installed,  
   **And** Xcode is installed on the Mac,  
   **When** I activate the Coding preset,  
   **Then** FlowSnap selects Xcode from the `.editor` fallback chain,  
   **And** launches Xcode via `NSWorkspace.openApplication`,  
   **And** waits up to 10.0 seconds for Xcode's first AX window to appear,  
   **And** places Xcode into the left 60% slot.

2. **Given** the Design preset requires a design tool (`.design`), but neither Figma, Sketch, nor Illustrator is installed,  
   **When** I activate the Design preset,  
   **Then** the design slot is skipped with reason `.notInstalled`,  
   **And** the remaining reference browser slot is placed successfully in its 30% right zone,  
   **And** the restore summary reports "Restored 1/2 — Design Tool not installed".

3. **Given** a fallback app launches but its initial window takes > 10.0 seconds to appear,  
   **When** I activate the preset,  
   **Then** FlowSnap times out the slot at 10.0 seconds with reason `.launchTimeout`,  
   **And** proceeds immediately to finish remaining slots without freezing the UI.

---

### User Story 3 — Link & Synchronize Window Groups (Priority: P3)

**As a** power multitasker,  
**I want** cooperating windows to form a synchronized Window Group,  
**So that** minimizing, focusing, or repositioning one window coordinates all member windows together.

**Why this priority**: Preserves layout cohesiveness when switching contexts or multitasking across multiple apps.

**Independent Test**: Can be tested by creating a group with 2 windows, clicking minimize on one window, and verifying both windows minimize simultaneously without cascade loops.

**Acceptance Scenarios**:

1. **Given** VS Code and Terminal are linked in a `WindowGroup`,  
   **When** I click the yellow minimize button on VS Code,  
   **Then** `WindowGroupManager` minimizes both VS Code and Terminal simultaneously,  
   **When** I restore VS Code from the Dock or App Switcher,  
   **Then** Terminal is also automatically un-minimized and restored.

2. **Given** a 3-window Window Group is partially hidden behind other background apps,  
   **When** I click into any window belonging to the group,  
   **Then** all 3 grouped windows are brought to the front together,  
   **And** the clicked window remains the topmost active window (preserving relative z-order).

3. **Given** a Window Group with move synchronization enabled (`.moveTogether`),  
   **When** I snap the anchor window to another display or zone,  
   **Then** the associated grouped windows shift cohesively to adjacent zones on the target display.

4. **Given** a Window Group containing exactly 2 windows,  
   **When** I close one of the member windows (`⌘W` / Quit),  
   **Then** `WindowGroupManager` receives `kAXUIElementDestroyedNotification`,  
   **And** removes the closed window ID from the group,  
   **And** automatically dissolves the group because member count is now 1 (< 2),  
   **And** the remaining window returns to normal standalone behavior.

5. **Given** an active Window Group with 3 windows,  
   **When** minimizing window A triggers programmatic minimize on windows B and C,  
   **Then** the resulting AX minimize notifications from B and C are ignored by `WindowGroupManager`'s re-entrancy lock,  
   **And** no redundant operations or infinite event feedback loops occur.

---

### User Story 4 — Presets Gallery & Hotkey Customization (Priority: P4)

**As a** FlowSnap user,  
**I want** to visually inspect presets and assign custom shortcuts in Settings,  
**So that** I can personalize my workflow triggers and manage active groups.

**Why this priority**: Provides discoverability, visual feedback, and shortcut flexibility for power users.

**Independent Test**: Can be tested by opening Settings > Presets, recording a new shortcut for the Writing preset, and verifying registration and collision warnings.

**Acceptance Scenarios**:

1. **Given** the Settings > Presets Gallery tab is open,  
   **When** I click the shortcut recorder for the Research preset and press `⌃⌥⇧R`,  
   **Then** the shortcut is saved to `PreferencesStore`,  
   **And** `GlobalHotkeyManager` updates the active hotkey registration.

2. **Given** `⌃⌥←` is already assigned to the "Snap Left Half" action,  
   **When** I attempt to record `⌃⌥←` for the Coding preset,  
   **Then** the recorder rejects the input and shows an inline warning: "Shortcut already in use by Left Half",  
   **And** the previous shortcut remains unchanged.

3. **Given** an active Window Group exists,  
   **When** I open Settings > Window Groups and click "Ungroup",  
   **Then** `WindowGroupManager.dissolveGroup()` is executed,  
   **And** the group is removed from the active list.

---

## 3. Requirements

### Functional Requirements

- **FR-PRESET-001 (Built-in Factory)**: System MUST provide `BuiltinPresetFactory` containing 4 standard immutable presets (`Coding`, `Research`, `Writing`, `Design`) with relative slot definitions, ratios, and default shortcuts (`⌃⌥C`, `⌃⌥R`, `⌃⌥W`, `⌃⌥D`).
- **FR-PRESET-002 (Fallback Resolution)**: System MUST evaluate slot candidates in order: (1) running app, (2) first installed app on system, (3) graceful skip.
- **FR-PRESET-003 (Bounded Auto-Launch)**: System MUST auto-launch missing fallback candidates with a ≤ 10.0s timeout for first AX window; timed-out slots MUST be marked `SkipReason.launchTimeout` without aborting remaining slots.
- **FR-PRESET-004 (Resolution-Independence)**: System MUST calculate target frames at runtime from the active display's `visibleBounds` and user window gap preference (`PreferencesStore.windowGap`).
- **FR-PRESET-005 (Hotkey Dispatch)**: System MUST route preset shortcuts via `GlobalHotkeyManager` → `CommandDispatcher.dispatch(.restorePreset(id))` with latest-wins debouncing.
- **FR-PRESET-006 (Collision Prevention)**: System MUST reject shortcut assignments colliding with `ShortcutAction.allCases` or existing preset/workspace shortcuts.
- **FR-PRESET-007 (UI Surfaces)**: System MUST provide Settings Presets Gallery, Settings Window Groups tab, Menu Bar Presets submenu, and non-blocking `RestoreSummary` banner.
- **FR-GROUP-001 (Group Membership Cardinality)**: System MUST require `WindowGroup.memberCount >= 2`; if member count drops below 2, group MUST automatically dissolve.
- **FR-GROUP-002 (Simultaneous Minimize/Restore)**: System MUST synchronize minimize and restore actions across all active group members.
- **FR-GROUP-003 (Simultaneous Focus & Z-Order)**: System MUST bring all group members to foreground on focus, raising the anchor/target window last to preserve relative z-order.
- **FR-GROUP-004 (Group Move Synchronization)**: System MUST translate all member windows by the relative delta when move synchronization is enabled.
- **FR-GROUP-005 (Re-Entrancy Guard)**: `WindowGroupManager` MUST ignore inbound AX event echoes during active synchronization passes via generation counter and lock flag.
- **FR-GROUP-006 (Dynamic Auto-Pruning)**: System MUST observe window destruction notifications and prune dead `CGWindowID`s immediately.
- **FR-GROUP-007 (AX Permission Pre-Flight)**: System MUST verify `AXAccessibilityService.isTrusted` before mutations; if untrusted, abort cleanly and prompt user.

---

## 4. Success Criteria

### Measurable Outcomes

- **SC-001**: Preset restoration for 3 running applications completes in under 500ms total elapsed time.
- **SC-002**: Preset hotkey invocation latency from keystroke to layout calculation is under 50ms.
- **SC-003**: 100% of uninstalled fallback applications fail gracefully to the next candidate or skip without freezing the application or crashing.
- **SC-004**: Window group synchronization across 3+ windows experiences zero cascade feedback loops or event amplification.
- **SC-005**: 100% of shortcut collisions against `ShortcutAction` are detected and rejected in Settings UI with zero false negatives.

---

## 5. Assumptions

- **ASM-001 (App Categories)**: The predefined app categories (`.editor`, `.browser`, `.terminal`, `.notes`, `.writing`, `.design`) cover >95% of target Mac knowledge worker workflows.
- **ASM-002 (Display Topology)**: The user intends preset layouts to apply to the screen currently containing the frontmost focused window, cursor, or primary display.
- **ASM-003 (Public AX Availability)**: Standard macOS applications (VS Code, Chrome, Safari, Xcode, Terminal, Notes) respond reliably to public `AXUIElement` position, size, raise, and minimize attributes.
- **ASM-004 (Concurrency Isolation)**: All window management actions are coordinated via `@MainActor` isolation in `WindowGroupManager` and `WorkspaceManager`.

---

## 6. Edge Cases & Error Handling

| #       | Edge Case                                                      | Expected System Behavior                                                                                 |
| ------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **E1**  | Preset triggered while no candidate apps are installed         | All slots skipped; `RestoreSummary` displays "Restored 0/N — No supported apps installed"; no crash      |
| **E2**  | Fallback app launch exceeds 10.0s timeout                      | Slot marked `SkipReason.launchTimeout`; other slots proceed without delay; non-blocking summary surfaced |
| **E3**  | Accessibility permission untrusted or revoked                  | Pre-flight check aborts; surfaces permission prompt; zero windows moved                                  |
| **E4**  | Preset hotkey assigned to existing snap shortcut (e.g. `⌃⌥←`)  | `ShortcutRecorderField` rejects input; inline red warning displayed; existing shortcut retained          |
| **E5**  | Grouped window closed by user (`⌘W` / quit)                    | `WindowGroupManager` receives destroy notification, prunes ID, dissolves group if count < 2              |
| **E6**  | Window minimization echoes back as AX notification             | Re-entrancy lock ignores echo event; prevents infinite loop                                              |
| **E7**  | Rapid sequential hotkey presses (`⌃⌥C` then `⌃⌥R`)             | `CommandDispatcher` cancels previous in-flight task via latest-wins debouncing                           |
| **E8**  | Preset applied on small display (13" MacBook) vs 34" ultrawide | Frames recomputed from active display `visibleBounds` with minimum size clamping                         |
| **E9**  | Non-resizable dialog opened by grouped application             | Dialog excluded from layout manipulation; primary window handled normally                                |
| **E10** | App launched in full-screen mode by macOS session restore      | `WindowManager` detects full-screen, exits full-screen before framing                                    |
| **E11** | Corrupt presets/groups persistence                             | `PreferencesStore` falls back to default immutable `BuiltinPresetFactory` presets                        |
| **E12** | All members of a group minimized; user clicks one in Dock      | Un-minimizes trigger window and restores all fellow group members                                        |

---

## 7. Open Technical Decisions (Resolved via ADRs)

- **ADR-0007**: Separation of immutable domain templates (`WorkspacePreset`) from user-saved workspace instances (`Workspace`).
- **ADR-0008**: `@MainActor WindowGroupManager` coordinator with re-entrancy generation locking for window synchronization.
- **ADR-0009**: Category-based fallback resolution chain using `ApplicationLaunching` protocol abstraction.
- **ADR-0010**: Extension of `WindowCommand` enum (`.restorePreset(String)`) and `PreferencesStore` shortcut collision validation.
