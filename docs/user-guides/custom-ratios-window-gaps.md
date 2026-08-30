# 📖 User Guide: Custom Split Ratios & Window Gaps

> **Audience:** FlowSnap Users & macOS Multitaskers  
> **Feature Epic:** US-SNAP-008 (Adaptive Multi-Window Resize & Gaps)  
> **Last Updated:** August 30, 2026

---

## 🎯 Overview

Standard 50/50 splits are great for basic dual-window setups, but complex workflows—such as coding alongside a live preview, writing next to research notes, or multitasking on an ultrawide monitor—benefit greatly from asymmetric screen layouts and clean spacing between windows.

FlowSnap's **Custom Split Ratios & Window Gaps** feature gives you complete control over your window tiling geometry:

- **Asymmetric Layout Ratios**: Snap windows to **60/40 (Golden Split)**, **70/30 (Master-Detail)**, **80/20 (Focus Canvas)**, or 3-column **25/50/25 (Center Stage)** partitions.
- **Aesthetic Window Gaps**: Add elegant padding (**0 px**, **4 px**, **8 px**, **12 px**, or **16 px**) between adjacent windows and screen edges for a polished tiling desktop aesthetic.
- **Uniform Gap Geometry**: Windows are uniformly inset from screen borders and adjacent windows, ensuring balanced margins across all monitors.
- **Sub-Pixel Precision**: FlowSnap's layout engine automatically handles odd-pixel screen resolutions (e.g. 1441px) without single-pixel gaps or window overlaps.
- **Instant One-Step Restore**: FlowSnap remembers your window's exact floating position before snapping so you can return to freeform mode anytime.

---

## 📐 Layout Ratio Catalog

FlowSnap provides 5 primary ratio configurations designed for modern desktop workflows:

| Ratio            | Split Name        | Zones                           |    Proportions    | Ideal Workflow                                                                                  |
| :--------------- | :---------------- | :------------------------------ | :---------------: | :---------------------------------------------------------------------------------------------- |
| **50 / 50**      | **Equal Split**   | Left Half, Right Half           |    `50% : 50%`    | Balanced side-by-side reading, comparing documents, or dual browsing.                           |
| **60 / 40**      | **Golden Split**  | Left 60%, Right 40%             |    `60% : 40%`    | Primary code editor or writing canvas on left, live preview/terminal on right.                  |
| **70 / 30**      | **Master-Detail** | Left 70%, Right 30%             |    `70% : 30%`    | Deep-work workspace on left with a narrow companion palette, chat, or notes on right.           |
| **80 / 20**      | **Focus Canvas**  | Left 80%, Right 20%             |    `80% : 20%`    | Maximized main work area with a compact inspector, tool shelf, or music player.                 |
| **25 / 50 / 25** | **Center Stage**  | Left 25%, Center 50%, Right 25% | `25% : 50% : 25%` | Ultrawide displays: Sidebar/Slack on left + Main Editor in center + Terminal/Debugger on right. |

---

## 🖼️ Visual Layout Diagrams

### 1. 50 / 50 Equal Split (Uniform Gap = 8px)

```text
+-------------------------------------------------------------+
|                     macOS Menu Bar                          |
+-------------------------------------------------------------+
|  gap=8px                                                    |
|  +---------------------------+ gap +---------------------+  |
|  |                           | =8  |                     |  |
|  |                           | px  |                     |  |
|  |        Left Half          |     |     Right Half      |  |
|  |          (50%)            |     |        (50%)        |  |
|  |                           |     |                     |  |
|  +---------------------------+     +---------------------+  |
|                                                     gap=8px |
+-------------------------------------------------------------+
|                     macOS Dock (Bottom)                     |
+-------------------------------------------------------------+
```

### 2. 70 / 30 Master-Detail Split (IDE + Companion Tool)

```text
+-------------------------------------------------------------+
|  gap=8px                                                    |
|  +--------------------------------------+ gap +----------+  |
|  |                                      | =8  |          |  |
|  |                                      | px  |  Right   |  |
|  |             Left (70%)               |     |  (30%)   |  |
|  |          Full-Featured IDE           |     | Terminal |  |
|  |          or Design Canvas            |     | or Notes |  |
|  |                                      |     |          |  |
|  +--------------------------------------+     +----------+  |
|                                                     gap=8px |
+-------------------------------------------------------------+
```

### 3. 25 / 50 / 25 3-Column Center Stage (Ultrawide Layout)

