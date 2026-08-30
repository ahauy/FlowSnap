# Baseline: Settings UI & Shortcut Customization (US-SNAP-010)

- **Status**: SIGNED-OFF v1.0
- **Sign-off Date**: 2026-08-30
- **Feature Slug**: `settings-shortcut-customization`
- **Specification Reference**: US-SNAP-010 / Epic 09

## Executive Summary
Provides a comprehensive macOS-native SwiftUI Settings window that allows FlowSnap users to:
1. **General Tab**: Configure window gaps ({0, 4, 8, 12, 16} px), default layout split ratios (50/50, 60/40, 70/30, 80/20, 25/50/25), launch at login, and toggle Drag-to-Snap behaviors with dwell delay settings.
2. **Shortcuts Tab**: Customize key combinations for all snap actions using `ShortcutRecorderField`, with live conflict detection, unassigning, and one-click "Restore Defaults".
3. **Application Rules Tab**: Overview and configuration of per-application window behaviors.
4. **About Tab**: FlowSnap version information, system permissions status, GitHub repo and license links.

## Signed-Off Requirements Matrix
- `REQ-SET-001`: Settings window with 4 distinct SwiftUI tabs (General, Shortcuts, App Rules, About).
- `REQ-SET-002`: `ShortcutRecorderField` with responsive keyboard capture, modifier enforcement, Escape-to-cancel, and Delete-to-clear.
- `REQ-SET-003`: `PreferencesStore` reactive storage for custom shortcuts, drag-to-snap settings, launch at login, and gap/ratio preferences.
- `REQ-SET-004`: Real-time Carbon hotkey dynamic re-registration when shortcuts are changed in UI.
- `REQ-SET-005`: Visual conflict warning when assigning duplicate hotkeys.
- `REQ-SET-006`: Automated snapshot generation and unit test suite verifying Codable persistence and conflict algorithms.
