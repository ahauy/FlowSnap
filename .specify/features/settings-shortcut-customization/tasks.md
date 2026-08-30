# Tasks: Settings UI & Shortcut Customization (US-SNAP-010)

## Phase 1: Domain Entities
- [x] T01: Create `FlowSnap/Domain/Hotkeys/ShortcutAction.swift` with categories, display names, default bindings, and command mappings.
- [x] T02: Extend `FlowSnap/Domain/Hotkeys/KeyboardShortcut.swift` with keycode character mappings (arrows, alphanumeric, special symbols) and Carbon/NSEvent modifier conversion.

## Phase 2: Persistence & State Management
- [x] T03: Update `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift` with shortcut persistence, conflict check, drag-to-snap switches, and reset to defaults.
- [x] T04: Add dynamic registration support to `GlobalHotkeyManaging` and `GlobalHotkeyManager`.
- [x] T05: Wire `AppDelegate` to observe shortcut changes and update Carbon hotkeys.

## Phase 3: UI Components & Settings Views
- [x] T06: Create `FlowSnap/UI/Settings/ShortcutRecorderField.swift` supporting interactive recording, keydown interception, modifier display, clear button, and Escape cancel.
- [x] T07: Create `FlowSnap/UI/Settings/ShortcutSettingsView.swift` with category sections, conflict badges, and restore defaults button.
- [x] T08: Update `FlowSnap/UI/Settings/GeneralSettingsView.swift` with Drag-to-Snap toggles and dwell delay controls.
- [x] T09: Create `FlowSnap/UI/Settings/AboutSettingsView.swift` with version info, permissions status, and links.
- [x] T10: Update `FlowSnap/UI/Settings/SettingsView.swift` to present 4 tabs with polished layout and frame.

## Phase 4: Unit Testing & Snapshot Verification
- [x] T11: Implement unit test suites in `FlowSnapTests/Domain/ShortcutActionTests.swift` and `FlowSnapTests/Infrastructure/PreferencesStoreTests.swift`.
- [x] T12: Update `FlowSnapTests/UI/SettingsSnapshotRenderer.swift` to render snapshots of General, Shortcuts, App Rules, and About tabs.
- [x] T13: Run `xcodebuild test` and confirm 100% test pass.

## Phase 5: Documentation & Handover
- [x] T14: Create `docs/features/settings-shortcut-customization/README.md`.
- [x] T15: Create `docs/user-guides/settings-shortcut-customization.md` with rendered screenshots.
- [x] T16: Update `docs/features/README.md` and `docs/PRODUCT_BACKLOG_ROADMAP.md`.