```text
+---------------------------------------------------------------------------------+
|  gap=8px                                                                        |
|  +---------------+ gap +---------------------------------+ gap +---------------+|
|  |               | =8  |                                 | =8  |               ||
|  |  Left (25%)   | px  |          Center (50%)           | px  |  Right (25%)  ||
|  |  Project Tree |     |         Main Code Editor        |     |  Debug Output ||
|  |  or Slack     |     |          or Active Task         |     |  or Terminal  ||
|  +---------------+     +---------------------------------+     +---------------+|
|                                                                         gap=8px |
+---------------------------------------------------------------------------------+
```

---

## 🚀 Step-by-Step Instructions & Workflows

### Step 1: Open FlowSnap Settings

1. Open FlowSnap Settings by pressing **`⌘,`** (Command + Comma) or clicking the FlowSnap menu bar icon → **Settings...**.
2. The **Settings** window will appear displaying the **General** tab:

![FlowSnap Settings Window](images/custom-ratios-window-gaps/02_settings_window_tabs.png)

- **① Settings Window**: Native macOS Preferences panel with intuitive controls.
- **② Window Gap Selector**: Segmented control showing available gap options (`0 px`, `4 px`, `8 px`, `12 px`, `16 px`).
- **③ Live Gap Preview**: Interactive visualizer showing real-time window spacing.
- **④ Default Ratio Picker**: Dropdown menu to pick your primary split proportion.
- **⑤ Launch at Login**: Toggle to start FlowSnap automatically on system startup.

---

### Step 2: Customize Window Gaps & Preview Spacing

1. In the **Window Gap** section, click your desired gap size:
   - **`0 px` (Flush)**: Windows touch screen borders and each other edge-to-edge for maximum screen real estate.
   - **`4 px` (Subtle — Default)**: Clean, minimal separation between windows without losing usable space.
   - **`8 px` (Modern Clean)**: Balanced spacing providing clear separation between multitasking windows.
   - **`12 px` (Airy & Spacious)**: Generous desktop breathing room, ideal for 4K and 5K high-density displays.
   - **`16 px` (Tiling WM Aesthetic)**: Distinctive wide gaps popular in Unix tiling window manager configurations.
2. Watch the **Live Gap Preview** box immediately update to display the chosen spacing:

![General Settings 8px Gap Preview](images/custom-ratios-window-gaps/01_general_settings_view.png)

- **① Gap Selection (`8 px`)**: Highlights the active gap preset in vibrant macOS accent color.
- **② Live Gap Preview Card**: Renders scaled window representations showing the exact inset margins.
- **③ Default Ratio (`70/30`)**: Sets the standard asymmetric ratio for keyboard snaps.

3. If you select **`16 px`**, the preview box expands spacing to show the prominent tiling window manager style:

![General Settings 16px Tiling Gap Preview](images/custom-ratios-window-gaps/03_general_settings_16px_tiling.png)

- **① Tiling Gap (`16 px`)**: Selected preset for wide visual separation.
- **② Expanded Preview Gutter**: Shows prominent spacing between blue (active) and grey (companion) window slots.
- **③ Center Stage Ratio (`25/50/25`)**: Default ratio configured for 3-column layouts.

---

### Step 3: Snapping with Custom Ratios via Top-Edge Picker

You can trigger custom asymmetric splits visually using the mouse:

1. Click and hold the title bar of any open application window.
2. Drag your cursor towards the top-center edge of your screen.
3. The **Top-Edge Snap Layout Picker** flyout will smoothly slide down.
4. Hover over the **70/30** or **3-Column (25/50/25)** card:
   - Hover over the larger left slot to snap to **70% width on the left**.
   - Hover over the smaller right slot to snap to **30% width on the right**.
   - Hover over the center slot in the 3-column card to snap to **50% center stage**.
5. Release your mouse button (`leftMouseUp`). The window snaps into the chosen partition with your configured window gap applied automatically!

---

### Step 4: Snapping with Global Keyboard Shortcuts

For high-speed keyboard-driven multitasking:

1. Bring the application window you want to arrange to the front.
2. Press the shortcut corresponding to your desired ratio and placement (e.g., `⌃⌥←` for left partition, `⌃⌥→` for right partition).
3. The window instantly snaps to the calculated partition, automatically insetting by your active window gap.
4. Focus another window and snap it to the opposing side. Both windows will tile cleanly with uniform gap spacing.

---

### Step 5: Restoring Original Floating Window Position

1. To revert a snapped window back to its previous floating state, bring it to the foreground.
2. Trigger the **Restore** command (`⌃⌥↓` or click **Restore** in the Menu Bar quick menu).
3. FlowSnap instantly restores the window to its exact dimensions and desktop coordinates before any snap occurred.

