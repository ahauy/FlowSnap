# Architecture & Implementation Plan: 3D Interactive macOS Desktop Simulator (US-WEB-026)

## 1. Architectural Strategy

- **Deep Module Encapsulation (`codebase-design`)**:
  - Encapsulate the entire 3D desktop simulation inside `web/src/components/DesktopSimulator.astro`.
  - The component exposes a zero-prop public contract to `index.astro`, handling its own DOM structure, scoped styling, and client-side physics loop internally.
- **Hardware-Accelerated CSS 3D Transforms (`ASM-WEB-004`)**:
  - Use `perspective: 1200px`, `rotateX`, and `rotateY` via CSS 3D transforms on the container rather than a 500KB Three.js WebGL canvas.
  - Keeps bundle weight < 8KB, ensures instant 0ms FCP, native 120 FPS on ProMotion, and perfect text rendering of code syntax.
- **Pointer Events & Pointer Capture Engine**:
  - Use `pointerdown`, `pointermove`, `pointerup`, and `pointercancel` on the window titlebar with `setPointerCapture(pointerId)`.
  - Guarantees zero drag loss/slip even during rapid multi-directional cursor movements.
- **Dual Snap Trigger Channels**:
  - **Channel A (Top-Edge Picker)**: Dragging near the top menu bar (`Y <= 32px`) slides down the 4-template picker. Hovering over any zone highlights the zone and project a liquid glass HUD preview over the target desktop quadrant.
  - **Channel B (Direct Edge Snapping)**: Dragging within `24px` of the left or right desktop boundary automatically illuminates a 50% split preview.
- **Zero-CPU Idle Suspension**:
  - Use `IntersectionObserver` to completely disconnect mousemove listeners and freeze any animation/clock loops when `#showcase` is scrolled out of view.
- **Accessible & Touch-Friendly Fallback**:
  - Respect `prefers-reduced-motion: reduce` by disabling 3D perspective tilt.
  - Provide a Quick Snap toolbar with one-tap action chips ("Left 50%", "Right 50%", "Maximize", "Center Floating") and a prominent "Reset" button for mobile/touch screens.

---

## 2. File Modification & Creation Manifest

```
web/
├── src/
│   ├── components/
│   │   └── DesktopSimulator.astro      # [NEW] Deep module for 3D macOS Desktop & Snap Simulator
│   ├── pages/
│   │   └── index.astro                 # [MODIFY] Replace placeholder #showcase with DesktopSimulator
│   └── styles/
│       └── design-tokens.css           # [MODIFY] Add any necessary simulator utility tokens if needed
```

---

## 3. Implementation Phasing

1. **Phase 1: Component Structure & Visual Styling (`DesktopSimulator.astro`)**:
   - Construct macOS desktop frame (16:10 aspect ratio, rounded bezel, 1px hairline border, dark wallpaper).
   - Construct virtual Menu Bar (Apple icon, FlowSnap title, status clock).
   - Construct virtual Dock (Finder, FlowSnap, VS Code, Terminal icons with liquid glass backdrop).
   - Construct Top-Edge Snap Picker (4 templates: 50/50, 70/30, 25/50/25, 4 Quarters).
   - Construct Liquid Glass HUD Snap Preview overlay.
   - Construct Draggable Mock Window with macOS traffic lights, snap status pill, and Swift 6 code editor.
   - Construct Toolbar with Reset button and mobile Quick Snap chips.
2. **Phase 2: Client Simulation Controller (`DesktopSimulatorController`)**:
   - Implement window drag physics with `PointerEvents` and `setPointerCapture`.
   - Implement top-edge detection (`Y <= 32px`) and picker reveal/hide state machine.
   - Implement picker zone hover detection and HUD preview geometry updates.
   - Implement direct edge snap detection.
   - Implement release-to-snap physics with spring cubic-bezier easing.
   - Implement traffic light actions (Red: reset, Green: toggle maximize).
   - Implement Quick Action chips and Reset button handlers.
3. **Phase 3: 3D Perspective Tilt & IntersectionObserver**:
   - Implement mousemove tracking across the showcase section to tilt the desktop frame (max ±5deg).
   - Implement specular glare reflection tracking.
   - Wire `IntersectionObserver` to pause 3D calculations when off-screen.
   - Wire `prefers-reduced-motion` check.
4. **Phase 4: Page Integration & Verification (`index.astro`)**:
   - Import and render `<DesktopSimulator />` inside `#showcase` in `web/src/pages/index.astro`.
   - Run `npm run build` in `web/` to verify zero TypeScript/Astro compilation errors.
   - Verify responsive layout across desktop, tablet, and mobile viewport widths.
