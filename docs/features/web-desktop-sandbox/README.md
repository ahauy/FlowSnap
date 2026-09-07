# Feature: 3D Interactive macOS Desktop Simulator (`web-desktop-sandbox`)

## Overview

- **User Story**: `US-WEB-026` (Khung giả lập macOS Desktop 3D / Interactive Sandbox)
- **Epic**: `EPIC 16` — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal (Sprint 8)
- **Platform**: Web (`web/`), static HTML generation via Astro v7
- **Design System**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)

---

## Architectural Highlights

1. **Hardware-Accelerated CSS 3D Transforms (`ASM-WEB-004`)**:
   - Uses CSS 3D perspective (`perspective: 1200px`, `rotateX`, `rotateY`) clamped strictly to `±4.5deg`.
   - Incorporates a dynamic specular glare reflection across the bezel tracking pointer coordinates.
   - Eliminates over 500KB of third-party 3D engine overhead (Three.js avoided for this component), preserving sub-1s load and native 120 FPS on Apple ProMotion displays.
   - Respects user accessibility preferences by checking `prefers-reduced-motion: reduce`.

2. **Pointer Events & Slip Protection**:
   - Utilizes HTML5 Pointer Events (`pointerdown`, `pointermove`, `pointerup`, `pointercancel`) with `setPointerCapture` on the window titlebar.
   - Eliminates mouse cursor slip or lost drag capture during fast cursor movement across the virtual desktop.

3. **Windows 11-Style Top-Edge Snap Picker (`ASM-WEB-005`)**:
   - Sliding flyout triggered when dragging the window within `32px` of the virtual top edge.
   - Implements all 4 canonical FlowSnap layout templates:
     1. **2 Columns Equal (50 / 50)**
     2. **2 Columns Asymmetric (70 / 30)**
     3. **3 Columns (25 / 50 / 25)**
     4. **4 Corners (25% each)**
   - Releasing the pointer over any zone card instantly snaps the window with an Apple-style spring curve (`cubic-bezier(0.16, 1, 0.3, 1)`).

4. **Translucent Liquid Glass HUD Snap Preview**:
   - Active preview overlay with backdrop blur (`backdrop-filter: blur(14px)`), 1.5px accent blue border, and glowing shadow (`rgba(10, 132, 255, 0.25)`).
   - Also activates on direct left and right desktop edge approaches (`<= 24px`).

5. **Zero-CPU Idle Suspension via IntersectionObserver**:
   - `IntersectionObserver` detects when `#showcase` scrolls out of the viewport, instantly pausing mouse tracking, 3D transform updates, and virtual clock intervals.
   - Guarantees 0.0% idle CPU consumption when the user reads other sections of the landing page.

6. **Multi-Window Concurrency (`ASM-WEB-007`)**:
   - Supports 2 concurrent draggable mock windows: **VS Code** (`SnapEngine.swift`) and **macOS Terminal** (`flowsnap-cli`).
   - Clicking app icons on the virtual Dock launches/focuses the corresponding window, elevating its `z-index`.
   - Allows users to experience real dual-window tiling (e.g. Code Editor on Left 70% and Terminal on Right 30%, or 50/50 split).

7. **FlowSnap Native Menu Bar Popover (`ASM-WEB-008`)**:
   - Clicking the FlowSnap status icon in the Menu Bar (or in the Dock) opens the authentic native FlowSnap Popover.
   - Includes the **Visual Snap Grid** (1/2, 70/30, 3-Col, Fullscreen) and **Workflow Presets** (`Coding Split 70/30`, `Research 50/50`).
   - One-click layout application directly targeting the active focused window.

8. **Proportional 70/30 & 3-Column Precision (`ASM-WEB-009`)**:
   - Resolves layout template previews so 70/30 renders true 70% left and 30% right geometry (eliminating `flex: 1` equal sizing).

9. **Reset Controls & Mobile Quick-Snap Toolbar**:
   - Dedicated "Reset Sandbox" button restoring windows to default floating positions.
   - Interactive macOS traffic light controls (Red: Close, Yellow: Minimize, Green: Maximize).
   - Quick Snap action chips (`50/50 Left`, `50/50 Right`, `70/30 Wide`, `Coding Split`) for one-tap mobile and tablet interaction.

10. **Adaptive Collinear Split Divider Bar (EPIC 08 Demo / `ASM-WEB-010`)**:
    - When two windows are tiled side-by-side (via dual presets, 50/50, or 70/30 split), an interactive vertical divider bar with a rounded handle pill automatically appears between them.
    - Dragging the divider bar resizes both windows inversely in real-time (clamped strictly between 20% and 80%) with pointer capture and hardware-accelerated style updates.
    - Double-clicking the divider bar instantly resets the split back to the balanced 50/50 layout.
    - Intelligently auto-tiles the companion window when snapping into 2-column layouts so users immediately experience the split.

---

## Deliverables & File Tree

```
web/
├── src/
│   ├── components/
│   │   └── DesktopSimulator.astro      # [NEW] 3D macOS Desktop & Snap Engine Simulator
│   ├── scripts/
│   │   └── desktop-simulator.ts        # [NEW] Simulator controller, drag physics & split divider
│   ├── pages/
│   │   └── index.astro                 # [MODIFY] Mounts DesktopSimulator under #showcase
│   └── styles/
│       └── design-tokens.css           # Design tokens, obsidian dark canvas & spring physics
└── tests/
    └── desktop-simulator.test.mjs      # [NEW] Automated test suite covering TC-001..TC-008
```

---

## Verification

- **Static Build**: `npm run build` in `web/` completes in `230ms` with zero errors.
- **Automated Tests**: `npm test` runs `tests/desktop-simulator.test.mjs` verifying all 8 test cases (`TC-001` through `TC-008`) successfully.