---

## ⌨️ Keyboard Shortcuts & Zone Reference

| Action / Layout Zone   |  Split Ratio   | Default Shortcut | Description                                               |
| :--------------------- | :------------: | :--------------: | :-------------------------------------------------------- |
| **Left Half (50%)**    |   `50 / 50`    |      `⌃⌥←`       | Snaps window to the left 50% half of active screen.       |
| **Right Half (50%)**   |   `50 / 50`    |      `⌃⌥→`       | Snaps window to the right 50% half of active screen.      |
| **Left 60%**           |   `60 / 40`    |  Custom / Menu   | Snaps window to left 60% width partition.                 |
| **Right 40%**          |   `60 / 40`    |  Custom / Menu   | Snaps window to right 40% width partition.                |
| **Left 70%**           |   `70 / 30`    |  Custom / Menu   | Snaps window to left 70% master partition.                |
| **Right 30%**          |   `70 / 30`    |  Custom / Menu   | Snaps window to right 30% companion partition.            |
| **Left 80%**           |   `80 / 20`    |  Custom / Menu   | Snaps window to left 80% canvas partition.                |
| **Right 20%**          |   `80 / 20`    |  Custom / Menu   | Snaps window to right 20% tool inspector partition.       |
| **Left 25% (3-Col)**   | `25 / 50 / 25` |  Custom / Menu   | Snaps window to left 25% sidebar column.                  |
| **Center 50% (3-Col)** | `25 / 50 / 25` |  Custom / Menu   | Snaps window to central 50% main work column.             |
| **Right 25% (3-Col)**  | `25 / 50 / 25` |  Custom / Menu   | Snaps window to right 25% utility column.                 |
| **Maximize**           |     `100%`     |      `⌃⌥↑`       | Fills 100% of visible desktop (respects Dock & Menu Bar). |
| **Restore**            |    Original    |      `⌃⌥↓`       | Restores window to exact pre-snap position and size.      |

---

## 💡 Pro Tips & Best Practices

- **Tip 1: Ultrawide Super-Productivity**: On 34-inch and 49-inch ultrawide monitors, set your default ratio to **25/50/25** or **70/30** with an **8px** or **12px** gap for a distraction-free panoramic workstation.
- **Tip 2: Instant Reset**: You can test different gap sizes at any time in Settings. Once changed, newly snapped windows will adopt the new gap immediately.
- **Tip 3: Dual-Screen Uniformity**: FlowSnap calculates gaps relative to the specific screen a window is snapped to, ensuring that multi-monitor setups with different resolutions keep identical padding proportions.
- **Tip 4: Zero Peek-Through**: Selecting `0 px` creates a completely seamless edge-to-edge layout where adjacent window frames share exact borders without any desktop wallpaper peeking through.

---

## ❓ Frequently Asked Questions (FAQ)

#### Q: Why doesn't a certain app shrink down to a 20% or 25% column?

**A:** macOS applications (such as Xcode, Final Cut, or certain web browsers) can specify a minimum window size. When snapping to narrow columns (e.g. 20% or 25%), FlowSnap anchors the window securely to your chosen screen edge and expands inward toward the center, ensuring the app is never clipped or pushed off-screen.

#### Q: Why is there a 1-pixel difference on some monitors?

**A:** On displays with odd pixel dimensions (e.g. 1441px wide), integer division produces a fractional pixel. FlowSnap automatically allocates the single remainder pixel to the rightmost column, guaranteeing 100% seamless desktop coverage with zero overlap.

#### Q: Do window gaps leave space around the macOS Dock and Menu Bar?

**A:** Yes. FlowSnap calculates usable screen space strictly inside the desktop area bounded by the macOS Menu Bar and Dock. Window gaps are applied inward from those system boundaries, preventing any window overlap with system bars.

#### Q: How do I disable window gaps completely?

**A:** Open **FlowSnap Settings (`⌘,`) → General** and click **`0 px`**. All subsequent window snap actions will be completely flush.

---

## ✅ Summary Checklist

- [x] Select custom window gap presets (`0 px`, `4 px`, `8 px`, `12 px`, `16 px`) in Settings.
- [x] Inspect real-time padding in the live interactive Gap Preview card.
- [x] Configure your preferred default layout ratio (50/50, 60/40, 70/30, 80/20, 25/50/25).
- [x] Snap windows smoothly using Top-Edge Layout Picker or Global Hotkeys.
- [x] Restore windows back to their original floating frames anytime with a single keystroke.
