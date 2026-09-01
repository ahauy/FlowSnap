# Software Requirements Specification: Window Groups & Workspace Presets (US-WORK-012)

- **Feature**: `window-groups-presets`
- **Stage**: BA Pipeline — Stage 6: Spec Writer (SRS)
- **Anchors**: ASM-GROUP-001 (app category fallbacks), ASM-GROUP-002 (group synchronization & lifecycle), ASM-GROUP-003 (hotkey routing & collision prevention)
- **Status**: SIGNED-OFF v1.0 — 2026-09-01
- **Upstream**: `spec/brd.md` (BR-PRESET-###, BR-GROUP-###), `spec/prd.md` (PRD-PRESET-###, PRD-GROUP-###)

---

## 1. Functional Requirements

### REQ-PRESET-001 — Curated Built-in Workflow Presets

**Derived from**: BR-PRESET-001 | **Assumption**: — | **Satisfies**: PRD-PRESET-001

The system shall provide a `BuiltinPresetFactory` supplying 4 immutable workflow presets:

1. **Coding**: Editor slot (`left60_40`, 60%), Browser slot (`topRight`, 25%), Terminal slot (`bottomRight`, 15%).
2. **Research**: Primary Browser slot (`leftHalf`, 50%), Notes slot (`topRight`, 25%), Reference Browser slot (`bottomRight`, 25%).
3. **Writing**: Document Editor slot (`left70_30`, 70%), Reference slot (`rightOneThird`, 30%).
4. **Design**: Design Tool slot (`left70_30`, 70%), Assets/Preview slot (`rightOneThird`, 30%).

Each preset shall specify `autoGroupWindows: true` by default.

---

### REQ-PRESET-002 — Smart App Category Fallback Resolution

**Derived from**: BR-PRESET-002 | **Assumption**: ASM-GROUP-001 | **Satisfies**: PRD-PRESET-002

For each slot in a preset, the system shall evaluate candidate bundle identifiers in prioritized order:

1. Find any running application registered in `WindowRegistry` matching one of the slot's `preferredBundleIDs`.
2. If none are running, resolve installed applications on the Mac via `NSWorkspace.urlForApplication(withBundleIdentifier:)` and select the highest priority installed candidate.
3. If an unlaunched installed candidate is selected, initiate asynchronous launch via `NSWorkspace.open`.
4. If no candidate in the chain is installed, mark the slot as skipped with `SkipReason.notInstalled`.

---

### REQ-PRESET-003 — Graceful Launch Timeout & Summary Reporting

**Derived from**: BR-PRESET-003 | **Assumption**: ASM-GROUP-001 | **Satisfies**: PRD-PRESET-003

When an application is auto-launched for a preset slot, the system shall wait at most 10.0 seconds for its initial AX window to appear. If the window fails to appear within 10.0 seconds, the system shall record `SkipReason.launchTimeout` and proceed to place the remaining slots without blocking. Upon completion, the system shall emit a `RestoreSummary` reporting the count of placed slots and skipped reasons.

---

### REQ-PRESET-004 — Display-Aware Intent Recomputation

**Derived from**: BR-PRESET-004 | **Assumption**: — | **Satisfies**: PRD-PRESET-004

The system shall calculate all target window frames against the active display's `visibleBounds` at restore time using `LayoutEngine` and `CoordinateTransformer`. Save-time display pixel dimensions shall never be hardcoded into preset definitions.

---

### REQ-PRESET-005 — Preset Global Hotkey Dispatch

**Derived from**: BR-PRESET-005 | **Assumption**: ASM-GROUP-003 | **Satisfies**: PRD-PRESET-005

The system shall support binding global `KeyboardShortcut` instances to presets (defaulting to `⌃⌥C` for Coding, `⌃⌥R` for Research, `⌃⌥W` for Writing, and `⌃⌥D` for Design). Global hotkey events shall be captured by `GlobalHotkeyManager` and routed to `CommandDispatcher.dispatch(.restorePreset(id))` with latest-wins cancellation debouncing.

---

### REQ-PRESET-006 — Hotkey Collision Prevention

**Derived from**: BR-PRESET-006 | **Assumption**: ASM-GROUP-003 | **Satisfies**: PRD-PRESET-006

The Settings shortcut customization interface (`ShortcutRecorderField`) shall validate entered key combinations against all standard window snap actions (`ShortcutAction.allCases`) and existing active preset/workspace hotkeys. If a collision occurs, the UI shall reject the assignment and display a prominent inline conflict warning.

---

### REQ-PRESET-007 — Settings Presets Gallery & Menu Bar Integration

**Derived from**: BR-PRESET-001, BR-GROUP-001 | **Assumption**: — | **Satisfies**: PRD-PRESET-006

The system shall provide:

1. A **Presets Gallery** tab in Settings with visual multi-pane schematic diagrams, slot details, shortcut recorders, and 1-click "Apply" buttons.
2. A **Presets Submenu** in the Menu Bar popover displaying all presets with current shortcut badges for rapid trigger.

---

### REQ-GROUP-001 — Window Group Membership & Minimum Cardinality

**Derived from**: BR-GROUP-001 | **Assumption**: ASM-GROUP-002 | **Satisfies**: PRD-GROUP-001

The system shall represent a linked window group as a `WindowGroup` entity containing a unique UUID, name, and a set of `CGWindowID` members with a minimum cardinality of 2. If window removals reduce the member count below 2, `WindowGroupManager` shall automatically dissolve the group.

---

### REQ-GROUP-002 — Simultaneous Minimize & Un-minimize Synchronization

**Derived from**: BR-GROUP-002 | **Assumption**: ASM-GROUP-002 | **Satisfies**: PRD-GROUP-002

When a window belonging to an active `WindowGroup` is minimized, `WindowGroupManager` shall programmatically minimize all other member windows via `WindowManager.minimize()`. When any minimized member window is un-minimized or restored, `WindowGroupManager` shall restore all group members concurrently.

---

### REQ-GROUP-003 — Simultaneous Focus & Z-Order Preservation

**Derived from**: BR-GROUP-003 | **Assumption**: ASM-GROUP-002 | **Satisfies**: PRD-GROUP-003

When a window belonging to an active `WindowGroup` is activated (receives focus), `WindowGroupManager` shall raise all member windows in the group to the foreground, activating the clicked/anchor window last so it remains frontmost, preserving relative z-order.

---

### REQ-GROUP-004 — Simultaneous Group Move Synchronization

**Derived from**: BR-GROUP-004 | **Assumption**: ASM-GROUP-002 | **Satisfies**: PRD-GROUP-004

When move synchronization (`GroupSyncOptions.moveTogether`) is enabled for a group, moving or snapping the anchor window shall translate all other member windows by the corresponding relative spatial displacement.

---

### REQ-GROUP-005 — Re-Entrancy Locking & Loop Guard

**Derived from**: BR-GROUP-005 | **Assumption**: — | **Satisfies**: PRD-GROUP-005

`WindowGroupManager` shall maintain an internal synchronization lock (`isSynchronizing` flag and generation token) during group dispatch operations. Inbound AX change notifications generated as echoes of programmatic group actions shall be ignored to prevent recursive feedback loops.

---

### REQ-GROUP-006 — Dynamic Lifecycle Auto-Pruning

**Derived from**: BR-GROUP-001, BR-GROUP-006 | **Assumption**: ASM-GROUP-002 | **Satisfies**: PRD-GROUP-001, PRD-GROUP-006

The system shall observe `kAXUIElementDestroyedNotification` and application termination events. Upon window destruction, `WindowGroupManager` shall immediately prune the dead `CGWindowID` from all active groups and dissolve any group whose remaining member count falls below 2.

---

### REQ-GROUP-007 — AX Pre-Flight Trust Verification

**Derived from**: BR-GROUP-006 | **Assumption**: — | **Satisfies**: PRD-PRESET-003, PRD-GROUP-006

Before executing any preset window placement or group synchronization action, the system shall verify `AXAccessibilityService.isTrusted()`. If accessibility permission is not granted, the operation shall abort immediately with zero partial window mutations and surface a non-blocking prompt.

---

## 2. Non-Functional Requirements

- **NFR-GROUP-001 (Strict Concurrency)**: Swift 6 strict concurrency; `@MainActor` isolation for `WindowGroupManager` and UI views; zero Sendable or data-race compiler warnings.
- **NFR-GROUP-002 (Code Hygiene)**: Files < 800 LOC, functions < 50 LOC; zero force-unwraps (`!`), `try!`, or `as!`; 100% pass on `swiftlint lint --strict`.
- **NFR-GROUP-003 (Performance)**: Hotkey dispatch < 50ms latency; preset placement execution for running apps < 500ms total elapsed time.
- **NFR-GROUP-004 (Public APIs Only)**: Exclusively public AppKit, SwiftUI, `NSWorkspace`, and AX APIs. Zero private CGS frameworks.
- **NFR-GROUP-005 (Schema Forward-Compatibility)**: Additive UserDefaults and JSON encoding; missing or unknown fields decode gracefully with defaults.

---

## 3. Verification Methods & Test Matrix

| REQ ID             | Method                           | Target Suite / Test Case                                                                                        |
| :----------------- | :------------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **REQ-PRESET-001** | Unit (Swift Testing `@Test`)     | `BuiltinPresetFactoryTests` — validates all 4 presets, slot ratios, normalized rects, and default shortcuts     |
| **REQ-PRESET-002** | Unit (Mock `NSWorkspace` double) | `PresetResolutionTests` — tests candidate fallback resolution across running, installed, and uninstalled chains |
| **REQ-PRESET-003** | Unit / Integration               | `PresetRestoreTimeoutTests` — tests 10s launch timeout handling, skip reasons, and `RestoreSummary` output      |
| **REQ-PRESET-004** | Unit / Integration               | `PresetDisplayMathTests` — tests layout calculation across different display sizes (e.g. 13" vs 27")            |
| **REQ-PRESET-005** | Unit                             | `CommandDispatcherPresetTests` — tests `.restorePreset(id)` dispatch and debouncing                             |
| **REQ-PRESET-006** | Unit / UI Test                   | `ShortcutCollisionTests` — tests rejection of colliding shortcuts with `ShortcutAction`                         |
| **REQ-PRESET-007** | UI Test / Manual                 | `PresetGalleryViewTests` & Menu Bar integration                                                                 |
| **REQ-GROUP-001**  | Unit                             | `WindowGroupManagerTests` — tests group creation, membership, and auto-dissolution (<2 members)                 |
| **REQ-GROUP-002**  | Unit (Mock AX double)            | `WindowGroupSyncTests` — tests simultaneous minimize and un-minimize propagation                                |
| **REQ-GROUP-003**  | Unit (Mock AX double)            | `WindowGroupSyncTests` — tests simultaneous focus with descending z-order preservation                          |
| **REQ-GROUP-004**  | Unit                             | `WindowGroupMoveTests` — tests group move delta translation                                                     |
| **REQ-GROUP-005**  | Unit                             | `WindowGroupReentrancyTests` — tests re-entrancy lock and echo loop prevention                                  |
| **REQ-GROUP-006**  | Unit                             | `WindowGroupLifecycleTests` — tests auto-pruning upon window destroy notifications                              |
| **REQ-GROUP-007**  | Unit                             | `WindowGroupSecurityTests` — tests AX pre-flight permission check                                               |
