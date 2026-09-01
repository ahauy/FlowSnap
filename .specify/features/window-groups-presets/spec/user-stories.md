# User Stories: Window Groups & Workspace Presets (US-WORK-012)

- **Feature**: `window-groups-presets`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (User Stories)
- **Anchors**: ASM-GROUP-001 (app category fallbacks), ASM-GROUP-002 (group synchronization & lifecycle), ASM-GROUP-003 (hotkey routing & collision prevention)

---

### Story 1: Activate Built-in Workflow Presets

**ID**: `US-WORK-012.1`  
**As a** Mac software engineer or knowledge worker,  
**I want** to trigger curated workflow presets (Coding, Research, Writing, Design) via global hotkeys or the Menu Bar,  
**So that** my entire multi-window layout configures itself instantly without manual dragging and snapping.

#### Acceptance Criteria (Gherkin):

- **Scenario 1.1 (Happy Path — Activate Coding Preset via Hotkey)**:
  - **Given** VS Code, Chrome, and Terminal are running on the active display
  - **When** I press `⌃⌥C` (Control + Option + C)
  - **Then** `CommandDispatcher` routes the command to `.restorePreset("builtin.coding")`
  - **And** VS Code is positioned in the left 60% zone (`.left60_40`)
  - **And** Chrome is positioned in the top-right 25% zone (`.topRight`)
  - **And** Terminal is positioned in the bottom-right 15% zone (`.bottomRight`)
  - **And** a toast notification shows "Restored Coding Preset (3/3 windows)".

- **Scenario 1.2 (Happy Path — Activate Research Preset via Menu Bar)**:
  - **Given** Safari and Apple Notes are open
  - **When** I open the Menu Bar popover and click "Presets > Research"
  - **Then** Safari takes the left half (`.leftHalf`, 50%)
  - **And** Apple Notes takes the top right (`.topRight`, 25%)
  - **And** a secondary browser window takes the bottom right (`.bottomRight`, 25%).

- **Scenario 1.3 (Edge — Restore Preset on External Ultrawide Display)**:
  - **Given** FlowSnap is active on a 34" ultrawide display
  - **When** I trigger the "Writing" preset (`⌃⌥W`)
  - **Then** the document editor is framed in the left 70% zone (`.left70_30`) and the reference browser in the right 30% zone (`.rightOneThird`)
  - **And** all window bounds are calculated from the ultrawide display's `visibleBounds` without hardcoded pixel coordinates.

- **Scenario 1.4 (Edge — AX Permission Missing)**:
  - **Given** Accessibility permission is not granted to FlowSnap
  - **When** I press a preset hotkey (`⌃⌥C`)
  - **Then** FlowSnap displays a non-blocking prompt to grant Accessibility permissions
  - **And** no windows are moved or modified.

---

### Story 2: Smart App Category Fallback & Resilient Launch

**ID**: `US-WORK-012.2`  
**As a** Mac user with a customized software stack,  
**I want** presets to resolve alternative applications when default apps are missing,  
**So that** presets work seamlessly regardless of whether I use VS Code, Xcode, Chrome, or Safari.

#### Acceptance Criteria (Gherkin):

- **Scenario 2.1 (Happy Path — Fallback App Auto-Resolved & Launched)**:
  - **Given** the Coding preset prefers VS Code, but VS Code is not installed
  - **And** Xcode is installed on the Mac
  - **When** I activate the Coding preset
  - **Then** FlowSnap selects Xcode from the `.editor` fallback chain
  - **And** launches Xcode via `NSWorkspace.open`
  - **And** waits up to 10.0 seconds for Xcode's first AX window to appear
  - **And** places Xcode into the left 60% slot.

- **Scenario 2.2 (Edge — No Candidate in Fallback Chain Installed)**:
  - **Given** the Design preset requires a design tool (`.design`), but neither Figma, Sketch, nor Illustrator is installed
  - **When** I activate the Design preset
  - **Then** the design slot is skipped with reason `.notInstalled`
  - **And** the remaining reference browser slot is placed successfully in its 30% right zone
  - **And** the restore summary reports "Restored 1/2 — Design Tool not installed".

