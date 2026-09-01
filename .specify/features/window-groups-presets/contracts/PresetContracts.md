# Contracts: Workspace Presets & Fallback Engine (US-WORK-012)

**Feature Slug:** `window-groups-presets`  
**Status:** Engineering Interface Contract  
**Created:** 2026-09-01

---

## 1. `PresetResolving` Protocol & Engine — `FlowSnap/Core/Workspace/PresetResolver.swift`

```swift
import CoreGraphics
import Foundation

public protocol PresetResolving: Sendable {
    /// Resolves and executes a preset by its identifier (e.g. "builtin.coding").
    ///
    /// - Parameters:
    ///   - preset: The `WorkspacePreset` to restore.
    ///   - targetDisplay: Target display to frame windows within (nil defaults to active focused/cursor display).
    /// - Returns: A `RestoreSummary` indicating placed and skipped slots.
    @MainActor
    func restore(preset: WorkspacePreset, on targetDisplay: Display?) async throws -> RestoreSummary
}

@MainActor
public final class PresetResolver: PresetResolving {
    private let accessibilityService: any AccessibilityService
    private let windowManager: any WindowManaging
    private let displayManager: any DisplayManaging
    private let layoutEngine: any LayoutCalculating
    private let launcher: any ApplicationLaunching
    private let preferencesStore: PreferencesStore
    private let windowGroupManager: WindowGroupManager
    private let launchTimeout: TimeInterval

    public init(
        accessibilityService: any AccessibilityService,
        windowManager: any WindowManaging,
        displayManager: any DisplayManaging,
        layoutEngine: any LayoutCalculating,
        launcher: any ApplicationLaunching,
        preferencesStore: PreferencesStore,
        windowGroupManager: WindowGroupManager,
        launchTimeout: TimeInterval = 10.0
    ) {
        self.accessibilityService = accessibilityService
        self.windowManager = windowManager
        self.displayManager = displayManager
        self.layoutEngine = layoutEngine
        self.launcher = launcher
        self.preferencesStore = preferencesStore
        self.windowGroupManager = windowGroupManager
        self.launchTimeout = launchTimeout
    }

    public func restore(preset: WorkspacePreset, on targetDisplay: Display? = nil) async throws -> RestoreSummary
}
```

### Resolution Algorithm

1. **Pre-flight Check**: Verify `accessibilityService.isTrusted`; if false, throw `PresetError.accessibilityDenied`.
2. **Display Resolution**: Resolve target `Display` via `displayManager.display(for: window.frame, cursorPoint: nil)` or fallback to primary display. Extract `visibleFrame` and `primaryScreenHeight`.
3. **Slot Processing**: For each `PresetAppSlot` in `preset.slots`:
   - Iterate through `preferredBundleIDs` in prioritized order:
     - Check if running: Query `accessibilityService.resolvedWindows(of: pid)` for candidate bundle ID.
     - If running window found, select this candidate.
     - If not running, check if installed: Query `NSWorkspace.shared.urlForApplication(withBundleIdentifier:)`.
     - If installed, launch via `launcher.openApp(withBundleIdentifier:)` and await first window via `launcher.waitForFirstWindow(pid:timeout:10.0)`.
   - If candidate window resolved:
     - Calculate target frame: If `slot.normalizedRect` exists, compute via `WorkspaceManager.frameFromNormalizedRect(slot.normalizedRect, in: visibleFrame, gap: preferencesStore.windowGap)`. Otherwise compute via `layoutEngine.frame(for: slot.zone, in: visibleFrame, gap: preferencesStore.windowGap)`.
     - Convert frame to AX coordinates via `CoordinateTransformer.toAX(rect:targetFrame, primaryScreenHeight:primaryHeight)`.
     - Reposition window via `windowManager.move(window, to: axFrame, element: resolvedElement)`.
     - Record placed window ID in `placedWindowIDs`.
   - If no candidate could be resolved or launch timed out:
     - Record in `skipped` list with appropriate `SkipReason` (`.notInstalled` or `.launchTimeout`).
4. **Window Group Linking**: If `preset.autoGroupWindows` is true and `placedWindowIDs.count >= 2`:
   - Invoke `windowGroupManager.createGroup(name: preset.name, windowIDs: placedWindowIDs, syncOptions: .all)`.
5. **Summary Reporting**: Return `RestoreSummary(placedCount: placedWindowIDs.count, totalPlacements: preset.slots.count, skipped: skipped)`.

---

## 2. Command Dispatcher Extension — `FlowSnap/Core/Commands/CommandDispatcher.swift`

### Extended `WindowCommand` Enum

```swift
public enum WindowCommand: Hashable, Sendable {
    // MARK: - Snap
    case snap(SnapTarget, targetDisplayID: CGDirectDisplayID? = nil)

    // MARK: - Window Actions
    case maximize
    case restore
    case minimize

    // MARK: - Display
    case moveToDisplay(CGDirectDisplayID)

    // MARK: - Workspace
    case restoreWorkspace(UUID)
    case saveWorkspace(String)

    // MARK: - Presets (US-WORK-012)
    case restorePreset(String) // Preset ID, e.g. "builtin.coding"
}
```

### Routing in `CommandDispatcher.execute`

```swift
case .restorePreset(let presetID):
    guard let preset = BuiltinPresetFactory.preset(for: presetID) else {
        dispatcherLogger.warning("Preset not found for id '\(presetID)'")
        return false
    }
    guard let presetResolver = self.presetResolver else {
        dispatcherLogger.error("PresetResolver not configured in CommandDispatcher")
        return false
    }
    let summary = try await presetResolver.restore(preset: preset, on: nil)
    self.lastRestoreSummary = summary
    return summary.placedCount > 0
```

---

## 3. PreferencesStore Preset Extensions — `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift`

```swift
extension PreferencesStore {
    /// Returns the effective shortcut for a preset (customized or default from BuiltinPresetFactory).
    public func shortcut(forPresetID id: String) -> KeyboardShortcut? {
        if let custom = customPresetShortcuts[id] {
            return custom
        }
        return BuiltinPresetFactory.preset(for: id)?.defaultShortcut
    }

    /// Assigns or unassigns a custom shortcut for a preset.
    public func setShortcut(_ shortcut: KeyboardShortcut?, forPresetID id: String) {
        if let shortcut = shortcut {
            customPresetShortcuts[id] = shortcut
        } else {
            customPresetShortcuts.removeValue(forKey: id)
        }
        saveCustomPresetShortcuts()
    }

    /// Checks if a proposed shortcut conflicts with standard snap actions or other presets.
    public func hasPresetConflict(_ shortcut: KeyboardShortcut, excludingPresetID: String? = nil) -> String? {
        // 1. Check against standard snap shortcuts
        if let snapConflict = hasConflict(shortcut) {
            return "Shortcut already assigned to \(snapConflict.rawValue)"
        }
        // 2. Check against other presets
        for preset in BuiltinPresetFactory.allBuiltinPresets {
            if let excluding = excludingPresetID, preset.id == excluding {
                continue
            }
            if let bound = self.shortcut(forPresetID: preset.id), bound == shortcut {
                return "Shortcut already assigned to \(preset.name) preset"
            }
        }
        return nil
    }
}
```

---

## 4. Error Types

```swift
public enum PresetError: Error, Equatable, Sendable {
    case presetNotFound(String)
    case accessibilityDenied
    case noEligibleWindows
    case executionFailed(String)
}
```
