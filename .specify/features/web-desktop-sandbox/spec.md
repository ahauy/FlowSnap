# Functional Specification: 3D Interactive macOS Desktop Simulator (US-WEB-026)

## 1. Functional Requirements (`REQ-SANDBOX-###`)

- **`REQ-SANDBOX-001` (macOS Virtual Desktop Canvas & Responsive Frame)**:
  - The component SHALL render a simulated macOS desktop viewport with a 16:10 aspect ratio and minimum height of 480px (maximum height 640px on desktop, scaling responsively on smaller viewports).
  - The frame SHALL feature 16px border-radius, a 1px hairline border (`var(--border-color)`), and multi-layered depth box-shadows.
  - The desktop background SHALL display a sleek, dark macOS Monterey/Ventura-inspired abstract wallpaper or radial gradient matching FlowSnap's obsidian palette (`#09090b` canvas).
  - A persistent macOS Menu Bar SHALL be positioned at the top of the canvas with:
    - Apple icon (left).
    - App title ("FlowSnap") in bold.
    - Standard dummy menus ("File", "Edit", "Layout", "Window", "Help").
    - Status items (right): FlowSnap menu bar status icon, battery/Wi-Fi indicator, and simulated live clock ("HH:MM").
  - A simulated macOS Dock SHALL float at the bottom of the canvas with liquid glass blur (`backdrop-filter: blur(16px)`), containing icons for Finder, FlowSnap (active dot indicator), VS Code, and Terminal.
  - _Derived from_: `US-SANDBOX-001`, `BR-SANDBOX-001`, `ASM-WEB-004`.

- **`REQ-SANDBOX-002` (Freeform Draggable Mock Window)**:
  - The component SHALL render an interactive simulated window (Mini Code Editor) within the desktop bounds.
  - Initial position SHALL be centered or slightly offset (e.g. `X: 20%`, `Y: 20%`, `Width: 55%`, `Height: 60%`).
  - The window header SHALL feature authentic macOS traffic light buttons (Red, Yellow, Green):
    - Red button: reset window position to initial state.
    - Yellow button: simulate minimize/restore pulse.
    - Green button: toggle Maximize/Snap Fullscreen.
    - Active layout badge displaying current snap status (e.g., "Floating", "Snapped (Left 50%)").
  - The window content SHALL display an authentic Swift 6 code snippet highlighting FlowSnap's core engine (`struct SnapEngine`, `@MainActor`, `snapWindow(...)`).
  - Window dragging SHALL be bound strictly to the window title bar. Dragging inside the code editor body SHALL permit text selection without triggering window movement.
  - The drag handler SHALL use the HTML5 Pointer Events API (`pointerdown`, `pointermove`, `pointerup`, `pointercancel`) with `setPointerCapture` to eliminate mouse slip during rapid movements.
  - Window translation SHALL be constrained within the desktop boundary (Menu Bar at `Y: 28px` to Dock at `Y: DesktopHeight - 48px`).
  - _Derived from_: `US-SANDBOX-002`, `BR-SANDBOX-001`, `BR-SANDBOX-002`.

- **`REQ-SANDBOX-003` (Windows 11-Style Top-Edge Snap Picker)**:
  - When dragging the window titlebar within `Y <= 32px` of the virtual desktop top edge, the Top-Edge Snap Picker flyout SHALL slide down smoothly (`transform: translateY(0)` with 200ms ease transition).
  - When the pointer moves away (`Y > 60px` while dragging or pointer released outside picker), the picker SHALL smoothly retract.
  - The Snap Picker SHALL render exactly 4 canonical FlowSnap layout templates:
    1. **Two-Column Equal (50% / 50%)**: Left half, Right half.
    2. **Two-Column Asymmetric (70% / 30%)**: Left wide (70%), Right sidebar (30%).
    3. **Three-Column (25% / 50% / 25%)**: Left column (25%), Center stage (50%), Right column (25%).
    4. **Four Quarters (25% each)**: Top-Left, Top-Right, Bottom-Left, Bottom-Right.
  - While dragging over any zone in the picker, that zone card SHALL illuminate with primary accent highlight (`var(--accent-color)`).
  - Releasing pointer over a zone card SHALL snap the window immediately to that zone's geometry.
  - _Derived from_: `US-SANDBOX-003`, `BR-SANDBOX-002`, `BR-SANDBOX-003`, `ASM-WEB-005`.

