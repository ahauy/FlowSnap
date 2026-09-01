# Traceability Matrix: Window Groups & Workspace Presets (US-WORK-012)

- **Feature**: `window-groups-presets`
- **Stage**: BA Pipeline — Stage 7/8: Traceability & Sign-off
- **Anchors**: ASM-GROUP-001 (app category fallbacks), ASM-GROUP-002 (group synchronization & lifecycle), ASM-GROUP-003 (hotkey routing & collision prevention)

---

## 1. Business Goal → Rule → PRD → SRS → Story → Test Target

| Business Goal / Need                                       | Business Rule / Assumption                  | PRD Requirement                | SRS Requirement                | User Story & Scenarios                                                                        | Target Test Suite / Case                                 |
| :--------------------------------------------------------- | :------------------------------------------ | :----------------------------- | :----------------------------- | :-------------------------------------------------------------------------------------------- | :------------------------------------------------------- |
| **G-01: Instant Curated Workflows** (OBJ-GROUP-01)         | BR-PRESET-001, BR-PRESET-004                | PRD-PRESET-001, PRD-PRESET-004 | REQ-PRESET-001, REQ-PRESET-004 | US-WORK-012.1: Sc. 1.1 (Coding), 1.2 (Research), 1.3 (Ultrawide)                              | `BuiltinPresetFactoryTests`, `PresetDisplayMathTests`    |
| **G-02: Zero-Config Tool Adaptability** (OBJ-GROUP-02)     | BR-PRESET-002, BR-PRESET-003, ASM-GROUP-001 | PRD-PRESET-002, PRD-PRESET-003 | REQ-PRESET-002, REQ-PRESET-003 | US-WORK-012.2: Sc. 2.1 (Fallback app), 2.2 (Missing category), 2.3 (Launch timeout)           | `PresetResolutionTests`, `PresetRestoreTimeoutTests`     |
| **G-03: Rapid Muscle-Memory Hotkeys** (OBJ-GROUP-01)       | BR-PRESET-005, BR-PRESET-006, ASM-GROUP-003 | PRD-PRESET-005, PRD-PRESET-006 | REQ-PRESET-005, REQ-PRESET-006 | US-WORK-012.1: Sc. 1.1 (Hotkey); US-WORK-012.4: Sc. 4.1 (Custom hotkey), 4.2 (Collision)      | `CommandDispatcherPresetTests`, `ShortcutCollisionTests` |
| **G-04: Coordinated Window Grouping** (OBJ-GROUP-03)       | BR-GROUP-001, BR-GROUP-002, ASM-GROUP-002   | PRD-GROUP-001, PRD-GROUP-002   | REQ-GROUP-001, REQ-GROUP-002   | US-WORK-012.3: Sc. 3.1 (Simultaneous Minimize & Restore)                                      | `WindowGroupManagerTests`, `WindowGroupSyncTests`        |
| **G-05: Focused Multi-Window Layering** (OBJ-GROUP-03)     | BR-GROUP-003, ASM-GROUP-002                 | PRD-GROUP-003                  | REQ-GROUP-003                  | US-WORK-012.3: Sc. 3.2 (Simultaneous Focus & Z-Order)                                         | `WindowGroupSyncTests` (Focus & Z-Order)                 |
| **G-06: Unified Spatial Repositioning** (OBJ-GROUP-03)     | BR-GROUP-004, ASM-GROUP-002                 | PRD-GROUP-004                  | REQ-GROUP-004                  | US-WORK-012.3: Sc. 3.3 (Simultaneous Move & Snap)                                             | `WindowGroupMoveTests`                                   |
| **G-07: Safe Non-Blocking Coordination** (OBJ-GROUP-04)    | BR-GROUP-005, BR-GROUP-006                  | PRD-GROUP-005, PRD-PRESET-003  | REQ-GROUP-005, REQ-GROUP-007   | US-WORK-012.3: Sc. 3.5 (Re-entrancy Echo); US-WORK-012.1: Sc. 1.4 (AX Guard)                  | `WindowGroupReentrancyTests`, `WindowGroupSecurityTests` |
| **G-08: Dynamic Lifecycle & Memory Safety** (OBJ-GROUP-04) | BR-GROUP-001, BR-GROUP-006                  | PRD-GROUP-001, PRD-GROUP-006   | REQ-GROUP-006                  | US-WORK-012.3: Sc. 3.4 (Window Close Auto-Dissolve); US-WORK-012.4: Sc. 4.3 (Manual Dissolve) | `WindowGroupLifecycleTests`                              |
| **G-09: Discoverable Presets & Groups UI**                 | BR-PRESET-001, BR-GROUP-001                 | PRD-GROUP-006                  | REQ-PRESET-007                 | US-WORK-012.4: Sc. 4.1 (Gallery view), 4.3 (Groups view); US-WORK-012.1: Sc. 1.2 (Popover)    | `PresetGalleryViewTests`, UI Manual Test                 |

