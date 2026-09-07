# Changelog: `web-desktop-sandbox`

All notable changes to the `web-desktop-sandbox` feature will be documented in this file.

## [1.0.0] - 2026-09-07

### Added

- **macOS Desktop Frame**: Simulated 16:10 Apple desktop viewport with authentic Menu Bar (Apple logo, dummy menus, status clock, FlowSnap menu bar item with live indicator) and Dock with liquid glass backdrop blur (`backdrop-filter: blur(20px)`).
- **Interactive Mock Window**: Mini Code Editor with Swift 6 syntax highlighting (`struct SnapEngine`, `@MainActor`, `snapWindow`), macOS traffic lights (Red: Reset, Green: Toggle Maximize), and live layout status badge (`Zone: Free Float`).
- **HTML5 Pointer Dragging**: Seamless window dragging via `PointerEvents` with `setPointerCapture` to eliminate cursor slip.
- **Windows 11-Style Top-Edge Snap Picker**: Smooth slide-down tray revealing 4 canonical FlowSnap layout templates (50/50, 70/30, 25/50/25, 4 Quarters) with hover detection and release-to-snap physics.
- **Liquid Glass HUD Snap Preview**: Translucent blue overlay reflecting target zone bounds upon hovering picker cards or dragging near virtual desktop edges.
- **Hardware-Accelerated CSS 3D Perspective Tilt**: Dynamic `rotateX` and `rotateY` tilt (clamped to `±4.5deg`) with interactive specular glare reflection and `prefers-reduced-motion` safety.
- **Zero-CPU Idle Suspension**: `IntersectionObserver` pause on scroll out guaranteeing 0.0% CPU during idle.
- **Multi-Window Concurrency (`ASM-WEB-007`)**: Added simultaneous draggable mock windows (VS Code `SnapEngine.swift` and macOS Terminal `flowsnap-cli`), supporting authentic dual-window tiling and Z-index focus layering.
- **Dock App Launching**: Clicking Dock icons launches, focuses, or unminimizes windows with running dot indicators.
- **FlowSnap Native Menu Bar Popover (`ASM-WEB-008`)**: Implemented authentic macOS Menu Bar dropdown with Visual Snap Grid (1/2, 70/30, 3-Col, Fullscreen) and 1-click Workflow Presets (`Coding Split 70/30`, `Research 50/50`).
- **70/30 Layout Ratio Precision Bug Fix (`ASM-WEB-009`)**: Fixed CSS `.template-preview` so the 70/30 template renders true proportional 70% left and 30% right widths instead of being forced into equal 50/50 by `flex: 1`. Also balanced 3-column template (25/50/25).
- **Buttery 120 FPS Drag Physics Engine**: Added `requestAnimationFrame` movement throttling, dynamic Z-index elevation, and complete text-selection isolation during window drag.
