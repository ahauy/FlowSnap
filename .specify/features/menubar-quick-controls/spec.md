# Technical Specification: Menu Bar Status Item & Quick Snap Controls (US-SNAP-005)

## 1. Scope & Objective

This specification details the architecture and implementation for `US-SNAP-005`: creating a native macOS Menu Bar Status Item with an interactive dropdown/popover for quick window snapping, permission status monitoring, and system management.

---

## 2. Functional Requirements

- **REQ-MENU-001 (Status Item Presence)**: FlowSnap must configure a persistent `NSStatusItem` in the system menu bar featuring the FlowSnap icon.
- **REQ-MENU-002 (Agent App Mode)**: `LSUIElement` in `Info.plist` must remain set to `true` to suppress Dock icon appearance and run as a dedicated menu bar utility.
- **REQ-MENU-003 (Target Window Capture & Focus)**: The Menu Bar view model must retain the last active application window prior to menu interaction. When a user clicks a snap action, the snap operation targets this window, immediately dismisses the menu, and returns keyboard/accessibility focus.
- **REQ-MENU-004 (Permission Status & Banner)**:
  - If accessibility permissions are not granted (`accessibilityService.isTrusted == false`), display an interactive alert banner `⚠️ Accessibility Permission Required [Grant Permission]`.
  - Clicking "Grant Permission" opens macOS System Settings to Privacy & Security > Accessibility.
  - When permissions are valid, the banner is hidden and snap actions are active.
- **REQ-MENU-005 (Snap Actions Grid)**:
  - Halves: Left (`⌃⌥←`), Right (`⌃⌥→`), Top, Bottom.
  - Full / Restore: Maximize (`⌃⌥↑`), Restore (`⌃⌥↓`).
  - Quarters: Top-Left (`⌃⌥1`), Top-Right (`⌃⌥2`), Bottom-Left (`⌃⌥3`), Bottom-Right (`⌃⌥4`).
- **REQ-MENU-006 (System Actions)**:
  - "Settings...": Opens the standard Settings scene.
  - "Quit FlowSnap": Gracefully unregisters hotkeys and shuts down the process.
- **REQ-MENU-007 (Visual Snap Canvas Grid)**:
  - Replaces text-heavy snap buttons with interactive miniature screen cards aligned with the design language of `SnapLayoutPickerView`.
  - Displays partitions for Left/Right halves, Top/Bottom halves, Maximize, and 4 Quarters with continuous corner radii and 1px hairline borders.
  - Clicking any partitioned slot triggers the corresponding `MenuBarAction` and automatically dismisses the popover.
- **REQ-MENU-008 (Compact Workspaces & Presets)**:
  - Caps workspace/preset menu list to at most 3-4 active items to keep menu height under 420px.
  - Provides direct "+" (Save Layout) and "Manage..." links leading to the dedicated Settings tabs.
- **REQ-MENU-009 (Modern Settings Window NavigationSplitView)**:
  - Upgrades `SettingsView` from unstyled `TabView` to macOS `NavigationSplitView`.
  - Left sidebar displays categorized sections (General, Shortcuts, Presets, Window Groups, App Rules, Workspaces, About) with vibrant SF Symbols.
  - Right detail pane embeds content inside a `ScrollView` with grouped card geometry, eliminating clipping and label redundancy.

---

## 3. Non-Functional Requirements

- **NFR-MENU-001 (Performance)**: Popover presentation and snap button click response latency < 30ms.
- **NFR-MENU-002 (Memory & Thread Safety)**: All UI state changes and AppKit interactions must be `@MainActor` isolated. Zero CPU polling when menu is closed.
- **NFR-MENU-003 (Aesthetics & Anti-AI-Slop)**: Native macOS styling, subtle 1px borders, standard system font typography, monochrome SF Symbols adapting to Light/Dark modes.
