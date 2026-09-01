# Business Requirements Document: Window Groups & Workspace Presets (US-WORK-012)

- **Feature**: `window-groups-presets`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (BRD)
- **Anchors**: ASM-GROUP-001 (app category fallbacks), ASM-GROUP-002 (group synchronization & lifecycle), ASM-GROUP-003 (hotkey routing & collision prevention)
- **Status**: SIGNED-OFF v1.0 — 2026-09-01

---

## 1. Business Context

FlowSnap's core mission is to provide frictionless, muscle-memory window management for macOS power users. In `US-WORK-011`, FlowSnap introduced intent-based workspace snapshot and restoration. However, users still encounter significant friction in two common scenarios:

1. **Cold Start & New Setup Friction**: New users or users starting fresh tasks do not want to spend minutes manually arranging 3-4 apps and tweaking split ratios before saving custom workspaces. They expect instant, professionally curated "Workflow Presets" (Coding, Research, Writing, Design) that work immediately out of the box with whatever tools they have installed.
2. **Window Disconnection & Clutter**: When multi-window tasks involve cooperating applications (e.g., Code Editor + Browser + Terminal, or Design Tool + Asset Browser), minimizing or switching between windows requires multiple disjointed clicks. Users need logical **Window Groups** that keep collaborating windows synchronized during minimize, restore, and focus operations.

---

## 2. Business Objectives & Success Metrics

| ID               | Objective                                    | Metric                                                                                            | Target                                                              |
| :--------------- | :------------------------------------------- | :------------------------------------------------------------------------------------------------ | :------------------------------------------------------------------ |
| **OBJ-GROUP-01** | Instant Workflow Activation                  | Time required from clean desktop to fully configured 3-pane workflow (Coding/Research)            | < 3 seconds via global hotkey / menu bar                            |
| **OBJ-GROUP-02** | Zero-Configuration Tool Adaptability         | Successful preset restoration rate across heterogeneous Mac setups without hardcoded app failures | ≥ 95% across varied app environments (via smart category fallbacks) |
| **OBJ-GROUP-03** | Synchronized Multi-Window Focus & Management | Clicks required to minimize or foreground an entire active multi-window working set               | Exactly 1 click / shortcut invocation                               |
| **OBJ-GROUP-04** | Zero System & Concurrency Instability        | Incidents of infinite event feedback loops, private API rejections, or UI hangs                   | 0 incidents (strictly actor-isolated, public AX APIs only)          |

---

## 3. Stakeholders & Concerns

| Stakeholder                                                               | Key Concerns                                                                            | Addressed by                               |
| :------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------- | :----------------------------------------- |
| **Mac Software Engineers & Creators**                                     | One-key setup for development/writing environments without fiddling with layout ratios. | OBJ-GROUP-01, BR-PRESET-001, BR-PRESET-005 |
| **Users with Varied Toolchains (e.g. Safari vs Chrome, Nova vs VS Code)** | Presets shouldn't fail or crash if specific default apps aren't installed.              | OBJ-GROUP-02, BR-PRESET-002, BR-PRESET-003 |
| **Power Multitaskers**                                                    | Managing grouped windows as a single unit without accidental window scattering.         | OBJ-GROUP-03, BR-GROUP-001…004             |
| **System Architects & Reviewers**                                         | Swift 6 strict concurrency, Zero Private API policy, clean memory lifecycle.            | OBJ-GROUP-04, BR-GROUP-005, BR-GROUP-006   |

---

## 4. Business Requirements

