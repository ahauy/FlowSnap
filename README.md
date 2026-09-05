# FlowSnap 🪟⚡

<p align="center">
  <strong>Your Mac. Your Layout. Your Flow.</strong><br>
  <em>High-performance native macOS window manager and intent-based workspace orchestrator built with Swift 6.</em>
</p>

<p align="center">
  <a href="README.vi.md">🇻🇳 Tiếng Việt</a> •
  <a href="https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg"><strong>📥 Download (.dmg)</strong></a> •
  <a href="#-key-features">Key Features</a> •
  <a href="#-installation--getting-started">Installation</a> •
  <a href="#%EF%B8%8F-keyboard-shortcuts">Shortcuts</a> •
  <a href="#-architecture--engineering">Architecture</a> •
  <a href="#-documentation-index">Docs</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B%20(Sonoma%20%2F%20Sequoia)-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-6.0%20Strict%20Concurrency-FA7343?style=flat-square&logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Tests-470%20Passing%20(70%20Suites)-2ea44f?style=flat-square" alt="Tests 470 Passing">
  <img src="https://img.shields.io/badge/Apple%20API-100%25%20Zero%20Private%20APIs-0071e3?style=flat-square" alt="Zero Private APIs">
  <img src="https://img.shields.io/badge/Architecture-DDD%20%26%20Deep%20Modules-7928ca?style=flat-square" alt="DDD Architecture">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="MIT License">
</p>

<p align="center">
  <a href="https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg">
    <img src="https://img.shields.io/badge/Download%20for%20macOS-FlowSnap.dmg-0071e3?style=for-the-badge&logo=apple&logoColor=white" alt="Download FlowSnap for macOS">
  </a>
  <a href="https://github.com/ahauy/FlowSnap/releases/latest">
    <img src="https://img.shields.io/badge/Latest%20Release-v1.3.1-success?style=for-the-badge" alt="Latest Release v1.3.1">
  </a>
</p>

<p align="center">
  📥 <strong>Direct Download:</strong> <a href="https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg"><strong>FlowSnap.dmg (Latest v1.3.1)</strong></a> • <a href="https://github.com/ahauy/FlowSnap/releases/latest">Release Notes</a><br>
  ⚡ <strong>One-Line Terminal Install:</strong> <code>/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/scripts/install.sh)"</code><br>
  <em>~ Compatible with macOS 14.0 Sonoma and later (Apple Silicon & Intel) ~</em>
</p>

<p align="center">
  <img src="docs/user-guides/images/top-edge-layout-picker/01_layout_picker_flyout.png" width="780" alt="FlowSnap Top-Edge Layout Picker Preview">
</p>

---

## 🌟 Why FlowSnap?

The default macOS window management experience forces you into constant manual resizing, clunky full-screen Split Views, or jarring transitions that break your flow.

Even worse is **unwanted Space hopping**: opening an app suddenly pulls you across monitors or virtual desktops, destroying your mental context.

**FlowSnap** solves this with a singular principle:

> **You decide where windows belong. FlowSnap takes care of the rest.**

FlowSnap pairs an intuitive **Top-Edge Snap Layout Flyout** with an **Intent-Based Workspace Engine** engineered specifically for macOS. It delivers instant, fluid window tiling without sacrificing the flexibility of floating windows.

---

## ✨ Key Features

### 1. 🪟 Interactive Top-Edge Snap Layout Picker

Drag any window towards the top center edge of your screen to summon an instant layout picker. Hover over partition zones (50/50, 70/30, 3-column, 4-quarters) and release to snap windows into place with zero effort.

<p align="center">
  <img src="docs/user-guides/images/top-edge-layout-picker/01_layout_picker_flyout.png" width="720" alt="FlowSnap Top-Edge Layout Picker">
</p>

---

### 2. ⚡ Interactive Drag-to-Snap & Real-Time HUD Overlay

Drag windows to screen borders or display corners to trigger real-time translucent HUD snap overlays with smooth spring physics. Drop to snap; drag away to cancel.

