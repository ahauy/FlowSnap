# Technical Specification: Settings UI & Shortcut Customization (US-SNAP-010)

## 1. Overview
This specification details the user-customizable shortcut management system and the 4-tab SwiftUI Settings window for FlowSnap.

## 2. Requirements & User Stories

### US-SNAP-010.1: Settings Tab Navigation
- **REQ-SET-101**: Settings window displays four tabs: `General`, `Shortcuts`, `Application Rules`, and `About`.
- **REQ-SET-102**: Selecting a tab immediately updates the view content with persistent tab selection.

### US-SNAP-010.2: Shortcut Customization & Conflict Detection
- **REQ-SET-201**: Users can view all configurable actions grouped by category (`Halves & Maximize`, `Quarter Screens`, `Asymmetric & Thirds`, `Display Navigation`).
- **REQ-SET-202**: Clicking on a shortcut field activates recording mode.
- **REQ-SET-203**: Recording captures modifier combinations (`⌃`, `⌥`, `⌘`, `⇧`) and virtual keycodes.
- **REQ-SET-204**: If a newly assigned shortcut conflicts with an existing action, a warning badge is shown and conflict resolution is supported.
- **REQ-SET-205**: Pressing `Escape` cancels recording; pressing `Delete` or clicking the clear button unassigns the shortcut.
- **REQ-SET-206**: "Restore Defaults" resets all shortcuts to the canonical 8 Carbon presets.

### US-SNAP-010.3: Preferences & General Configuration
- **REQ-SET-301**: Window gap selector persists clamped values {0, 4, 8, 12, 16} px.
- **REQ-SET-302**: Default layout split ratio selector persists {50/50, 60/40, 70/30, 80/20, 25/50/25}.
- **REQ-SET-303**: Toggle for Drag-to-Snap (`isDragToSnapEnabled`) and picker for preview delay.
- **REQ-SET-304**: Toggle for Launch at Login.

### US-SNAP-010.4: Dynamic Hotkey Re-Registration
- **REQ-SET-401**: When shortcuts change in `PreferencesStore`, `GlobalHotkeyManager` dynamically re-registers active bindings on the system Carbon dispatcher.
