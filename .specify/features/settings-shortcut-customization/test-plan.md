# Test Plan: Settings UI & Shortcut Customization (US-SNAP-010)

## Overview
Validates shortcut model encoding, conflict detection, preference persistence, custom shortcut updates, dynamic hotkey re-registration, and UI snapshot rendering.

## Test Cases

| Test Case ID | Target | Description | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **TC-SET-001** | `ShortcutAction` | Action default shortcuts, commands, and display names. | All 10+ actions provide valid display strings, categories, and commands. |
| **TC-SET-002** | `KeyboardShortcut` | Keycode to string conversion (arrows, numbers, letters, symbols) and modifier masks. | Accurate glyph rendering (e.g. `⌃⌥←`, `⌘⇧P`). |
| **TC-SET-003** | `PreferencesStore` | Serialization of custom shortcuts to `UserDefaults`. | Encoded JSON decodes identically upon store re-initialization. |
| **TC-SET-004** | `PreferencesStore` | Conflict detection between assigned shortcuts. | Returns conflicting `ShortcutAction` if key combination matches another action. |
| **TC-SET-005** | `PreferencesStore` | Reset shortcuts to default. | Reverts custom shortcuts dictionary to nil / canonical presets. |
| **TC-SET-006** | `PreferencesStore` | Drag-to-snap switches and dwell delay settings. | Persists booleans and doubles correctly. |
| **TC-SET-007** | `GlobalHotkeyManager` | Dynamic hotkey update from PreferencesStore. | Unregisters previous bindings and registers updated custom hotkeys. |
| **TC-SET-008** | `SettingsSnapshotRenderer` | Snapshot rendering for all 4 Settings tabs. | PNG snapshots generated without layout overflow. |