<p align="center">
  <img src="docs/user-guides/images/drag-to-snap-preview/01_drag_to_snap_left_half.png" width="720" alt="FlowSnap Drag to Snap Preview">
</p>

---

### 3. ↔️ Adaptive Collinear Resize & Custom Window Gaps

Resizing one window shouldn't require manually readjusting its neighbor. FlowSnap automatically detects **collinear shared dividers** between tiled windows—dragging the boundary line resizes both windows simultaneously in real time locked at 60 FPS.

Configure customizable inner and outer window gaps for aesthetic, modern tiling desk setups.

<p align="center">
  <img src="docs/user-guides/images/custom-ratios-window-gaps/03_general_settings_16px_tiling.png" width="720" alt="FlowSnap Gaps and Tiling Settings">
</p>

---

### 4. 🪐 Current Space Anchoring (Zero Unwanted Space Jumping)

Never get pulled away from your active Desktop again. FlowSnap continuously observes application launches and guarantees that new windows appear **strictly within your active Space and Display**, preserving your flow state without using any private Apple APIs.

<p align="center">
  <img src="docs/user-guides/images/app-launch-current-space-policy/01_current_space_anchoring.png" width="720" alt="FlowSnap Current Space Anchoring">
</p>

---

### 5. 🗂️ Intent-Based Workspaces & Workflow Presets

Save your multi-window layout as a named **Workspace** (e.g., _Coding_, _Research_, _Writing_). Workspaces store geometric intent rather than rigid pixel values, allowing seamless restoration across different display resolutions and external monitors.

- **Curated Builtin Presets**: Instant templates for common two-window and three-window setups.
- **Linked Window Groups**: Group related windows so minimizing or repositioning one keeps the set together.

<p align="center">
  <img src="docs/user-guides/images/workspace-snapshot-restoration/01_save_workspace_sheet.png" width="720" alt="FlowSnap Save Workspace Sheet">
</p>

---

### 6. 📌 Per-App Window Policies & Smart Floating Stack

Define dedicated rules per application bundle ID:

- **Floating Utilities**: Keep lightweight tools (Calculator, Dictionary, Notes) floating above your tiled workspace.
- **Remember Position**: Automatically clamp and remember last-closed positions.
- **Smart Focus Return**: Closing a floating window immediately restores keyboard focus to the underlying tiled application.

<p align="center">
  <img src="docs/user-guides/images/settings-shortcut-customization/03_application_rules_tab.png" width="720" alt="FlowSnap Per-App Rules Settings">
</p>

---

### 7. ⌨️ Menu Bar Quick Controls & Global Hotkeys

Trigger any snap zone instantly with system-wide keyboard shortcuts powered by low-latency Carbon Event Hotkeys, or click and drag across the **Interactive Visual Snap Grid** directly from the menu bar companion.

<p align="center">
  <img src="docs/user-guides/images/settings-shortcut-customization/02_shortcuts_tab.png" width="350" alt="FlowSnap Shortcut Customization">
  <img src="docs/user-guides/images/menubar-quick-controls/01_menubar_quick_snap_menu.png" width="350" alt="FlowSnap Menu Bar Quick Snap Grid">
</p>

---

## 💻 System Requirements & Permissions

| Requirement           | Specification                                               |
| --------------------- | ----------------------------------------------------------- |
| **Operating System**  | macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)                |
| **Hardware**          | Apple Silicon (M1 / M2 / M3 / M4) or Intel (x86_64)         |
| **System Permission** | **macOS Accessibility** (`AXUIElement` window manipulation) |

> [!IMPORTANT]
> **Granting Accessibility Permission:**
> FlowSnap requires Accessibility access to position windows. On first launch, macOS will prompt you to open **System Settings → Privacy & Security → Accessibility** and toggle **FlowSnap** ON.
> FlowSnap uses **100% public Apple APIs** and runs in a hardened runtime with zero private framework calls.

---

## 🚀 Installation & Getting Started

### For Users: Download & Install

#### Option 1: One-Line Terminal Install (Recommended ⚡)

