# Plan: Settings UI & Shortcut Customization (US-SNAP-010)

## Architecture Overview
The settings and shortcut customization system connects SwiftUI UI views to `PreferencesStore`, which persists configurations via `UserDefaults` and notifies system listeners:

```
[SettingsView (4 Tabs)]
   ├── [GeneralSettingsView]  -----> [PreferencesStore] -----> [UserDefaults]
   ├── [ShortcutSettingsView] -----> [PreferencesStore]          │ (Combines)
   │     └── [ShortcutRecorderField]                             ▼
   ├── [ApplicationRulesView] ------> [WindowPolicyManager]   [GlobalHotkeyManager]
   └── [AboutSettingsView]                                       │ (Carbon Hotkeys)
                                                                 ▼
                                                              [macOS OS]
```

## Implementation Phases

### Phase 1: Domain Entities & Extensions
1. Implement `ShortcutAction` (enum with category, display names, default shortcuts, and window commands).
2. Extend `KeyboardShortcut` with Carbon virtual key code string converters, modifier helpers, and comparison helpers.

### Phase 2: Persistence & Store Extensions
1. Extend `PreferencesStore` with:
   - `customShortcuts: [ShortcutAction: KeyboardShortcut]`
   - `isDragToSnapEnabled: Bool`
   - `dragPreviewDwellDelay: Double`
   - `launchAtLogin: Bool`
   - `shortcut(for: ShortcutAction) -> KeyboardShortcut?`
   - `setShortcut(_: KeyboardShortcut?, for: ShortcutAction)`
   - `resetShortcutsToDefault()`
   - `hasConflict(_: KeyboardShortcut, excluding: ShortcutAction?) -> ShortcutAction?`
   - `shortcutsDidChange` notification / publisher

### Phase 3: Hotkey Manager Dynamic Re-registration
1. Update `GlobalHotkeyManaging` and `GlobalHotkeyManager` to support dynamic registration from `PreferencesStore`.
2. Connect `AppDelegate` to observe shortcut updates and reload active bindings.

### Phase 4: UI Components & Settings Views
1. Build `ShortcutRecorderField` with recording state, keydown listener, modifier badge rendering, conflict indicator, clear button, and Escape cancel.
2. Implement `ShortcutSettingsView` with category grouping, shortcut table, conflict warnings, and "Restore Defaults" button.
3. Enhance `GeneralSettingsView` with Drag-to-Snap switches and preview dwell delay controls.
4. Create `AboutSettingsView` with app version, accessibility status indicator, and repository links.
5. Update `SettingsView` to host all 4 tabs with appropriate framing.

### Phase 5: Testing & Verification
1. Add unit tests for `ShortcutAction`, `KeyboardShortcut`, and `PreferencesStore`.
2. Update `SettingsSnapshotRenderer` to generate visual snapshots of all 4 tabs.
3. Run `xcodebuild test` and verify 100% pass rate.
