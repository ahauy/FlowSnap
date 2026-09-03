# 📖 User Guide: Cross-Display Window Throw (US-DISP-015)

> **Target Audience:** Every FlowSnap Mac User working with Multiple Monitors  
> **Applies to:** FlowSnap 1.0+ (macOS 14 Sonoma & macOS 15 Sequoia)  
> **Last Updated:** September 3, 2026

---

## 🎯 1. What This Feature Does (in Plain English)

When working across multiple displays (such as a MacBook connected to an external 4K monitor or an ultra-wide screen), moving windows between displays by dragging them across screen borders is cumbersome and disruptive:

- You have to click, hold, and drag a large window across the boundary.
- The window often ends up misaligned, oversized, or awkwardly cut off if the two monitors have different resolutions (e.g. 4K vs 1080p).
- You lose your mouse cursor on the other monitor and spend valuable seconds searching for it.

**FlowSnap's Cross-Display Window Throw** makes this instantaneous and effortless:

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     FLOWSNAP CROSS-DISPLAY THROW                         │
├─────────────────────────────────────┬────────────────────────────────────┤
│ ⚡ Instant Global Shortcuts         │ 📐 Proportional Scaling & Snapping │
│ • ⌃⌥⇧→ : Throw to Next Display      │ • Snapped windows stay snapped     │
│ • ⌃⌥⇧← : Throw to Previous Display  │ • Floating windows scale cleanly   │
├─────────────────────────────────────┼────────────────────────────────────┤
│ 🎯 Auto Cursor Warping              │ 🔄 Cyclic Modulo Navigation        │
│ • Mouse cursor instantly jumps to   │ • Moving past the last monitor     │
│   the center of the thrown window   │   wraps around to the first one    │
└─────────────────────────────────────┴────────────────────────────────────┘
```

---

## ⌨️ 2. Default Shortcuts & How to Use

| Action                       | Default Shortcut                               | Behavior                                                               |
| :--------------------------- | :--------------------------------------------- | :--------------------------------------------------------------------- |
| **Move to Next Display**     | `⌃⌥⇧→` (`Ctrl + Option + Shift + Right Arrow`) | Moves the focused window to the next monitor to the right (cyclic).    |
| **Move to Previous Display** | `⌃⌥⇧←` (`Ctrl + Option + Shift + Left Arrow`)  | Moves the focused window to the previous monitor to the left (cyclic). |

### How It Works:

1. Focus the window you want to move (e.g. your code editor, browser, or terminal).
2. Press `⌃⌥⇧→`.
3. The window instantly teleports to the next monitor.
4. **Your mouse cursor automatically jumps to the center of the window on the new monitor**, ready for immediate scrolling or clicking!

---

## 📐 3. Smart Layout Adaptation

FlowSnap is target-aware when throwing windows:

- **If the window was Snapped (e.g. Left Half, Right Half, Maximize)**:
  - FlowSnap recalculates the snap frame for the target display, honoring that display's resolution, safe area (Menu Bar, Dock), and your configured **Window Gap**.
- **If the window was Free-Floating**:
  - FlowSnap maintains its exact proportional size and position relative to the destination screen. A window occupying 40% width on your laptop will occupy 40% width on your 4K display.
  - Built-in `FrameClampingHelper` guarantees the window never opens off-screen or trapped under the dock.

---

## ⚙️ 4. Customizing Shortcuts in Settings

1. Click the **FlowSnap icon** in the macOS menu bar and select **Preferences...** (or press `⌘,`).
2. Open the **Shortcuts** tab.
3. Scroll down to the **Display Navigation** section:
   - **Move to Next Display** (default: `⌃⌥⇧→`)
   - **Move to Previous Display** (default: `⌃⌥⇧←`)
4. Click on any shortcut recorder field to record your preferred custom key combination.

---

## 💡 5. Frequently Asked Questions (FAQ)

### Q: What happens if I only have one display connected?

**A:** FlowSnap detects that only 1 display is active and safely ignores the shortcut (`no-op`). There is zero screen flicker, zero audio error beep, and no delay.

### Q: Does this move windows across displays if they are arranged vertically in macOS Settings?

**A:** Yes! FlowSnap automatically sorts displays primarily from left to right (`minX`), and secondarily from top to bottom (`minY`), providing a deterministic cyclic order across any multi-monitor topology.

### Q: Does this feature use private macOS APIs?

**A:** No. FlowSnap uses 100% public Apple APIs (`NSScreen`, `CGWarpMouseCursorPosition`, and `AXUIElement`), ensuring complete safety and future macOS compatibility.