Open your Terminal and run this single command to automatically download, install to `/Applications`, remove Gatekeeper quarantine, and launch FlowSnap:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/scripts/install.sh)"
```

---

#### Option 2: Direct Download for macOS (.dmg) 📥

Click the link below to immediately trigger the native browser download dialog:

<p align="center">
  <a href="https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg">
    <strong>Download for macOS (FlowSnap.dmg)</strong>
  </a><br>
  <em>~ Compatible with macOS 14.0 Sonoma and later (Apple Silicon & Intel) ~</em>
</p>

1. Your browser will prompt to save **`FlowSnap.dmg`** (or save it directly into your `Downloads` folder).
2. Double-click the downloaded `.dmg` and drag **FlowSnap** into your **Applications** folder.
3. **First-time launch (macOS Gatekeeper)**: Because FlowSnap is an open-source project without a paid Apple Developer certificate ($99/year), macOS may show an _"Apple could not verify FlowSnap"_ warning on first launch. You can allow it via either:
   - **Terminal (Fastest)**: Run `xattr -cr /Applications/FlowSnap.app`
   - **System Settings**: Go to **System Settings → Privacy & Security**, scroll down to **Security**, and click **Open Anyway**.

---

#### Option 3: Package DMG from Source Locally

If you prefer to build the release `.dmg` yourself:

```bash
git clone https://github.com/ahauy/FlowSnap.git
cd FlowSnap
./scripts/build-dmg.sh
open build/FlowSnap-*.dmg
```

---

### For Developers: Building from Source

#### Prerequisites

- **macOS 14.0+**
- **Xcode 16.0+**
- **XcodeGen** (`brew install xcodegen`)

#### Build & Run Commands

1. **Generate the Xcode project and compile:**

   ```bash
   xcodegen generate
   xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnap -destination 'platform=macOS' build
   ```

2. **Launch the built app:**

   ```bash
   open $(find ~/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug -name "FlowSnap.app" | head -n 1)
   ```

3. **Run the automated test suite (358 Tests across 55 Suites):**

   ```bash
   xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnapTests test
   ```

4. **Run FlowSnapLab (Interactive QA Testbed):**
   ```bash
   xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnapLab -destination 'platform=macOS' build
   open $(find ~/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug -name "FlowSnapLab.app" | head -n 1)
   ```

---

## ⌨️ Keyboard Shortcuts

| Action                    | Default Shortcut | Description                             |
| :------------------------ | :--------------: | :-------------------------------------- |
| **Snap Left Half**        |     `⌥ ⌃ ←`      | Snap window to left half of screen      |
| **Snap Right Half**       |     `⌥ ⌃ →`      | Snap window to right half of screen     |
| **Snap Top Half**         |     `⌥ ⌃ ↑`      | Snap window to top half of screen       |
| **Snap Bottom Half**      |     `⌥ ⌃ ↓`      | Snap window to bottom half of screen    |
| **Maximize Window**       |     `⌥ ⌃ ↩`      | Maximize within visible screen bounds   |
| **Restore Previous Size** |     `⌥ ⌃ ⌫`      | Restore window to frame before snapping |
| **Center Window**         |     `⌥ ⌃ C`      | Center window on current display        |
| **Next Display**          |     `⌥ ⌃ ⇥`      | Move focused window to next monitor     |
| **Previous Display**      |    `⌥ ⌃ ⇧ ⇥`     | Move focused window to previous monitor |
| **Save Workspace**        |     `⌥ ⌃ S`      | Open quick save workspace dialog        |
| **Restore Workspace**     |     `⌥ ⌃ R`      | Cycle through or restore last workspace |

> [!NOTE]
> All hotkeys can be fully customized or disabled in **FlowSnap Preferences → Shortcuts**.

---

## 🏗️ Architecture & Engineering

FlowSnap is built on **Domain-Driven Design (DDD)** and John Ousterhout’s **Deep Modules** philosophy, isolating pure geometric business logic from macOS system adapters:

```
FlowSnap/
├── Domain/           # Pure business rules, math, coordinate transforms & interfaces (Zero OS deps)
│   ├── Model/        # ManagedWindow, LayoutZone, Workspace, AppPolicyRule
│   ├── Services/     # SnapEngine, LayoutEngine, CollinearEdgeDetector
│   └── Ports/        # AccessibilityServing, DisplayManaging, GlobalHotkeyManaging
├── Core/             # High-leverage coordination services
│   ├── Workspace/    # WorkspaceManager, PresetResolver, WindowGroupManager
│   ├── Policy/       # WindowPolicyManager, SmartFocusStack, FrameClampingHelper
│   └── Dispatcher/   # CommandDispatcher, LiveResizeThrottler
├── Infrastructure/   # macOS System Adapters (Ports implementation)
│   ├── Accessibility/# AXUIElement adapter, AXObserver lifecycle
│   ├── Hotkey/       # Carbon RegisterEventHotKey daemon
│   ├── Display/      # AppKit NSScreen observer & monitor topology
│   └── Persistence/  # Atomic JSON storage & UserDefaults PreferencesStore
└── UI/               # Declarative SwiftUI & non-activating NSPanels
    ├── SnapPreview/  # Translucent ghost overlay panel
    ├── LayoutPicker/ # Interactive top-edge visual flyout
    ├── MenuBar/      # NSStatusItem & popover visual snap grid
    └── Settings/     # Full-featured tabbed settings & shortcut recorder