- **`REQ-SANDBOX-004` (Liquid Glass HUD Snap Preview Overlay)**:
  - When hovering over a snap zone in the picker OR dragging near desktop edges (left, right, corners), a translucent liquid glass preview overlay (`.hud-preview`) SHALL appear over the corresponding screen area.
  - The preview SHALL feature:
    - `backdrop-filter: blur(12px)`.
    - Translucent background (`rgba(59, 130, 246, 0.15)` or `rgba(255, 255, 255, 0.08)`).
    - 1px hairline border with glow (`1px solid rgba(59, 130, 246, 0.5)`).
    - Border radius 12px conforming to target snap bounds.
    - Smooth CSS transition (150ms spring curve `cubic-bezier(0.16, 1, 0.3, 1)`).
  - Releasing pointer while preview is active SHALL animate the window to the exact preview bounds.
  - _Derived from_: `US-SANDBOX-003`, `BR-SANDBOX-003`.

- **`REQ-SANDBOX-005` (Interactive 3D Perspective Tilt & Hardware Acceleration)**:
  - The simulator desktop container SHALL be rendered within a CSS 3D perspective wrapper (`perspective: 1200px`).
  - Pointer movement over the showcase section SHALL calculate normalized X/Y coordinates (-1.0 to +1.0) from the section center.
  - The desktop card SHALL apply `transform: rotateX(...) rotateY(...)` with maximum tilt angle clamped to `±5deg` to preserve readability and usability.
  - A dynamic radial glare highlight (`background: radial-gradient(...)`) SHALL shift across the glass bezel following the pointer angle.
  - When the pointer leaves the section, the card SHALL smoothly lerp back to neutral (`rotateX: 0deg, rotateY: 0deg`) with spring ease.
  - If `window.matchMedia('(prefers-reduced-motion: reduce)').matches` is true, 3D tilt SHALL be disabled.
  - _Derived from_: `US-SANDBOX-001`, `BR-SANDBOX-004`, `ASM-WEB-004`.

- **`REQ-SANDBOX-006` (Zero-CPU Idle Suspension via IntersectionObserver)**:
  - The client controller SHALL instantiate an `IntersectionObserver` observing the `#showcase` section.
  - When the section is scrolled out of viewport (`isIntersecting === false`), all pointer tracking, 3D transform listeners, and clock intervals SHALL be suspended.
  - When scrolled back into viewport, tracking SHALL cleanly resume.
  - Guaranteed CPU usage during idle/off-screen SHALL be 0.0%.
  - _Derived from_: `BR-SANDBOX-005`, `NFR-SANDBOX-001`.

- **`REQ-SANDBOX-007` (Reset Action & Mobile Touch Fallback)**:
  - A floating "Reset Sandbox" button SHALL be positioned in the showcase toolbar/controls area to restore the window to initial floating coordinates in one click.
  - On mobile/touch devices (< 768px) where fine drag-and-drop may be constrained by small viewport dimensions:
    - The mock window remains visible and draggable.
    - An auxiliary Quick Snap Toolbar SHALL be displayed below the desktop, allowing one-tap snapping to "Left 50%", "Right 50%", "Maximize", or "Center Floating".
  - _Derived from_: `US-SANDBOX-004`, `BR-SANDBOX-006`, `BR-SANDBOX-007`.

---

## 2. Non-Functional Requirements (`NFR-SANDBOX-###`)

- **`NFR-SANDBOX-001` (Performance & Bundle Budget)**:
  - Pure CSS 3D transforms with zero external 3D libraries (Three.js avoided for this component per `ASM-WEB-004`).
  - JavaScript size budget for simulator script: < 8KB minified, zero third-party dependencies.
  - 60+ FPS on standard 60Hz displays and 120 FPS on Apple ProMotion displays.
- **`NFR-SANDBOX-002` (Accessibility & A11y)**:
  - All interactive buttons (traffic lights, reset button, snap chips) SHALL have explicit `aria-label` attributes.
  - The simulator container SHALL have `role="region"` and `aria-label="Interactive macOS Desktop Simulator"`.
  - Full keyboard accessibility: Reset button and snap chips operable via `Tab` and `Enter`/`Space`.
- **`NFR-SANDBOX-003` (Anti-AI-Slop Visual Governance)**:
  - Strict adherence to `web/DESIGN.md` and Apple HIG.
  - Hairline borders: 1px `var(--border-color)`.
  - Canvas: Obsidian `#09090b`.
  - Zero gaudy neon halos or unrequested purple gradients.
