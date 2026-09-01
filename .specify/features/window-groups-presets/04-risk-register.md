# Risk Register & Scope Lock: Window Groups & Workspace Presets (US-WORK-012)

- **Feature**: `window-groups-presets`
- **Stage**: BA Pipeline — Stage 5: Risk & Contradiction Scanner
- **Anchors**: ASM-GROUP-001 (app category fallbacks), ASM-GROUP-002 (group synchronization & lifecycle), ASM-GROUP-003 (hotkey routing & collision prevention)

---

## 1. Risk Matrix

| Risk ID            | Description                                                                                                                                                                                                          | Probability | Impact | Mitigation Strategy                                                                                                                                                                                                  |
| :----------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------: | :----: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-GROUP-001** | **Infinite Event Feedback Loop in Group Sync**: Minimizing window A triggers programmatic minimize on window B, which fires an AX notification that re-triggers window A, creating an infinite cascade loop.         |    High     |  High  | Implement re-entrancy locking (`isSynchronizing` flag / generation token) in `WindowGroupManager` (BR-GROUP-005) to ignore echo events during active group dispatch.                                                 |
| **RISK-GROUP-002** | **Stale `CGWindowID` Retention & Dangling References**: Closed or crashed windows leave obsolete IDs in `WindowGroup.windowIDs`, causing `kAXErrorInvalidUIElement` errors when subsequent group operations execute. |   Medium    | Medium | Subscribe to `kAXUIElementDestroyedNotification` via `WorkspaceObserver`; automatically prune dead IDs from group membership and auto-dissolve groups when fewer than 2 members remain (BR-GROUP-001, BR-GROUP-005). |
| **RISK-GROUP-003** | **Fallback App Cold Launch Hang / Slow Gatekeeper Check**: Launching a heavy fallback app (e.g. Xcode) takes > 10s, blocking the preset restoration flow.                                                            |   Medium    |  High  | Bounded ~10s timeout per app slot (BR-PRESET-003); run fallback resolution asynchronously; skip timed-out slots with typed `SkipReason.launchTimeout` without aborting other slots; report in `RestoreSummary`.      |
| **RISK-GROUP-004** | **Global Hotkey Collision with Standard Snap or System Hotkeys**: User or default preset hotkey collides with standard snap shortcuts (e.g. `⌃⌥←`) or macOS system hotkeys.                                          |   Medium    | Medium | UI pre-validation in `ShortcutRecorderField` against `ShortcutAction.allCases` and active workspace/preset shortcuts (BR-PRESET-006); reject collisions with clear inline error messaging.                           |
| **RISK-GROUP-005** | **Multi-Display Resolution & Aspect Ratio Mismatch**: Applying a 3-pane preset (Coding: 60/25/15) on a small 13" laptop display vs a 34" ultrawide display causes window clipping or unusable aspect ratios.         |   Medium    | Medium | Presets store normalized proportional zones and `LayoutRatio` math (BR-PRESET-004); `LayoutEngine` clamps window frames to minimum usable sizes (`ManagedWindow.minSize`) and visible display bounds.                |
| **RISK-GROUP-006** | **Concurrent Rapid Preset Hotkey Invocations (Debounce Race)**: Rapid spamming of preset hotkeys (`⌃⌥C`, `⌃⌥R`) results in overlapping window re-positioning tasks.                                                  |   Medium    |  Low   | Latest-wins debouncing via `CommandDispatcher.pendingTask` cancellation (BR-PRESET-005); previous in-flight frame calculations are cancelled cleanly.                                                                |
| **RISK-GROUP-007** | **AX Permission Missing or Revoked**: Preset restoration or group operation invoked without active macOS Accessibility privileges.                                                                                   |     Low     |  High  | Pre-flight trust check via `AXAccessibilityService`; if untrusted, abort with zero partial window mutations and surface non-blocking system permission prompt.                                                       |
| **RISK-GROUP-008** | **Z-Order Inversion on Collective Focus**: Raising all group windows to the foreground in arbitrary order disrupts the user's intended layer stacking.                                                               |     Low     |  Low   | Enforce deterministic z-order activation in `WindowGroupManager.handleWindowFocus` (BR-GROUP-003), raising the anchor/frontmost window last so it remains top-level.                                                 |

---

## 2. Consolidated Assumptions (ASM → Risk Traceability)

| Assumption        | Decision Carried into Design                                                                                                      | Mitigated Risks                                |
| :---------------- | :-------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------- |
| **ASM-GROUP-001** | Categorized app fallback chains with prioritized resolution (Running → Installed → Auto-launch with 10s timeout → Skip + Report). | RISK-GROUP-003, RISK-GROUP-005                 |
| **ASM-GROUP-002** | Live `WindowGroup` synchronization (minimize, focus, move) with dynamic lifecycle auto-pruning and re-entrancy locking.           | RISK-GROUP-001, RISK-GROUP-002, RISK-GROUP-008 |
| **ASM-GROUP-003** | Dedicated preset keyboard shortcuts routed via `CommandDispatcher` with UI collision prevention against snap shortcuts.           | RISK-GROUP-004, RISK-GROUP-006                 |

---

## 3. Contradiction & Scope Lock (MoSCoW)

### Must-Have (P0 / Core)

- **Built-in Presets Factory**: 4 immutable standard presets (Coding, Research, Writing, Design) with relative split ratios and app categories.
- **Smart App Category Fallback Engine**: Prioritized candidate matching (Running → Installed → Auto-launch with 10s timeout → Graceful Skip).
- **Preset Hotkey Activation**: Configurable shortcuts for presets with `CommandDispatcher` routing and collision detection.
- **Window Group Core**: Aggregate entity, membership tracking, simultaneous minimize/un-minimize, simultaneous focus with z-order preservation.
- **Dynamic Group Auto-Pruning**: Automatic removal on window close and clean dissolution when count < 2.
- **Settings Presets Gallery**: Visual schematic cards showing layout previews and direct "Apply" action.

### Should-Have (P1)

- **Menu Bar Quick Presets**: Presets submenu in Menu Bar popover with direct trigger and hotkey badges.
- **Restore Summary Banner**: Non-blocking toast reporting restored count and skipped app reasons.
- **Group Move Synchronization**: Coordinated spatial repositioning of grouped windows across displays/zones.

### Could-Have (P2)

- **Custom User Preset Creation**: Ability to save an existing workspace as a reusable preset template with custom fallback chains.
- **Visual Group Highlight**: Subtle border tint or badge indicating linked window group membership.

### Won't-Have (Out of Scope for v1.0)

- **Cross-Space / Virtual Desktop Group Movement**: Moving windows across macOS Mission Control Spaces via private CGS APIs (strictly forbidden by Zero Private API policy).
- **Automated In-App Tab Merging**: Forcing multiple native app windows into a single unified tab container (requires undocumented AppKit hooks).
- **Cloud Sync / Online Community Presets Sharing**: Remote preset catalog downloading (local-first design principle).
- **App Launch Space Preservation**: Automatically trapping newly launched apps into current Space — blocked successor feature `US-WORK-013`.
