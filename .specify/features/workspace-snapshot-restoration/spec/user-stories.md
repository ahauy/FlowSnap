# User Stories: Workspace Snapshot & Intent-Based Multi-Window Restoration (US-WORK-011)

- **Feature**: `workspace-snapshot-restoration`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (User Stories)
- **Anchors**: ASM-WORK-001 (auto-launch), ASM-WORK-002 (count-aware mapping), ASM-WORK-003 (additive restore)

---

### Story 1: Save Current Arrangement as a Named Workspace

**ID**: `US-WORK-011.1`
**As a** Mac power user,
**I want** to save my current multi-window arrangement under a name and icon,
**So that** I can return to it later with one action.

#### Acceptance Criteria (Gherkin):

- **Scenario 1.1 (Happy Path — Save)**:
  - **Given** 3 apps are running with windows snapped into zones on the current display
  - **When** I choose "Save current arrangement", enter the name "Coding" and pick an SF Symbol icon, and confirm
  - **Then** a `Workspace` is captured with one `WindowPlacement` per app (bundle-id → relative zone/ratio + `expectedWindowCount`)
  - **And** it is persisted atomically to `~/Library/Application Support/FlowSnap/workspaces.json` via the `WorkspaceStore` actor
  - **And** no pixel coordinates are stored (BR-WORK-001).

- **Scenario 1.2 (Edge — Duplicate Name Blocked)**:
  - **Given** a workspace named "Coding" already exists
  - **When** I type "coding" (case-insensitive match) in the Save sheet
  - **Then** the Save button is disabled and an inline error is shown
  - **And** no new entry is written to the store (BR-WORK-008).

- **Scenario 1.3 (Edge — Empty Name Blocked)**:
  - **Given** the Save sheet is open
  - **When** the name field is empty or whitespace-only
  - **Then** the Save button remains disabled.

- **Scenario 1.4 (Edge — Store Failure)**:
  - **Given** the store write fails (e.g. disk error)
  - **When** I confirm Save
  - **Then** a non-blocking alert appears with a typed error and a retry offer
  - **And** the app does not crash and the name is kept in the sheet for retry (BR-WORK-009).

---

### Story 2: One-Key Restore onto the Current Display

**ID**: `US-WORK-011.2`
**As a** Mac power user,
**I want** to restore a saved workspace with one action,
**So that** my apps return to their slots without manual re-snapping.

#### Acceptance Criteria (Gherkin):

- **Scenario 2.1 (Happy Path — All Apps Running)**:
  - **Given** the "Coding" workspace exists and all its apps are running with ≥ `expectedWindowCount` windows each
  - **When** I invoke Restore from the Menu Bar popover
  - **Then** each app's primary window is placed into its placement zone, recomputed from the current display's `visibleBounds`
  - **And** extra same-app windows are stacked/cascaded sequentially inside the same zone with offsets clamped inside zone bounds (BR-WORK-002, ASM-WORK-002)
  - **And** a summary "Restored 3/3" is shown and auto-dismisses.

- **Scenario 2.2 (Edge — Restore on a Different Display Size)**:
  - **Given** "Coding" was saved on a 14" display
  - **When** I restore it on an external 27" display
  - **Then** every window lands inside the correct relative zone of the current display
  - **And** no save-time pixel geometry is reused (BR-WORK-001, BR-WORK-007).

- **Scenario 2.3 (Edge — Non-Workspace Windows Untouched)**:
  - **Given** a Notes window is open outside any workspace placement
  - **When** I restore "Coding"
  - **Then** the Notes window's position and size are unchanged (BR-WORK-005, ASM-WORK-003).

- **Scenario 2.4 (Edge — AX Permission Missing)**:
  - **Given** Accessibility permission is not granted
  - **When** I invoke Restore
  - **Then** a non-blocking prompt is shown and restore aborts with zero window moves (RISK-WORK-008).

---

### Story 3: Auto-Launch Missing Apps with Graceful Skip

**ID**: `US-WORK-011.3`
**As a** Mac power user,
**I want** restore to launch apps that are not running and skip the ones it cannot,
**So that** one action restores as much of my workspace as possible without ever hanging.

#### Acceptance Criteria (Gherkin):

- **Scenario 3.1 (Happy Path — Auto-Launch & Place)**:
  - **Given** the "Coding" workspace includes VS Code, which is not running but is installed
  - **When** I restore "Coding"
  - **Then** FlowSnap launches VS Code via `NSWorkspace.open` (public API)
  - **And** waits ≤ 10s for its first window via AX observation
  - **And** places that window into its placement zone (BR-WORK-003, ASM-WORK-001).

- **Scenario 3.2 (Edge — App Not Installed)**:
  - **Given** a workspace references a bundle-id that no longer resolves on this Mac
  - **When** I restore
  - **Then** that app is skipped with reason `.notInstalled`
  - **And** remaining placements are still restored
  - **And** the summary reads "Restored 2/3 — VS Code not running" (BR-WORK-004).

- **Scenario 3.3 (Edge — Launch/First-Window Timeout)**:
  - **Given** a workspace app launches but shows no AX window within ~10s (e.g. gatekeeper delay, login dialog)
  - **When** I restore
  - **Then** that app is skipped with reason `.launchTimeout` or `.noWindowAppeared`
  - **And** restore continues sequentially with the remaining placements without blocking (RISK-WORK-001).

- **Scenario 3.4 (Edge — Extra Windows Stay In-Bounds)**:
  - **Given** a workspace app had 4 windows at save time
  - **When** I restore with all 4 windows present
  - **Then** the primary window takes the zone and the 3 extras cascade inside the zone without leaking outside its bounds or overlapping other workspace windows (RISK-WORK-006).

---

### Story 4: Manage Saved Workspaces

**ID**: `US-WORK-011.4`
**As a** Mac power user,
**I want** to view, rename, and delete my saved workspaces,
**So that** the list stays relevant as my setups change.

#### Acceptance Criteria (Gherkin):

- **Scenario 4.1 (Happy Path — List & Rename)**:
  - **Given** 2 saved workspaces exist
  - **When** I open the Popover or Settings workspace list
  - **Then** both entries appear with name and icon from reactive state
  - **And** renaming "Coding" to "Deep Work" updates the list and the store.

- **Scenario 4.2 (Edge — Delete with Confirmation)**:
  - **Given** the workspace list shows "Coding"
  - **When** I choose Delete and confirm
  - **Then** the workspace is removed from the store and the list
  - **And** cancelling the confirmation changes nothing.

- **Scenario 4.3 (Edge — Empty State)**:
  - **Given** no workspaces are saved
  - **When** I open the workspace list
  - **Then** an empty state with a "Save current arrangement" CTA is shown.

- **Scenario 4.4 (Edge — Corrupt Store File)**:
  - **Given** `workspaces.json` is corrupt (e.g. partial write)
  - **When** FlowSnap reads the store
  - **Then** the list degrades to empty with a typed, non-crashing error and a retry offer
  - **And** the corrupt file is not silently overwritten until the user saves again (BR-WORK-009, RISK-WORK-004).
