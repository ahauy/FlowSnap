# 01 — Elicitation Record (Stage 2) — cross-display-window-throw

> Interview anchored on roadmap AC for US-DISP-015. Only underspecified / high-risk branches were grilled.
> Confirmed decisions: `ASM-DISP-001`, `ASM-DISP-002`, `ASM-DISP-003`.

## Confirmed Decisions

### ASM-DISP-001 — Display Topology Ordering & Cyclic Traversal

- **Decision**: Displays are ordered spatially from left to right based on screen frame X coordinates (`screen.frame.origin.x`, tie-broken by `origin.y`).
  - **Ordering Algorithm**: `sortedDisplays = displays.sorted { ($0.frame.minX, $0.frame.minY) < ($1.frame.minX, $1.frame.minY) }`.
  - **Next Display (`⌃⌥⇧→`)**: Moves to index `(currentIndex + 1) % count`. When on the rightmost display, wraps around to the leftmost display.
  - **Previous Display (`⌃⌥⇧←`)**: Moves to index `(currentIndex - 1 + count) % count`. When on the leftmost display, wraps around to the rightmost display.
  - **Single Display Graceful Degradation**: If `displays.count <= 1`, the operation immediately no-ops without animation, audio beep, or error log.
- **Rationale**: Provides intuitive, predictable spatial navigation that matches the physical layout of monitors on the user's desk, regardless of the internal index order assigned by macOS.

### ASM-DISP-002 — Semantic Snap Preservation with Geometric Fallback

- **Decision**: Window dimensions and placement are preserved proportionally, prioritizing semantic snap alignment.
  - **Semantic Snap Check**: If the active window was snapped via FlowSnap (e.g. Left Half, Right Half, Maximize, Top-Left Quarter, etc.) or has an active snap zone:
    - FlowSnap re-calculates the snap frame directly on the target display using `SnapEngine`.
    - Automatically accounts for target display resolution, aspect ratio, safe area (Dock/Menu Bar), and configured `WindowGap`.
  - **Free-Form Floating Windows**: If the window is free-floating (not snapped):
    - `RelativeFrameScaler` computes normalized coordinates relative to `sourceDisplay.visibleFrame`:
      - `relX = (window.x - src.minX) / src.width`
      - `relY = (window.y - src.minY) / src.height`
      - `relW = window.width / src.width`
      - `relH = window.height / src.height`
    - Target frame is mapped onto `targetDisplay.visibleFrame`:
      - `targetW = min(target.width, max(minSize.width, relW * target.width))`
      - `targetH = min(target.height, max(minSize.height, relH * target.height))`
      - `targetX = target.minX + relX * target.width`
      - `targetY = target.minY + relY * target.height`
    - Target frame is clamped inside `targetDisplay.visibleFrame` via `FrameClampingHelper` so that minimum window boundaries remain 100% visible on screen.
- **Rationale**: Ensures pixel-perfect alignment for productivity workflows: half-screen code editors stay half-screen on 4K/FHD, while arbitrary floating utility windows maintain proportional desktop real estate.

### ASM-DISP-003 — Mouse Cursor Warping & Keyboard Focus Handshake

- **Decision**: The mouse cursor is immediately warped to the center of the transported window on the target display, and keyboard focus is explicitly reinforced.
  - **Cursor Warping**: Calculate the center point of the window in global display coordinates (`CGPoint(x: frame.midX, y: frame.midY)`). Call `CGWarpMouseCursorPosition(center)`.
  - **Focus Retention**: Call `AccessibilityService.setFocus` on the target window to ensure that immediate keystrokes or mouse clicks register directly to the active application without requiring an extra manual click.
- **Rationale**: Eliminates the "lost cursor" phenomenon common in multi-monitor setups when throwing windows, keeping the user's cognitive flow unbroken.

---

## Anchored (not re-asked) — settled by roadmap AC & tech context

- **Stack & Concurrency**: Swift 6 strict concurrency (`Sendable`, actor isolation, `@MainActor`).
- **Public API Policy**: 100% Public macOS APIs (`NSScreen`, `CGWarpMouseCursorPosition`, `AXUIElement`, Carbon Event Hotkeys).
- **Default Shortcuts**:
  - `Move to Next Display`: `⌃⌥⇧→` (Ctrl + Opt + Shift + Right Arrow, keyCode: 124).
  - `Move to Previous Display`: `⌃⌥⇧←` (Ctrl + Opt + Shift + Left Arrow, keyCode: 123).
  - Configurable in Settings UI under `ShortcutCategory.displays`.
- **Command Dispatcher**: `WindowCommand.moveToNextDisplay` and `WindowCommand.moveToPreviousDisplay` routed through `CommandDispatcher`.
