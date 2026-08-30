# FlowSnap End-User Documentation Index

Welcome to the **FlowSnap User Guides**! This directory contains step-by-step visual documentation, shortcuts, workflows, and troubleshooting tips for all FlowSnap features.

---

## 📚 Available Feature User Guides

| Epic / Slug     | Feature Title                                           | Key Topics Covered                                                                                                                                                                  |                    Guide Link                    |
| :-------------- | :------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------: |
| **US-SNAP-001** | **Accessibility Permission & Focused Window Discovery** | • macOS Accessibility setup<br>• Permission trust verification<br>• Foreground window inspection<br>• Modal sheet/dialog safety guards                                              | [View Guide](accessibility-window-discovery.md)  |
| **US-SNAP-002** | **Core Layout Calculation & Basic Snap Engine**         | • Zero-gap 50/50 halves<br>• 4-corner 25% quadrant tiling<br>• Maximize & visible bounds<br>• Pre-snap frame storage & instant restore                                              |     [View Guide](core-layout-snap-engine.md)     |
| **US-SNAP-003** | **Display-Aware Multi-Monitor Manipulation**            | • AppKit vs Accessibility coordinate inversion<br>• Multi-display boundary resolution<br>• Cross-screen window hops<br>• Mirrored display handling                                  |   [View Guide](display-aware-manipulation.md)    |
| **US-SNAP-004** | **Global Hotkeys & Command Dispatcher**                 | • System-wide `⌃⌥` shortcut map<br>• Low-latency (<50ms) async pipeline<br>• Rapid-key debouncing<br>• Key conflict resilience                                                      |    [View Guide](global-hotkeys-dispatcher.md)    |
| **US-SNAP-005** | **Menu Bar Status Item & Quick Snap Controls**          | • Lightweight menu bar utility<br>• 10-button quick snap matrix<br>• Auto-dismiss & focus return<br>• In-menu permission alerts & deep links                                        |     [View Guide](menubar-quick-controls.md)      |
| **US-SNAP-006** | **Drag-to-Snap & HUD Snap Preview**                     | • Edge & corner drag gestures<br>• Translucent Liquid Glass HUD preview<br>• Multi-monitor screen crossing friction<br>• Snap gesture cancellation                                  |      [View Guide](drag-to-snap-preview.md)       |
| **US-SNAP-007** | **Top-Edge Snap Layout Picker**                         | • Top-edge mouse flyout trigger<br>• Windows 11-style layout templates<br>• Interactive slot hovering & preview<br>• 2-col, 3-col & 4-quadrant presets                              |     [View Guide](top-edge-layout-picker.md)      |
| **US-SNAP-008** | **Custom Split Ratios & Window Gaps**                   | • Asymmetric ratios (60/40, 70/30, 80/20, 25/50/25)<br>• Aesthetic gap presets (`0px` to `16px`)<br>• Live Settings visualizer<br>• Uniform outer/inner margin geometry             |    [View Guide](custom-ratios-window-gaps.md)    |
| **US-SNAP-009** | **Adaptive Multi-Window Divider Resize**                | • Smart divider hover & cursor morph (`⬌`/`⬍`)<br>• Simultaneous T-junction multi-window resizing<br>• Minimum window size protection<br>• 60fps smooth throttling                  |     [View Guide](adaptive-divider-resize.md)     |
| **US-SNAP-010** | **Settings & Shortcut Customization**                   | • SwiftUI floating settings panel (`.floating`)<br>• Interactive shortcut recorder with conflict detection<br>• Dynamic 2-column ratio picker sync<br>• Launch at login & app rules | [View Guide](settings-shortcut-customization.md) |

---

## ⚡ Quick Reference: Default Keyboard Shortcuts

| Shortcut  | Action           | Description                                                                  |
| :-------- | :--------------- | :--------------------------------------------------------------------------- |
| **`⌃⌥←`** | **Snap Left**    | Snaps active window to the left 50% of the screen.                           |
| **`⌃⌥→`** | **Snap Right**   | Snaps active window to the right 50% of the screen.                          |
| **`⌃⌥↑`** | **Maximize**     | Expands window to fill 100% of visible desktop (respecting Dock & Menu Bar). |
| **`⌃⌥↓`** | **Restore**      | Restores window to its exact pre-snap position and size.                     |
| **`⌃⌥1`** | **Top-Left**     | Snaps window to the top-left 25% corner quadrant.                            |
| **`⌃⌥2`** | **Top-Right**    | Snaps window to the top-right 25% corner quadrant.                           |
| **`⌃⌥3`** | **Bottom-Left**  | Snaps window to the bottom-left 25% corner quadrant.                         |
| **`⌃⌥4`** | **Bottom-Right** | Snaps window to the bottom-right 25% corner quadrant.                        |
| **`⌘,`**  | **Settings**     | Opens the FlowSnap preferences window.                                       |
| **`⌘Q`**  | **Quit**         | Gracefully closes FlowSnap and releases system hotkeys.                      |

---

## 🖼️ User Guide Screenshots & Visual Assets

All visual guide assets and annotated screenshots are organized under [`images/`](images/) by feature slug:

- [`images/accessibility-window-discovery/`](images/accessibility-window-discovery/)
- [`images/core-layout-snap-engine/`](images/core-layout-snap-engine/)
- [`images/display-aware-manipulation/`](images/display-aware-manipulation/)
- [`images/global-hotkeys-dispatcher/`](images/global-hotkeys-dispatcher/)
- [`images/menubar-quick-controls/`](images/menubar-quick-controls/)
- [`images/drag-to-snap-preview/`](images/drag-to-snap-preview/)
- [`images/top-edge-layout-picker/`](images/top-edge-layout-picker/)
- [`images/custom-ratios-window-gaps/`](images/custom-ratios-window-gaps/)