---

## 2. Assumption Traceability

| Assumption ID     | Statement Summary                                                                                                                   | Business Rules               | PRD Requirements               | SRS Requirements                 | User Story Scenarios                              |
| :---------------- | :---------------------------------------------------------------------------------------------------------------------------------- | :--------------------------- | :----------------------------- | :------------------------------- | :------------------------------------------------ |
| **ASM-GROUP-001** | Categorized app fallback chains with prioritized resolution (Running → Installed → Auto-launch with ≤10s timeout → Skip + Summary). | BR-PRESET-002, BR-PRESET-003 | PRD-PRESET-002, PRD-PRESET-003 | REQ-PRESET-002, REQ-PRESET-003   | US-WORK-012.2 Sc. 2.1, 2.2, 2.3                   |
| **ASM-GROUP-002** | Live `WindowGroup` synchronization (minimize/restore, focus, move) with dynamic lifecycle auto-pruning.                             | BR-GROUP-001…004             | PRD-GROUP-001…004              | REQ-GROUP-001…004, REQ-GROUP-006 | US-WORK-012.3 Sc. 3.1, 3.2, 3.3, 3.4              |
| **ASM-GROUP-003** | Dedicated preset keyboard shortcuts routed via `CommandDispatcher` with UI collision prevention against snap shortcuts.             | BR-PRESET-005, BR-PRESET-006 | PRD-PRESET-005, PRD-PRESET-006 | REQ-PRESET-005, REQ-PRESET-006   | US-WORK-012.1 Sc. 1.1; US-WORK-012.4 Sc. 4.1, 4.2 |

---

## 3. Risk Traceability

| Risk ID            | Description Summary                                          | Mitigating Requirement(s)                                                        |
| :----------------- | :----------------------------------------------------------- | :------------------------------------------------------------------------------- |
| **RISK-GROUP-001** | Infinite Event Feedback Loop in Group Sync                   | REQ-GROUP-005 (Re-entrancy lock and generation token)                            |
| **RISK-GROUP-002** | Stale `CGWindowID` Retention & Dangling References           | REQ-GROUP-006 (Dynamic auto-pruning on AX destroy notification)                  |
| **RISK-GROUP-003** | Fallback App Cold Launch Hang / Slow Gatekeeper Check        | REQ-PRESET-003 (Bounded 10s launch timeout & non-blocking skip)                  |
| **RISK-GROUP-004** | Global Hotkey Collision with Standard Snap or System Hotkeys | REQ-PRESET-006 (Pre-validation & collision rejection)                            |
| **RISK-GROUP-005** | Multi-Display Resolution & Aspect Ratio Mismatch             | REQ-PRESET-004 (Display-aware visibleBounds calculation & minimum size clamping) |
| **RISK-GROUP-006** | Concurrent Rapid Preset Hotkey Invocations (Debounce Race)   | REQ-PRESET-005 (`CommandDispatcher` latest-wins task cancellation)               |
| **RISK-GROUP-007** | AX Permission Missing or Revoked                             | REQ-GROUP-007 (Pre-flight AX trust check)                                        |
| **RISK-GROUP-008** | Z-Order Inversion on Collective Focus                        | REQ-GROUP-003 (Preserve descending z-order, anchor window frontmost)             |

---

## 4. Coverage Summary

- **12 / 12** Business Rules (6 PRESET + 6 GROUP) mapped to PRD and SRS specifications.
- **14 / 14** SRS Requirements (7 PRESET + 7 GROUP) mapped directly to Gherkin user story scenarios and test targets.
- **3 / 3** Confirmed Assumptions (`ASM-GROUP-001…003`) traced end-to-end.
- **8 / 8** Identified Risks (`RISK-GROUP-001…008`) actively mitigated by formal requirements.
- **Zero** orphan requirements; **zero** orphan test cases.