| ID                | Requirement Statement                                                                                                                                                                                                              | Derived from / Risk           | Satisfied by (PRD) |
| :---------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------- | :----------------- |
| **BR-PRESET-001** | **Curated Standard Workflow Presets** — FlowSnap shall supply 4 standard built-in presets: Coding (60/25/15), Research (50/25/25), Writing (70/30), and Design (70/30). Presets are immutable domain templates.                    | Roadmap AC; OBJ-GROUP-01      | PRD-PRESET-001     |
| **BR-PRESET-002** | **Prioritized App Category Fallbacks** — Each preset slot shall evaluate candidate bundle IDs in prioritized order: (1) running app in chain, (2) first installed app in chain via `NSWorkspace`, (3) skip slot if none installed. | ASM-GROUP-001; RISK-GROUP-003 | PRD-PRESET-002     |
| **BR-PRESET-003** | **Graceful App Launch & Non-Blocking Summary**                                                                                                                                                                                     | ASM-GROUP-001; RISK-GROUP-003 | PRD-PRESET-003     |
| **BR-PRESET-004** | **Resolution-Independent Intent Framing** — Presets store relative zones and normalized bounding rectangles recomputed against the active display's `visibleBounds`.                                                               | Roadmap AC; RISK-GROUP-005    | PRD-PRESET-004     |
| **BR-PRESET-005** | **Preset Hotkey Execution & Dispatch** — Global keyboard shortcuts for presets shall be routed through `GlobalHotkeyManager` → `CommandDispatcher.dispatch(.restorePreset(id))`.                                                   | ASM-GROUP-003; RISK-GROUP-006 | PRD-PRESET-005     |
| **BR-PRESET-006** | **Hotkey Collision Rejection** — Presets/workspace shortcut assignments colliding with existing snap shortcuts (`ShortcutAction`) or active shortcuts shall be blocked in the UI.                                                  | ASM-GROUP-003; RISK-GROUP-004 | PRD-PRESET-006     |
| **BR-GROUP-001**  | **Window Group Membership & Cardinality** — A `WindowGroup` requires ≥ 2 distinct `CGWindowID` members. If fewer than 2 remain, the group shall dissolve cleanly.                                                                  | Roadmap AC; RISK-GROUP-002    | PRD-GROUP-001      |
| **BR-GROUP-002**  | **Simultaneous Group Minimize & Un-minimize** — Minimizing any window in an active group minimizes all members; restoring any member restores all members.                                                                         | Roadmap AC; RISK-GROUP-001    | PRD-GROUP-002      |
| **BR-GROUP-003**  | **Simultaneous Group Focus & Z-Order Preservation** — Focusing any window in an active group raises all member windows to the foreground while preserving their relative z-order.                                                  | Roadmap AC; RISK-GROUP-008    | PRD-GROUP-003      |
| **BR-GROUP-004**  | **Simultaneous Group Repositioning** — Moving or snapping a group anchor window shifts member windows cohesively when move sync is enabled.                                                                                        | Roadmap AC; OBJ-GROUP-03      | PRD-GROUP-004      |
| **BR-GROUP-005**  | **Re-Entrancy & Loop Prevention** — Group handlers shall employ synchronization lock flags/tokens to prevent infinite AX event echo loops.                                                                                         | RISK-GROUP-001; OBJ-GROUP-04  | PRD-GROUP-005      |
| **BR-GROUP-006**  | **Zero Private API & Memory Safety** — Window groups shall rely strictly on public AX APIs and clean event-driven auto-pruning.                                                                                                    | Tech Context; RISK-GROUP-002  | PRD-GROUP-006      |

---

## 5. Scope

### 5.1 In Scope (v1.0)

- Curated Built-in Presets factory (Coding, Research, Writing, Design) with proportional zone math.
- Smart App Category Fallback engine with running/installed detection and ≤10s launch timeout.
- Global Hotkey Manager & `CommandDispatcher` preset routing with collision prevention.
- Dynamic `WindowGroup` model and `@MainActor WindowGroupManager` coordinator.
- Simultaneous group minimize/restore, focus with z-order preservation, and spatial move sync.
- Dynamic group auto-pruning on window close (`kAXUIElementDestroyedNotification`).
- Settings Presets Gallery with visual layout previews and hotkey recorders.
- Menu Bar Popover quick presets trigger and active group indicators.

### 5.2 Out of Scope (Won't-Have for v1.0)

- Cross-Space / Mission Control window movement (requires private CGS APIs).
- Native application tab grouping / AppKit tab consolidation.
- Cloud-synced preset sharing.
- App launch space trapping (deferred to successor feature `US-WORK-013`).

---

## 6. Assumptions & Dependencies

- **Dependencies**: Depends on `US-WORK-011` (Workspace snapshots, `WorkspaceStore`, `WorkspaceManager`), `LayoutEngine` (ratios/gaps), `GlobalHotkeyManager`, `AXAccessibilityService`, `DisplayManager`.
- **Blocks**: `US-WORK-013` (App Launch Observer & Current Space Preservation Policy).
- **Assumptions**: `ASM-GROUP-001`, `ASM-GROUP-002`, and `ASM-GROUP-003` are confirmed and binding.
