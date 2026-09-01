# Product Requirements Document: Window Groups & Workspace Presets (US-WORK-012)

- **Feature**: `window-groups-presets`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (PRD)
- **Anchors**: ASM-GROUP-001 (app category fallbacks), ASM-GROUP-002 (group synchronization & lifecycle), ASM-GROUP-003 (hotkey routing & collision prevention)
- **Status**: SIGNED-OFF v1.0 — 2026-09-01
- **Upstream**: `spec/brd.md` (BR-PRESET-001…006, BR-GROUP-001…006)

---

## 1. Product Overview

FlowSnap Window Groups & Workspace Presets extends workspace management by delivering:

1. **Curated Workflow Presets**: Ready-to-use multi-window layouts for Coding, Research, Writing, and Design with smart fallback chains and proportional multi-column split zones.
2. **Dedicated Hotkey Dispatch**: Custom global keyboard shortcuts that instantly activate any preset or user workspace.
3. **Synchronized Window Groups**: Live grouping of collaborating windows that coordinate minimize/un-minimize, focus, and relative movement as a single unit.

---

## 2. Product Requirements

| ID                 | Requirement Statement                                                                                                                                                                                         | Derived from (BR)           | Assumption    | Verified by (SRS)             |
| :----------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------- | :------------ | :---------------------------- |
| **PRD-PRESET-001** | **Curated Built-in Preset Templates** — Supply 4 standard presets: Coding (60/25/15), Research (50/25/25), Writing (70/30), and Design (70/30) with predefined application category slots.                    | BR-PRESET-001               | —             | REQ-PRESET-001                |
| **PRD-PRESET-002** | **Smart App Category Fallback Resolution** — Automatically resolve each preset slot by checking: (1) running apps matching candidates, (2) first installed candidate on system, (3) skip slot if unavailable. | BR-PRESET-002               | ASM-GROUP-001 | REQ-PRESET-002                |
| **PRD-PRESET-003** | **Graceful Launch & Toast Reporting** — Launch unlaunched fallback apps via `NSWorkspace.open`, wait ≤ 10s for first window, gracefully skip on timeout, and surface non-blocking `RestoreSummary`.           | BR-PRESET-003               | ASM-GROUP-001 | REQ-PRESET-003                |
| **PRD-PRESET-004** | **Display-Aware Zone Placement** — Recompute target frames against the active display's `visibleBounds` at runtime, supporting custom divider ratios and multi-column splits.                                 | BR-PRESET-004               | —             | REQ-PRESET-004                |
| **PRD-PRESET-005** | **Preset Global Hotkey Triggers** — Allow triggering presets via dedicated global shortcuts (`⌃⌥C`, `⌃⌥R`, `⌃⌥W`, `⌃⌥D`) dispatched through `CommandDispatcher`.                                              | BR-PRESET-005               | ASM-GROUP-003 | REQ-PRESET-005                |
| **PRD-PRESET-006** | **Hotkey Collision Rejection** — Block and warn against hotkey assignments conflicting with standard snap shortcuts or other active bindings.                                                                 | BR-PRESET-006               | ASM-GROUP-003 | REQ-PRESET-006                |
| **PRD-GROUP-001**  | **Window Group Creation & Cardinality** — Support creating logical window groups with ≥ 2 member windows; auto-dissolve groups when fewer than 2 members remain.                                              | BR-GROUP-001                | ASM-GROUP-002 | REQ-GROUP-001                 |
| **PRD-GROUP-002**  | **Simultaneous Minimize & Restore Sync** — Minimizing or restoring any window in a group applies the same state transition to all group members.                                                              | BR-GROUP-002                | ASM-GROUP-002 | REQ-GROUP-002                 |
| **PRD-GROUP-003**  | **Simultaneous Focus & Z-Order Preservation** — Activating any group member brings all group windows to the front while preserving their relative visual z-order.                                             | BR-GROUP-003                | ASM-GROUP-002 | REQ-GROUP-003                 |
| **PRD-GROUP-004**  | **Simultaneous Group Move & Spatial Cohesion** — Moving or snapping a group anchor window shifts member windows cohesively when move sync is enabled.                                                         | BR-GROUP-004                | ASM-GROUP-002 | REQ-GROUP-004                 |
| **PRD-GROUP-005**  | **Re-Entrancy & Echo Loop Guard**                                                                                                                                                                             | BR-GROUP-005                | —             | REQ-GROUP-005                 |
| **PRD-GROUP-006**  | **Settings & Menu Bar UI Affordances** — Provide visual presets gallery with ratio previews, shortcut recorder, active groups management, and popover submenu.                                                | BR-PRESET-001, BR-GROUP-001 | —             | REQ-GROUP-006, REQ-PRESET-007 |

---

## 3. Non-Functional Requirements

| ID                | Requirement Statement                                                                                                                         | Traceability            |
| :---------------- | :-------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------- |
| **NFR-GROUP-001** | **Swift 6 Strict Concurrency**: Zero data-race/Sendable warnings; `@MainActor` UI and coordinator isolation; actor-backed store interactions. | Tech-context hard rules |
| **NFR-GROUP-002** | **Code Hygiene & Limits**: Zero force-unwraps (`!`), zero `try!`, zero `as!`; file < 800 LOC; function < 50 LOC; passes `swiftlint --strict`. | Tech-context hard rules |
| **NFR-GROUP-003** | **Execution Latency**: Preset layout framing for already-running apps executes in < 500ms; hotkey dispatch responds in < 50ms.                | OBJ-GROUP-01            |
| **NFR-GROUP-004** | **Zero Private API Policy**: Strict adherence to public macOS AppKit, SwiftUI, `NSWorkspace`, and AX APIs. No private CGS symbols.            | BR-GROUP-006            |
| **NFR-GROUP-005** | **Dynamic Memory Safety**: Group memberships auto-pruned upon window close; zero memory leaks or dangling AX element pointers.                | RISK-GROUP-002          |

---

## 4. UX States & Surfaces

1. **Settings > Presets & Workspaces Gallery**:
   - Visual cards depicting proportional layout splits (60/25/15, 50/25/25, 70/30).
   - Direct "Apply Preset" button.
   - Shortcut recorder field per preset with real-time collision detection.
2. **Settings > Window Groups Management**:
   - Active groups list displaying member window titles and app icons.
   - Checkboxes for sync options: `[x] Minimize Together`, `[x] Focus Together`, `[ ] Move Together`.
   - "Ungroup" button to dissolve a group manually.
3. **Menu Bar Popover Integration**:
   - "Presets" section listing Coding, Research, Writing, Design with hotkey badges.
   - Active group status pill with quick "Ungroup" action.
4. **Restore Summary Toast**:
   - Non-blocking banner: "Restored Coding Preset (3/3 windows)" or "Restored 2/3 — Terminal not running".

---

## 5. Release Plan

- **v1.0 (This Feature)**: Curated built-in presets factory, smart category fallbacks, dedicated preset hotkeys with collision prevention, live window group synchronization (minimize/restore, focus, move), dynamic auto-pruning, Settings gallery and Menu Bar integration.
- **v1.1 (Future Additive Evolution)**: Custom user preset creation with arbitrary fallback chains, visual group border highlighting.
- **Successor**: `US-WORK-013` (Application Launch Observer & Current Space Policy).