- **Scenario 2.3 (Edge — Heavy App Launch Times Out)**:
  - **Given** a fallback app launches but its initial window takes > 10.0 seconds to appear (e.g. system slowdown)
  - **When** I activate the preset
  - **Then** FlowSnap times out the slot at 10.0 seconds with reason `.launchTimeout`
  - **And** proceeds immediately to finish remaining slots without freezing the user interface.

---

### Story 3: Link & Synchronize Window Groups

**ID**: `US-WORK-012.3`  
**As a** power multitasker,  
**I want** cooperating windows to form a synchronized Window Group,  
**So that** minimizing, focusing, or repositioning one window coordinates all member windows together.

#### Acceptance Criteria (Gherkin):

- **Scenario 3.1 (Happy Path — Simultaneous Group Minimize & Restore)**:
  - **Given** VS Code and Terminal are linked in a `WindowGroup`
  - **When** I click the yellow minimize button on VS Code (or press minimize hotkey)
  - **Then** `WindowGroupManager` minimizes both VS Code and Terminal simultaneously
  - **When** I restore VS Code from the Dock or App Switcher
  - **Then** Terminal is also automatically un-minimized and restored.

- **Scenario 3.2 (Happy Path — Simultaneous Group Focus & Z-Order Preservation)**:
  - **Given** a 3-window Window Group is partially hidden behind other background apps
  - **When** I click into any window belonging to the group
  - **Then** all 3 grouped windows are brought to the front together
  - **And** the clicked window remains the topmost active window.

- **Scenario 3.3 (Happy Path — Simultaneous Group Move / Snap)**:
  - **Given** a Window Group has move synchronization enabled
  - **When** I snap the group anchor window to another display or zone
  - **Then** the associated grouped windows shift cohesively to adjacent zones on the target display.

- **Scenario 3.4 (Edge — Member Window Closes & Group Auto-Dissolves)**:
  - **Given** a Window Group containing exactly 2 windows
  - **When** I close one of the member windows (`⌘W` / Quit)
  - **Then** `WindowGroupManager` receives `kAXUIElementDestroyedNotification`
  - **And** removes the closed window ID from the group
  - **And** automatically dissolves the group because member count is now 1 (< 2)
  - **And** the remaining window returns to normal standalone behavior.

- **Scenario 3.5 (Edge — Re-Entrancy Event Echo Ignored)**:
  - **Given** an active Window Group with 3 windows
  - **When** minimizing window A triggers programmatic minimize on windows B and C
  - **Then** the resulting AX minimize notifications from B and C are ignored by `WindowGroupManager`'s re-entrancy lock
  - **And** no redundant operations or infinite event feedback loops occur.

---

### Story 4: Presets Gallery & Hotkey Customization

**ID**: `US-WORK-012.4`  
**As a** FlowSnap user,  
**I want** to visually inspect presets and assign custom shortcuts in Settings,  
**So that** I can personalize my workflow triggers and manage active groups.

#### Acceptance Criteria (Gherkin):

- **Scenario 4.1 (Happy Path — Customize Preset Hotkey)**:
  - **Given** the Settings > Presets Gallery tab is open
  - **When** I click the shortcut recorder for the Research preset and press `⌃⌥⇧R`
  - **Then** the shortcut is saved to `PreferencesStore`
  - **And** `GlobalHotkeyManager` updates the active hotkey registration.

- **Scenario 4.2 (Edge — Hotkey Collision Rejected)**:
  - **Given** `⌃⌥←` is already assigned to the "Snap Left Half" action
  - **When** I attempt to record `⌃⌥←` for the Coding preset
  - **Then** the recorder rejects the input and shows an inline warning: "Shortcut already in use by Left Half"
  - **And** the previous shortcut remains unchanged.

- **Scenario 4.3 (Happy Path — Manage Active Groups in Settings)**:
  - **Given** an active Window Group exists
  - **When** I open Settings > Window Groups and click "Ungroup"
  - **Then** `WindowGroupManager.dissolveGroup()` is executed
  - **And** the group is removed from the active list.
