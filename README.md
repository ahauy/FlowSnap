# FlowSnap 🪟⚡

<p align="center">
  <strong>Your Mac. Your Layout. Your Flow.</strong><br>
  <em>Native macOS window manager and intent-based workspace orchestrator built with Swift 6.</em>
</p>

<p align="center">
  <a href="README.vi.md">🇻🇳 Tiếng Việt</a> •
  <a href="#key-features">Features</a> •
  <a href="#installation--getting-started">Installation</a> •
  <a href="#keyboard-shortcuts">Shortcuts</a> •
  <a href="#architecture--engineering">Architecture</a> •
  <a href="#documentation">Docs</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma%20%2F%20Sequoia)-black?style=flat-square&logo=apple" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-6.0%20Strict%20Concurrency-orange?style=flat-square&logo=swift" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Tests-358%20Passing%20(55%20Suites)-brightgreen?style=flat-square" alt="Tests 358 Passing">
  <img src="https://img.shields.io/badge/Apple%20API-100%25%20Zero%20Private%20APIs-blue?style=flat-square" alt="Zero Private APIs">
  <img src="https://img.shields.io/badge/Architecture-DDD%20%26%20Deep%20Modules-purple?style=flat-square" alt="DDD Architecture">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
</p>

---

## 🌟 Why FlowSnap?

The default macOS window management experience forces users to repeatedly perform manual resizing, wrestle with restrictive Split Views, or suffer jarring desktop transitions when opening new applications.

One of the biggest productivity killers on macOS is **unwanted Space hopping**: opening an app suddenly pulls you across to another Desktop/Space, breaking your mental focus.

**FlowSnap** solves this with a singular core principle:

> **You decide where windows belong. FlowSnap takes care of the rest.**

FlowSnap combines the visual elegance of **Windows 11-style Snap Layouts** with a powerful **Intent-Based Workspace Engine** designed from the ground up for macOS.

---

## ✨ Key Features

### 1. 🪟 Windows 11-Style Top-Edge Snap Layout Picker

Drag any window towards the top center edge of your screen to summon an instant layout picker. Hover over partition zones (50/50, 70/30, 3-column, 4-quarters) and release to snap windows into place with zero effort.

<p align="center">
  <img src="docs/user-guides/images/top-edge-layout-picker/01_layout_picker_flyout.png" width="750" alt="FlowSnap Top-Edge Layout Picker">
</p>

---

### 2. ⚡ Interactive Drag-to-Snap & Real-Time HUD Preview

Drag windows to screen boundaries or corners to trigger real-time translucent HUD snap overlays with smooth spring-physics animations. Drop to snap; drag away to cancel.

<p align="center">
  <img src="docs/user-guides/images/drag-to-snap-preview/01_drag_to_snap_left_half.png" width="750" alt="FlowSnap Drag to Snap Preview">
</p>

---

### 3. ↔️ Adaptive Multi-Window Resize & Inner/Outer Gaps

Resizing one window shouldn't require manually adjusting its neighbor. FlowSnap detects **collinear shared dividers** between tiled windows—dragging the boundary line resizes both windows simultaneously in real time (locked at 60 FPS).

Configure aesthetic inner and outer window gaps for clean, modern tiled desk setups.

<p align="center">
  <img src="docs/user-guides/images/custom-ratios-window-gaps/03_general_settings_16px_tiling.png" width="750" alt="FlowSnap Gaps and Tiling">
</p>

---

### 4. 🪐 Current Space Anchoring (Zero Unwanted Space Jumping)

Never get pulled away from your active Desktop again. FlowSnap continuously observes application launches and guarantees that new windows appear **strictly within your current Space and Display**, preserving your flow state without using any private Apple APIs.

<p align="center">
  <img src="docs/user-guides/images/app-launch-current-space-policy/01_current_space_anchoring.png" width="750" alt="FlowSnap Current Space Anchoring">
</p>

---

### 5. 🗂️ Intent-Based Workspaces & Workflow Presets

Save your entire multi-window layout as a named **Workspace** (e.g. _Coding_, _Research_, _Writing_). Workspaces store geometric intent rather than rigid pixel values, allowing seamless restoration across different display sizes and external monitors.

- **Curated Builtin Presets**: Quick-start templates for common workflows.
- **Linked Window Groups**: Group related windows so minimizing or moving one acts cohesively across the set.

