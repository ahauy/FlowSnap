# FlowSnap End-User Documentation Index

Welcome to the **FlowSnap User Guides**! This directory contains step-by-step visual documentation, shortcuts, workflows, and troubleshooting tips for all FlowSnap features.

---

## 📚 Available Feature User Guides

| Epic / Slug     | Feature Title                                           | Key Topics Covered                                                                                                                                                                                                             |                     Guide Link                     |
| :-------------- | :------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------: |
| **US-SNAP-001** | **Accessibility Permission & Focused Window Discovery** | • macOS Accessibility setup<br>• Permission trust verification<br>• Foreground window inspection<br>• Modal sheet/dialog safety guards                                                                                         |  [View Guide](accessibility-window-discovery.md)   |
| **US-SNAP-002** | **Core Layout Calculation & Basic Snap Engine**         | • Zero-gap 50/50 halves<br>• 4-corner 25% quadrant tiling<br>• Maximize & visible bounds<br>• Pre-snap frame storage & instant restore                                                                                         |      [View Guide](core-layout-snap-engine.md)      |
| **US-SNAP-003** | **Display-Aware Multi-Monitor Manipulation**            | • AppKit vs Accessibility coordinate inversion<br>• Multi-display boundary resolution<br>• Cross-screen window hops<br>• Mirrored display handling                                                                             |    [View Guide](display-aware-manipulation.md)     |
| **US-SNAP-004** | **Global Hotkeys & Command Dispatcher**                 | • System-wide `⌃⌥` shortcut map<br>• Low-latency (<50ms) async pipeline<br>• Rapid-key debouncing<br>• Key conflict resilience                                                                                                 |     [View Guide](global-hotkeys-dispatcher.md)     |
| **US-SNAP-005** | **Menu Bar Status Item & Quick Snap Controls**          | • Lightweight menu bar utility<br>• 10-button quick snap matrix<br>• Auto-dismiss & focus return<br>• In-menu permission alerts & deep links                                                                                   |      [View Guide](menubar-quick-controls.md)       |
| **US-SNAP-006** | **Drag-to-Snap & HUD Snap Preview**                     | • Edge & corner drag gestures<br>• Translucent Liquid Glass HUD preview<br>• Multi-monitor screen crossing friction<br>• Snap gesture cancellation                                                                             |       [View Guide](drag-to-snap-preview.md)        |
| **US-SNAP-007** | **Top-Edge Snap Layout Picker**                         | • Top-edge mouse flyout trigger<br>• Windows 11-style layout templates<br>• Interactive slot hovering & preview<br>• 2-col, 3-col & 4-quadrant presets                                                                         |      [View Guide](top-edge-layout-picker.md)       |
| **US-SNAP-008** | **Custom Split Ratios & Window Gaps**                   | • Asymmetric ratios (60/40, 70/30, 80/20, 25/50/25)<br>• Aesthetic gap presets (`0px` to `16px`)<br>• Live Settings visualizer<br>• Uniform outer/inner margin geometry                                                        |     [View Guide](custom-ratios-window-gaps.md)     |
| **US-SNAP-009** | **Adaptive Multi-Window Divider Resize**                | • Smart divider hover & cursor morph (`⬌`/`⬍`)<br>• Simultaneous T-junction multi-window resizing<br>• Minimum window size protection<br>• 60fps smooth throttling                                                             |      [View Guide](adaptive-divider-resize.md)      |
| **US-SNAP-010** | **Settings & Shortcut Customization**                   | • SwiftUI floating settings panel (`.floating`)<br>• Interactive shortcut recorder with conflict detection<br>• Dynamic 2-column ratio picker sync<br>• Launch at login & app rules                                            |  [View Guide](settings-shortcut-customization.md)  |
| **US-WORK-011** | **Workspace Snapshot & Intent Restoration**             | • Save multi-window layout as a named workspace<br>• One-tap restore with auto-launch of closed apps<br>• Cross-display restoration (intent, not pixels)<br>• Rename / delete in Settings → Workspaces                         |  [View Guide](workspace-snapshot-restoration.md)   |
| **US-WORK-012** | **Window Groups & Workspace Presets**                   | • 4 curated workflow presets (Coding, Research, Writing, Design)<br>• Smart app category fallbacks & auto-launch<br>• Linked window groups (minimize, focus, move together)<br>• Hotkey customization & collision prevention   |       [View Guide](window-groups-presets.md)       |
| **US-WORK-013** | **App Launch Observer & Current Space Policy**          | • Automatic active desktop space interception<br>• Zero-polling launch detection via NSWorkspace<br>• First window AXObserver safety net<br>• No Spaces switching disruption                                                   |  [View Guide](app-launch-current-space-policy.md)  |
| **US-WORK-014** | **Per-App Window Rules & Smart Floating Stack**         | • Floating app immunity from tiling<br>• Smart focus restoration to underlying windows<br>• Clamped multi-monitor remembered positions<br>• Assigned canonical layout zones (70/30, halves)                                    |   [View Guide](per-app-rules-floating-stack.md)    |
| **US-DISP-015** | **Cross-Display Window Throw & Target-Aware Snap**      | • Instant cross-monitor navigation<br>• Global shortcuts `⌃⌥⇧→` and `⌃⌥⇧←`<br>• Auto cursor warping to target window<br>• Semantic snap preservation & relative scaling                                                        |    [View Guide](cross-display-window-throw.md)     |
| **US-DISP-016** | **Display Topology Profiles & Hot-Plug Rebalancer**     | • Deterministic SHA-256 display topology fingerprinting<br>• 600ms coalescing debounce on screen change<br>• Safe proportional clamping on unplug (title bar visible)<br>• Zero-prompt auto-restore on reconnect               | [View Guide](display-topology-profiles-hotplug.md) |
| **US-WORK-018** | **Stage Manager Multi-Window Auto-Grouping**            | • Dynamic Stage Manager detection (`com.apple.WindowManager`)<br>• Smart Stage Coordination (Anchor app + `kAXRaiseAction`)<br>• Multi-window workspace co-existence on a single Stage<br>• Primary window keyboard focus lock |    [View Guide](stage-manager-auto-grouping.md)    |
| **US-WORK-019** | **Universal Fullscreen Escape for Electron/Native**     | • 3-tier resilient escape hierarchy<br>• Electron & Chromium zoom button press<br>• Target PID ⌃⌘F keystroke dispatch<br>• Adaptive 100ms space transition polling                                                             |    [View Guide](universal-fullscreen-escape.md)    |

