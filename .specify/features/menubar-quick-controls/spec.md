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

---

## 3. Non-Functional Requirements

- **NFR-MENU-001 (Performance)**: Popover presentation and snap button click response latency < 30ms.
- **NFR-MENU-002 (Memory & Thread Safety)**: All UI state changes and AppKit interactions must be `@MainActor` isolated. Zero CPU polling when menu is closed.
- **NFR-MENU-003 (Aesthetics & Anti-AI-Slop)**: Native macOS styling, subtle 1px borders, standard system font typography, monochrome SF Symbols adapting to Light/Dark modes.
