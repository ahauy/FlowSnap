# 📖 User Guide: Settings & Shortcut Customization (US-SNAP-010)

> **Target Audience:** FlowSnap Mac Users  
> **Applies to:** FlowSnap 1.0+ (macOS 14 Sonoma & macOS 15 Sequoia)  
> **Last Updated:** August 30, 2026

---

## 🎯 Overview

FlowSnap features a clean, macOS-native **Settings Window** designed with SwiftUI. It provides complete control over your workspace geometry, customizable global keyboard shortcuts, drag-to-snap sensitivity, and application management.

The Settings window is designed as a **Floating Utility Panel (`level = .floating`)**, ensuring it always opens directly in the foreground above other apps and never gets lost behind open windows.

---

## 🚀 Step 1: Opening the Settings Window

You can summon FlowSnap Settings at any time using either method:

1. **Menu Bar Extra**: Click the FlowSnap menu bar icon (`rectangle.split.2x1`) at the top-right of your macOS screen and click **Settings...**
2. **Keyboard Shortcut**: Press standard macOS preferences shortcut **`⌘,`** (Command + Comma) while FlowSnap is focused.

![Full Settings Window](images/settings-shortcut-customization/05_full_settings_window.png)

---

## ⚙️ Step 2: Configuring General Preferences

The **General** tab lets you customize how windows tile and partition on your desktop:

![General Settings](images/settings-shortcut-customization/01_general_settings_view.png)

### 1. Window Gap (Aesthetic Spacing)

- Choose from 5 calibrated gap presets: **`0 px`** (flush edge-to-edge), **`4 px`** (compact default), **`8 px`** (balanced modern), **`12 px`**, or **`16 px`** (spacious breathing room).
- The interactive visual preview box immediately reflects the padding and gutter margins in real time.

### 2. Default Split Ratio (Adaptive 2-Column Partitioning)

- Select your preferred split ratio: **`50/50`**, **`60/40`**, **`70/30`**, **`80/20`**, or **`25/50/25`** (3-Column).
- **Where this applies**:
  - **Quick Hotkeys**: Pressing `⌃⌥←` (Snap Left) or `⌃⌥→` (Snap Right) will snap according to this ratio (e.g. 80% left and 20% right).
  - **Edge Dragging**: Dragging a window directly into the left or right screen border will snap according to your chosen ratio.
  - **Top-Edge Layout Picker Integration**: The 2nd card in the Top-Edge Layout Picker automatically adapts to your selected ratio (e.g. displaying **`2-Column (80/20)`**)!

### 3. Drag to Snap & Sensitivity

- **Enable Drag to Snap**: Toggle edge-dragging detection on or off.
- **Preview Delay**: Adjust the dwell threshold before the translucent HUD preview appears:
  - **Instant (50 ms)**: Fastest response for power users.
  - **Normal (150 ms)**: Standard balanced dwell.
  - **Relaxed (300 ms)**: Prevents accidental triggers when moving windows near screen edges.

### 4. Launch at Login

- Check **Launch at login** to have FlowSnap start automatically in the background when your Mac boots up.

---

## ⌨️ Step 3: Customizing Keyboard Shortcuts

The **Shortcuts** tab provides complete freedom to bind window actions to your preferred key combinations:

![Shortcuts Tab](images/settings-shortcut-customization/02_shortcuts_tab.png)

### How to Record a Custom Shortcut:

1. Click on the shortcut button next to any action (e.g. **Left Half**).
2. The button highlights with an active blue indicator and displays `"Type keys..."`.
3. Press your desired key combination on your keyboard (e.g. `⌥1`, `⌃⌥←`, or `⌘⇧Left`).
4. FlowSnap records the key combination instantly and updates the system-wide Carbon Hotkey registration immediately—**no app restart required!**

### Safe Shortcut Recording Features:

- **Conflict Warning Indicator (`⚠️`)**: If you record a shortcut already assigned to another action, FlowSnap displays an orange warning badge (`⚠️`) with a tooltip explaining which action is sharing that shortcut.
- **Cancel Recording (`⎋ Escape`)**: Press the `Escape` key while recording to abort and keep your existing shortcut.
- **Clear / Unassign (`⌫ Delete` / `✕`)**: Press `Delete` or click the circular `✕` button to leave an action unassigned.
- **Restore Defaults**: Click **Restore Defaults** in the bottom-right corner to reset all shortcut keybindings back to factory defaults.

---

## 📱 Step 4: Per-Application Rules & About

### Application Rules Tab

Define custom exclusion rules or floating behaviors for specific apps (e.g. Calculator, Notes, or video conferencing tools):

![Application Rules Tab](images/settings-shortcut-customization/03_application_rules_tab.png)

### About & Permission Status Tab

View version information and verify your macOS Accessibility trust status:

![About Tab](images/settings-shortcut-customization/04_about_settings_tab.png)

- If Accessibility permission is ever disabled, a red warning badge will appear with a **Grant Access** button that opens macOS System Settings directly to Privacy & Security > Accessibility.

---

## 💡 Pro-Tips for Testing Shortcuts

> [!TIP]
> **Focusing External Windows When Testing Hotkeys**:  
> FlowSnap deliberately protects its own Settings window from being accidentally moved or snapped (`window.pid == FlowSnap.pid`).  
> When testing newly recorded hotkeys, **click on any other app window** (such as Finder, Safari, Chrome, or Notes) and press your shortcut!

---

## ❓ Frequently Asked Questions (FAQ)

### Q1: Can I use single-letter keys (like just 'A' or '1') as shortcuts?

**A:** FlowSnap requires at least one modifier key (`⌃ Control`, `⌥ Option`, `⇧ Shift`, or `⌘ Command`) to prevent hotkeys from conflicting with normal text typing in other applications.

### Q2: Why does my shortcut reset when I press Escape?

**A:** `⎋ Escape` is reserved to cancel an in-progress recording. If you want to clear a shortcut permanently, use `⌫ Delete` or the `✕` button instead.

### Q3: How do I open Settings if I hid the menu bar icon?

**A:** Press **`⌘,`** whenever FlowSnap is active, or summon FlowSnap from Spotlight / Raycast.