<p align="center">
  <img src="docs/user-guides/images/workspace-snapshot-restoration/01_save_workspace_sheet.png" width="750" alt="FlowSnap Save Workspace Sheet">
</p>

---

### 6. 📌 Per-App Window Policies & Smart Floating Stack

Define dedicated rules per application bundle ID:

- **Floating**: Keep lightweight utilities (Calculator, Dictionary, Notes) floating above your tiled workspace.
- **Remember Position**: Automatically clamp and remember last-closed positions.
- **Assigned Layout**: Force specific apps (like Slack or Spotify) into predetermined screen zones.
- **Smart Focus Stack**: Closing a floating window immediately hands keyboard focus back to your primary tiled application underneath.

<p align="center">
  <img src="docs/user-guides/images/settings-shortcut-customization/03_application_rules_tab.png" width="750" alt="FlowSnap Per-App Rules Settings">
</p>

---

### 7. ⌨️ Global Hotkeys & Native Menu Bar Quick Controls

Trigger any snap zone instantly with system-wide keyboard shortcuts powered by low-latency Carbon Event Hotkeys. Features a reactive shortcut recorder with conflict detection and an unobtrusive menu bar companion.

<p align="center">
  <img src="docs/user-guides/images/settings-shortcut-customization/02_shortcuts_tab.png" width="370" alt="FlowSnap Shortcut Customization">
  <img src="docs/user-guides/images/menubar-quick-controls/01_menubar_quick_snap_menu.png" width="370" alt="FlowSnap Menu Bar Quick Snap">
</p>

---

## 🏗️ Architecture & Engineering

FlowSnap is engineered with uncompromising software quality, adhering to Domain-Driven Design (DDD) and John Ousterhout's _Deep Modules_ philosophy.

```
FlowSnap/
├── Domain/           # Pure business rules, math, coordinate transforms & interfaces (Zero OS deps)
│   ├── Model/        # ManagedWindow, LayoutZone, Workspace, AppPolicyRule
│   ├── Services/     # SnapEngine, LayoutEngine, CollinearEdgeDetector
│   └── Ports/        # AccessibilityServing, DisplayManaging, GlobalHotkeyManaging
├── Core/             # State coordination & high-leverage services
│   ├── Workspace/    # WorkspaceManager, PresetResolver, WindowGroupManager
│   ├── Policy/       # WindowPolicyManager, SmartFocusStack, FrameClampingHelper
│   └── Dispatcher/   # CommandDispatcher, LiveResizeThrottler
├── Infrastructure/   # Adapters to macOS system services
│   ├── Accessibility/# AXUIElement adapter, AXObserver lifecycle
│   ├── Hotkey/       # Carbon RegisterEventHotKey daemon
│   ├── Display/      # AppKit NSScreen observer & monitor topology
│   └── Persistence/  # Atomic JSON storage & UserDefaults PreferencesStore
└── UI/               # Declarative SwiftUI views & non-activating NSPanels
    ├── SnapPreview/  # Translucent ghost overlay panel
    ├── LayoutPicker/ # Top-edge Windows 11-style interactive flyout
    ├── MenuBar/      # NSStatusItem & popover quick controls
    └── Settings/     # Full-featured tabbed settings & shortcut recorder
```

### Engineering Guarantees

- **100% Swift 6.0 Concurrency**: Full actor isolation, `@MainActor` UI synchronization, and `Sendable` domain contracts. Zero data races.
- **100% Zero Private APIs**: Fully verified with automated symbol audits (`audit-no-private-apis.sh`). No unsafe `CGS*` or `SLS*` private calls. Hardened Runtime and notarization ready.
- **Rigorous Test Coverage**: **358 automated tests** across 55 test suites using Swift Testing (`@Test`) and XCTest, backed by protocol-based mock doubles.
- **Sub-Millisecond Performance**: Snap calculations execute in under **1ms**; live divider drags maintain continuous **60 FPS**; idle CPU consumption is **~0.0%**.

---

## 🚀 Installation & Getting Started

### System Requirements

- **macOS 14.0 (Sonoma)** or **macOS 15.0+ (Sequoia)**
- Apple Silicon (M1/M2/M3/M4) or Intel (x86_64)

---

### Option 1: Package & Run DMG (Recommended)

You can build and package a standalone, drag-and-drop `.dmg` installer with a single command:

