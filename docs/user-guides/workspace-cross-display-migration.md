# 📖 User Guide: Atomic Workspace Cross-Display Migration (US-DISP-017)

> **Target Audience:** FlowSnap Mac Users working across dual or multi-monitor setups (e.g. MacBook + External 4K Display, Dual Studio Displays)  
> **Applies to:** FlowSnap 1.0+ (macOS 14 Sonoma & macOS 15 Sequoia)  
> **Feature Status:** Built-in & Fully Automated

---

## 🎯 1. Overview (in Plain English)

When working across multiple monitors on macOS, power users frequently need to transfer an entire multi-window layout — such as a code editor filling 70% of the screen with a browser and terminal sharing the remaining 30% — from one screen to another.

- **The Old Way:** You had to throw windows across screens one by one (`⌃⌥⇧→`), manually re-arrange them, and resize them to fit the new display's dimensions. If you used macOS Stage Manager, throwing individual windows repeatedly fragmented your stage grouping, kicking your apps into the left thumbnail strip.
- **The FlowSnap Way:** With **Atomic Workspace Cross-Display Migration**, pressing `⌃⌥⇧⌘→` (or selecting "Move Workspace to Next Display" in the Menu Bar) relocates **all windows in the active workspace at once**.
  - Window sizes and positions scale proportionally to fit the destination screen.
  - On macOS Stage Manager, the window group stays intact without scattering.
  - Your mouse cursor automatically warps to the primary window on the target monitor, so your hands stay focused without manual pointer tracking.

```
┌──────────────────────────────────────────────────────────────────────────┐
│              FLOWSNAP ATOMIC WORKSPACE MIGRATION ARCHITECTURE            │
├─────────────────────────────────────┬────────────────────────────────────┤
│ 🖥️ Multi-Display Topology Mapping   │ 📐 Relative Proportional Scaling   │
│ • Detects source from active window │ • Scales geometry proportionally   │
│ • Cycles smoothly across monitors   │ • Respects Menu Bar & Dock margins │
├─────────────────────────────────────┼────────────────────────────────────┤
│ 🛡️ Adaptive Move Ordering           │ 🖱️ Ergonomic Cursor Warping        │
│ • Stage Manager: Staggered IPC delay│ • Warps cursor to primary center   │
│ • Standard: Shrink before Expand    │ • Reactivates adaptive divider     │
└─────────────────────────────────────┴────────────────────────────────────┘
```

---

## 🚀 2. How to Use

### Method 1: Global Keyboard Shortcuts

FlowSnap provides dedicated multi-modifier global hotkeys for instantaneous workspace migration:

| Action                                 | Shortcut    | Description                                                                                                 |
| :------------------------------------- | :---------- | :---------------------------------------------------------------------------------------------------------- |
| **Move Workspace to Next Display**     | `⌃ ⌥ ⇧ ⌘ →` | Migrates all active workspace windows to the next screen to the right (or cycles back to the first screen). |
| **Move Workspace to Previous Display** | `⌃ ⌥ ⇧ ⌘ ←` | Migrates all active workspace windows to the previous screen to the left.                                   |

> [!TIP]
> You can customize these shortcuts anytime in **FlowSnap Settings > Shortcuts > Displays & Workspaces**.

---

### Method 2: Menu Bar Quick Controls

If you prefer using the mouse:

1. Click the **FlowSnap** icon in the macOS menu bar.
2. In the **WORKSPACES** section, click **Move Workspace to Next Display**.
3. FlowSnap immediately executes the migration and closes the menu bar dropdown cleanly.

---

## ⚙️ 3. Intelligent Under-the-Hood Behaviors

### 1. Proportional Display Scaling

Displays have different resolutions and aspect ratios (e.g. 16:10 MacBook Retina vs. 16:9 4K external or 21:9 Ultrawide). FlowSnap calculates the proportional bounding box of each window on the source monitor and scales it mathematically into the target monitor's visible frame, preventing windows from spilling off-screen or hiding behind the macOS Dock.

### 2. Stage Manager Cohesion

When macOS Stage Manager is turned on:

- The anchor window moves first to establish the stage on the destination monitor.
- Companion windows move with a 40ms stagger and are raised into the stage using macOS Accessibility (`kAXRaiseAction`), without triggering disruptive stage-swapping.
- The anchor window receives final keyboard focus lock, allowing you to resume typing immediately.

### 3. Two-Phase Transit (Standard Mode)

When Stage Manager is off, FlowSnap executes a two-phase move sequence:

1. **Phase 1 (Shrink)**: Windows whose target size is smaller than their source size are moved and shrunk first.
2. **Phase 2 (Expand)**: Expanding windows are resized into the remaining space.
   This prevents transient window collisions, flickering, or desktop crowding during movement.

### 4. Adaptive Divider Seam Continuity

If you are using FlowSnap's Adaptive Divider to adjust adjacent windows, migrating the workspace automatically hides the divider overlay on the old monitor and re-anchors it onto the destination screen the moment your cursor hovers over the window seam.

---

## ❓ 4. Frequently Asked Questions (FAQ)

#### Q: What happens if I only have one monitor connected?

FlowSnap detects that only a single display is connected and silently no-ops. No windows will move, shake, or resize unnecessarily.

#### Q: What if no workspace is currently active?

FlowSnap checks whether the windows currently visible on your focused screen match any of your saved workspaces. If a matching saved workspace is found, it migrates those windows. If no workspace is recognized, FlowSnap no-ops smoothly without disturbing your layout.

#### Q: Do I need to enable any special macOS permissions?

Yes, FlowSnap requires **macOS Accessibility** permission (`System Settings > Privacy & Security > Accessibility`) to query window positions and move windows across displays. If permission is missing, FlowSnap presents an alert and safely no-ops.