---

## ⚡ Quick Reference: Default Keyboard Shortcuts

| Shortcut  | Action              | Description                                                                  |
| :-------- | :------------------ | :--------------------------------------------------------------------------- |
| **`⌃⌥C`** | **Coding Preset**   | 60/25/15 layout: Code Editor (60%), Browser (25%), Terminal (15%).           |
| **`⌃⌥R`** | **Research Preset** | 50/25/25 layout: Main Browser (50%), Notes (25%), Reference Browser (25%).   |
| **`⌃⌥W`** | **Writing Preset**  | 70/30 layout: Document Editor (70%), Reference Browser (30%).                |
| **`⌃⌥D`** | **Design Preset**   | 70/30 layout: Design Canvas (70%), Assets & Preview Browser (30%).           |
| **`⌃⌥←`** | **Snap Left**       | Snaps active window to the left 50% of the screen.                           |
| **`⌃⌥→`** | **Snap Right**      | Snaps active window to the right 50% of the screen.                          |
| **`⌃⌥↑`** | **Maximize**        | Expands window to fill 100% of visible desktop (respecting Dock & Menu Bar). |
| **`⌃⌥↓`** | **Restore**         | Restores window to its exact pre-snap position and size.                     |
| **`⌃⌥1`** | **Top-Left**        | Snaps window to the top-left 25% corner quadrant.                            |
| **`⌃⌥2`** | **Top-Right**       | Snaps window to the top-right 25% corner quadrant.                           |
| **`⌃⌥3`** | **Bottom-Left**     | Snaps window to the bottom-left 25% corner quadrant.                         |
| **`⌃⌥4`** | **Bottom-Right**    | Snaps window to the bottom-right 25% corner quadrant.                        |
| **`⌘,`**  | **Settings**        | Opens the FlowSnap preferences window.                                       |
| **`⌘Q`**  | **Quit**            | Gracefully closes FlowSnap and releases system hotkeys.                      |

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
- [`images/settings-shortcut-customization/`](images/settings-shortcut-customization/)
- [`images/workspace-snapshot-restoration/`](images/workspace-snapshot-restoration/)
- [`images/app-launch-current-space-policy/`](images/app-launch-current-space-policy/)
- [`images/cross-display-window-throw/`](images/cross-display-window-throw/)
- [`images/display-topology-profiles-hotplug/`](images/display-topology-profiles-hotplug/)
- [`images/stage-manager-auto-grouping/`](images/stage-manager-auto-grouping/)

Each folder is regenerated by a standalone Swift script in [`scripts/`](../../scripts/), e.g.:

```bash
swiftc -parse-as-library -O scripts/render_workspace_screenshots.swift -o /tmp/render_workspace
/tmp/render_workspace
```