```bash
git clone https://github.com/ahauy/FlowSnap.git
cd FlowSnap
./scripts/build-dmg.sh
```

This generates `build/FlowSnap-1.3.0.dmg`. Double-click or open it:

```bash
open build/FlowSnap-*.dmg
```

Drag **FlowSnap** into your **Applications** folder, and you're ready to go!

---

### Option 2: Build from Source with Xcode

1. Ensure **Xcode 16+** and **XcodeGen** are installed:

   ```bash
   brew install xcodegen
   ```

2. Generate the project and compile:

   ```bash
   xcodegen generate
   xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnap -destination 'platform=macOS' build
   ```

3. Launch FlowSnap:
   ```bash
   open $(find ~/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug -name "FlowSnap.app" | head -n 1)
   ```

---

### 🛡️ Granting Accessibility Permissions

FlowSnap requires macOS **Accessibility** permission to reposition and resize windows via the native macOS Accessibility API.

1. On first launch, click **Open System Settings** in the prompt.
2. Navigate to **Privacy & Security → Accessibility**.
3. Toggle the switch **ON** for **FlowSnap**.

> [!TIP]
> **Troubleshooting permission cache issues:** If macOS keeps showing untrusted after re-building the app, reset the TCC cache with:
>
> ```bash
> tccutil reset Accessibility com.flowsnap.app
> ```

---

## ⌨️ Default Keyboard Shortcuts

| Action                    | Shortcut  | Description                                       |
| :------------------------ | :-------: | :------------------------------------------------ |
| **Snap Left Half**        |  `⌥ ⌃ ←`  | Snap focused window to left half                  |
| **Snap Right Half**       |  `⌥ ⌃ →`  | Snap focused window to right half                 |
| **Snap Top Half**         |  `⌥ ⌃ ↑`  | Snap focused window to top half                   |
| **Snap Bottom Half**      |  `⌥ ⌃ ↓`  | Snap focused window to bottom half                |
| **Maximize Window**       |  `⌥ ⌃ ↩`  | Maximize window within visible display bounds     |
| **Restore Previous Size** |  `⌥ ⌃ ⌫`  | Restore window to bounds before snapping          |
| **Center Window**         |  `⌥ ⌃ C`  | Center window on current screen                   |
| **Next Display**          |  `⌥ ⌃ ⇥`  | Move focused window to next connected monitor     |
| **Previous Display**      | `⌥ ⌃ ⇧ ⇥` | Move focused window to previous connected monitor |
| **Save Workspace**        |  `⌥ ⌃ S`  | Open quick save workspace dialog                  |
| **Restore Workspace**     |  `⌥ ⌃ R`  | Cycle through or restore last workspace           |

_All shortcuts can be customized or disabled in **Preferences → Shortcuts**._

---

## 🧪 FlowSnapLab (Developer Interactive Testbed)

FlowSnap includes a standalone companion target called **FlowSnapLab** designed for interactive manual QA, permission diagnosis, and layout boundary inspection.

To run FlowSnapLab:

```bash
xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnapLab -destination 'platform=macOS' build
open $(find ~/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug -name "FlowSnapLab.app" | head -n 1)
```

---

## 📚 Documentation Index

- 📖 [**Product Roadmap & Requirements**](docs/PRODUCT_BACKLOG_ROADMAP.md) — Complete 12-Epic specifications and design principles.
- 🧩 [**Feature Documentation Index**](docs/features/README.md) — Detailed engineering specs for each implemented feature.
- 🖼️ [**User Guides with Screenshots**](docs/user-guides/README.md) — Visual walkthroughs for all capabilities.
- 📐 [**Architecture Decision Records (ADR)**](adr/) — Load-bearing architectural decisions (ADR-0001 through ADR-0010).
- 🧪 [**Run & Test Guide**](docs/RUN_AND_TEST.md) — Fast-track terminal commands for developers and testers.
- 💬 [**Shared Language (Ubiquitous Language)**](CONTEXT.md) — Domain glossary and terminology dictionary.

---

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are welcome!

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/amazing-idea`).
3. Ensure all tests pass: `xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnapTests test`.
4. Commit your changes with conventional commit messages.
5. Push to your branch and submit a Pull Request.

---

## 👤 Author

**Vũ Tuấn Hậu** ([@ahauy](https://github.com/ahauy))

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
