# 📖 User Guide: Adaptive Multi-Window Divider Resize (US-SNAP-009)

> **Target Audience:** FlowSnap Mac Users  
> **Applies to:** FlowSnap 1.0+ (macOS 14 Sonoma & macOS 15 Sequoia)  
> **Last Updated:** August 30, 2026

---

## 🎯 Overview

The **Adaptive Multi-Window Divider Resize** feature brings iPadOS Split View and modern tiling window manager ergonomics to macOS. Whenever two or more snapped windows share a border, you can simply hover your cursor over the seam between them and drag to resize both windows in perfect synchronization.

No more tedious manual resizing of window A and then adjusting window B to match—FlowSnap keeps your workspace beautifully aligned in real time.

```
┌───────────────────────────┬───────────────────────────┐
│                           │                           │
│     Window A (Left)       │     Window B (Right)      │
│                           │                           │
│                      ◄─── ║ ───►                      │
│                      (Drag Divider)                   │
│                           │                           │
└───────────────────────────┴───────────────────────────┘
```

---

## 🚀 Step-by-Step Instructions

### Step 1: Snap Two or More Windows

First, tile two or more windows on your screen using any of FlowSnap's snapping methods:

- **Keyboard Shortcuts**: Press `⌃⌥←` on Window A (Left) and `⌃⌥→` on Window B (Right).
- **Drag-to-Snap**: Drag Window A to the left screen edge, and drag Window B to the right screen edge.
- **Top-Edge Layout Picker**: Drag windows to the top edge and drop into the 2-Column, 3-Column, or 4-Quarters slots.

---

### Step 2: Hover Over the Shared Divider Seam

Move your mouse cursor to the boundary line between the adjacent windows:

- **Vertical Boundary (Left / Right split)**: The cursor instantly transforms into a horizontal resize indicator (`⬌`).
- **Horizontal Boundary (Top / Bottom split)**: The cursor transforms into a vertical resize indicator (`⬍`).
- **Window Gap Friendly**: If you configured an aesthetic Window Gap in Settings (e.g. `8 px` or `16 px`), you can click and drag anywhere inside the comfortable gap zone.

---

### Step 3: Click and Drag to Adjust the Split

1. **Click and hold** the primary mouse button on the active divider seam.
2. **Drag left or right** (or up and down) to adjust the partition ratio smoothly.
3. Both adjacent windows resize **simultaneously in real time at 60 frames per second** with zero tearing or stutter.
4. **Release the mouse button** to lock in your custom partition layout.

---

## 🌟 Advanced Capability: Multi-Window T-Junction Resizing

FlowSnap features a **Collinear Edge Detection Engine** that handles complex layouts effortlessly.

### Example: The 3-Window Developer Layout (1 Left, 2 Stacked Right)

Suppose you have:

- **Window A (Left)**: Xcode or VS Code code editor.
- **Window B (Top-Right)**: Web Browser / Documentation.
- **Window C (Bottom-Right)**: Terminal / Debugger.

```
┌─────────────────────┬─────────────────────┐
│                     │  Window B (Browser) │
│                     ├─────────────────────┤ ◄─── Dragging here resizes
│  Window A (Editor)  │                     │      Browser & Terminal heights
│                     │  Window C (Terminal)│      without affecting Editor
│                ◄─── ║ ───►                │
│             (Dragging here resizes        │
│          Editor vs BOTH B & C together!)  │
└─────────────────────┴─────────────────────┘
```

- **Dragging the Main Vertical Divider**: Resizes Window A on the left while **simultaneously adjusting both Window B and Window C** on the right in perfect lockstep!
- **Dragging the Horizontal Divider**: Adjusts the relative heights between Window B and Window C without disturbing Window A.

---

## 🛡️ Built-in Safeguards & Ergonomics

1. **Window Minimum Size Protection (No Collapsing)**:
   - FlowSnap guarantees that dragging a divider will never accidentally crush or hide a window.
   - Every window is safeguarded with minimum usable bounds (minimum 200px width, 150px height) or the application's own native minimum dimensions.
2. **ProMotion 120Hz Smooth Throttling**:
   - System Accessibility calls are intelligently batched to match 60fps display refresh cycles, ensuring zero UI freeze or high CPU usage.
3. **Clean Drag Cancellation**:
   - If you press `⎋` (Escape) during an active resize drag, FlowSnap cleanly ends the interaction without disturbing window positions.

---

## 💡 Tips & Best Practices

- **Combine with Custom Ratios**: Start with a `70/30` or `80/20` split from the Top-Edge Layout Picker, then fine-tune the exact ratio pixel-by-pixel using the adaptive divider.
- **Works Across Multiple Monitors**: Divider detection works independently on each of your connected external displays.
- **Zero Configuration Required**: Adaptive divider resize is active out-of-the-box as long as FlowSnap has Accessibility permission.

---

## ❓ Frequently Asked Questions (FAQ)

### Q1: Why doesn't the cursor change when I hover between two windows?

**A:** Ensure that:

1. FlowSnap is running and has **Accessibility Permission** enabled in macOS System Settings.
2. Both windows were snapped to adjacent zones (windows must share a common edge within 16px).

### Q2: Can I resize 3 vertical columns at once?

**A:** Yes! When 3 windows are placed side-by-side (Left, Center, Right), hovering over the divider between Left and Center resizes the Left and Center windows. Hovering over the divider between Center and Right resizes the Center and Right windows.

### Q3: Does divider resizing work with floating or freeform windows?

**A:** Adaptive divider resizing specifically detects snapped, tiled windows sharing a collinear boundary. Freeform floating windows can be snapped at any time using `⌃⌥←` or Drag-to-Snap.
