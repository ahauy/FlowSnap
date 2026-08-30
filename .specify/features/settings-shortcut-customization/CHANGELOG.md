# Changelog: Settings UI & Shortcut Customization (US-SNAP-010)

## [1.0.0] - 2026-08-30
### Added
- Created `ShortcutAction` domain enum mapping all window actions to default shortcuts and commands.
- Enhanced `KeyboardShortcut` with complete macOS virtual keycode to character mappings and modifier utilities.
- Extended `PreferencesStore` to persist custom shortcuts, drag-to-snap settings, and conflict checks.
- Created `ShortcutRecorderField` interactive component with live recording and conflict warning.
- Implemented 4-tab `SettingsView` (General, Shortcuts, Application Rules, About).
- Added snapshot tests and unit test suites.