```

### Engineering Guarantees

- **100% Swift 6.0 Concurrency**: Full actor isolation, `@MainActor` UI dispatch, and thread-safe domain entities. Zero data races.
- **100% Zero Private APIs**: Audited via `scripts/audit-no-private-apis.sh`. No undocumented `CGS*` or `SLS*` calls. Notarization and App Store ready.
- **Sub-Millisecond Execution**: Snap calculations compute in `< 1ms`. Boundary resizing maintains continuous **60 FPS**. Idle CPU consumption is **~0.0%**.
- **Rigorous Verification**: Backed by **358 automated tests** across 55 test suites with mock doubles.

---

## 🔧 Troubleshooting & Gotchas

<details>
<summary><strong>macOS keeps asking for Accessibility permission after re-compiling</strong></summary>

During local development, rebuilding the binary changes its code signature. macOS TCC may invalidate permissions for that debug path. Reset the permission cache using:

```bash
tccutil reset Accessibility com.flowsnap.app
```

Then relaunch the app and re-enable it in **System Settings → Privacy & Security → Accessibility**.
</details>

<details>
<summary><strong>"FlowSnap can't be opened because Apple cannot check it for malicious software" (Gatekeeper)</strong></summary>

If running an unsigned local build on a new machine, remove the quarantine attribute:

```bash
xattr -cr /Applications/FlowSnap.app
```

</details>

---

## 📚 Documentation Index

- 📖 [**Product Backlog & Roadmap**](docs/PRODUCT_BACKLOG_ROADMAP.md) — 12-Epic functional specifications and architecture roadmap.
- 🧩 [**Feature Documentation Index**](docs/features/README.md) — Architectural design and specs for each implemented feature.
- 🖼️ [**User Guides with Screenshots**](docs/user-guides/README.md) — Step-by-step visual guides for all user-facing features.
- 📐 [**Architecture Decision Records (ADR)**](adr/) — Immutable architectural decisions (ADR-0001 through ADR-0010).
- 🧪 [**Run & Test Guide**](docs/RUN_AND_TEST.md) — Terminal commands for testing, packaging, and QA.
- 💬 [**Ubiquitous Language (Context)**](CONTEXT.md) — Canonical project terminology and domain glossary.

---

## 🤝 Contributing

Contributions are welcome! Please check [CONTRIBUTING.md](CONTRIBUTING.md) before submitting pull requests.

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/amazing-feature`.
3. Verify test suites pass: `xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnapTests test`.
4. Submit a Pull Request.

---

## 🛡️ Security

If you discover a security vulnerability, please do **not** open a public issue. Report it confidentially via GitHub Security Advisories or contact the maintainer directly.

---

## 📄 License

FlowSnap is released under the **[MIT License](LICENSE)**.

Copyright © 2026 **Vũ Tuấn Hậu** ([@ahauy](https://github.com/ahauy)).
