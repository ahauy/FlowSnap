# Tech Context: FlowSnap 3D Interactive macOS Desktop Simulator (US-WEB-026)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1) and `web/DESIGN.md`.
> This file is the single source of truth for tech-stack facts of the web sandbox feature.
> Subagents and execution phases read this file first.

## Stack

- **framework**: Astro (v7.x, static output mode)
- **language**: TypeScript / JavaScript (ESM)
- **3D / Canvas**: Three.js (`three` ^0.185.1 already installed in `web/package.json`) + CSS 3D Transforms / Perspective
- **pointer events**: Modern Pointer Events API (`pointerdown`, `pointermove`, `pointerup`, `pointercancel`, `setPointerCapture`) for unified mouse and multi-touch support
- **styling**: Vanilla CSS + Semantic CSS Variables (`web/src/styles/design-tokens.css`)
- **design system**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)
- **typography**: System font stack (`-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif`, `"SF Mono", Menlo, monospace`)
- **package manager**: npm / node (`>= 22.12.0`)
- **rendering**: Static HTML / Component Island with client-side interactive sandbox script
- **browser support**: Modern Evergreen Browsers (Safari 16+, Chrome 110+, Firefox 115+, Edge)

## Relevant Subsystems for US-WEB-026

- `web/src/components/DesktopSimulator.astro` (or sandbox component): The interactive macOS desktop container with simulated Menu Bar, wallpaper canvas, mock draggable window, top-edge layout picker overlay, translucent HUD preview overlay, and controls (Reset Sandbox, snap status).
- `web/src/pages/index.astro`: Section `#showcase` where the placeholder box will be replaced with the live interactive simulator.
- `web/src/styles/design-tokens.css`: Glassmorphism tokens (`--glass-bg`, `--glass-border`, `--glass-blur`), snap highlight tokens, spring transition timing curves.

## Hard Constraints (from web/DESIGN.md & Anti-AI-Slop Governance)

- **Zero Generic AI Slop**: Strictly forbid unrequested multi-color neon gradients, excessive glowing orbs, or clunky animations. Stick to authentic macOS Monterey/Sonoma/Sequoia window geometry (12px rounded corners, authentic window controls red/yellow/green, crisp 1px hairline border).
- **Performance Budget (0.0% Idle CPU)**: Any 3D tilt loop, Three.js render loop, or pointer tracking must pause immediately via `IntersectionObserver` when the simulator is scrolled out of viewport.
- **Unified Drag & Drop Physics**: Use Pointer Events with `setPointerCapture` to avoid mouse slip / dropping when dragging outside bounds at fast velocity.
- **Mobile / Touch Responsive**: Responsive scaling or touch-friendly fallback when viewed on mobile screens (< 768px).
