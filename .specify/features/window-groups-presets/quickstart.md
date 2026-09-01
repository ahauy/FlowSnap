# Quickstart & Verification Guide: Window Groups & Workspace Presets (US-WORK-012)

**Feature Slug:** `window-groups-presets`  
**Status:** Verification Guide  
**Created:** 2026-09-01

---

## 1. Prerequisites & Build Setup

1. **macOS Version**: macOS 14.0+ (Sonoma or Sequoia).
2. **Xcode**: Xcode 16.0+ with Swift 6.0 toolchain.
3. **Permissions**: Accessibility permission granted in System Settings > Privacy & Security > Accessibility.

### Generate Xcode Project & Build

```bash
xcodegen generate
xcodebuild build -scheme FlowSnap -destination 'platform=macOS'
```

### Run Unit & Integration Test Suites

```bash
xcodebuild test -scheme FlowSnapTests -destination 'platform=macOS'
```

---

## 2. Automated Test Coverage Matrix

| Test Suite                     | Purpose & Coverage                                                                                          |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| `BuiltinPresetFactoryTests`    | Verifies all 4 built-in presets (Coding, Research, Writing, Design), slots, ratios, and default shortcuts   |
| `PresetResolverTests`          | Verifies candidate fallback resolution across running, installed, and uninstalled app chains                |
| `PresetRestoreTimeoutTests`    | Verifies bounded 10.0s launch timeout handling, graceful skip, and `RestoreSummary` output                  |
| `PresetDisplayMathTests`       | Verifies dynamic visibleBounds calculation across various display resolutions (13" laptop vs 34" ultrawide) |
| `CommandDispatcherPresetTests` | Verifies `CommandDispatcher.dispatch(.restorePreset(id))` and latest-wins cancellation debouncing           |
| `ShortcutCollisionTests`       | Verifies collision rejection between preset shortcuts and `ShortcutAction.allCases`                         |
| `WindowGroupManagerTests`      | Verifies `WindowGroup` creation, minimum 2-member cardinality, and auto-dissolution (<2 members)            |
| `WindowGroupSyncTests`         | Verifies simultaneous minimize, un-minimize, and focus with descending z-order preservation                 |
| `WindowGroupReentrancyTests`   | Verifies re-entrancy generation locking and elimination of cyclic AX notification loops                     |
| `WindowGroupLifecycleTests`    | Verifies dynamic auto-pruning upon window destruction notifications                                         |

---

## 3. Manual Interactive Verification Scenarios

### Scenario A: Activate Coding Preset via Hotkey

1. Open VS Code (or TextEdit), Google Chrome (or Safari), and Terminal.
2. Press global hotkey `⌃⌥C` (Control + Option + C).
3. **Verify**:
   - Primary Code Editor occupies the left 60% of the active display.
   - Web Browser occupies the top-right 25% of the active display.
   - Terminal occupies the bottom-right 15% of the active display.
   - A non-blocking banner appears: _"Restored Coding Preset (3/3 windows)"_.

### Scenario B: Smart Fallback Resolution

1. Ensure a primary app (e.g. VS Code) is closed, while a secondary candidate (e.g. Xcode or TextEdit) is available.
2. Trigger the Coding Preset.
3. **Verify**:
   - FlowSnap identifies the running or installed fallback candidate.
   - Launches candidate if necessary and frames it into the editor slot within 10s.

### Scenario C: Linked Window Group Synchronization

1. After restoring the Coding preset with `autoGroupWindows` enabled, an active Window Group is established.
2. Click the yellow minimize button on the Code Editor.
3. **Verify**:
   - Browser and Terminal minimize simultaneously into the Dock.
4. Click the Code Editor icon in the Dock to un-minimize.
5. **Verify**:
   - All 3 windows un-minimize and restore together to their assigned screen positions.

### Scenario D: Presets Gallery & Shortcut Customization in Settings

1. Open FlowSnap Settings (`⌘,`) and navigate to the **Presets Gallery** tab.
2. Observe the 4 visual preset cards (Coding, Research, Writing, Design).
3. Click the shortcut recorder for Writing Preset and record a new shortcut `⌃⌥⇧W`.
4. **Verify**:
   - Shortcut registers immediately.
5. Attempt to record `⌃⌥←` (already used by Left Half).
6. **Verify**:
   - Recorder rejects input and displays inline conflict warning.
