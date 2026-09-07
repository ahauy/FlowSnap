# Tech Context: FlowSnap Bento Grid Showcase, Metrics Proof & Shortcut Matrix (US-WEB-027)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1) and `web/DESIGN.md`.
> This file is the single source of truth for tech-stack facts of the web bento grid and shortcut matrix feature.
> Subagents and execution phases read this file first.

## Stack

- **framework**: Astro (v7.3.1, static output mode, zero-JS baseline where possible)
- **language**: TypeScript / JavaScript (ESM)
- **styling**: Vanilla CSS + Semantic CSS Variables (`web/src/styles/design-tokens.css`)
- **design system**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)
- **typography**: System font stack (`-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif`, `"SF Mono", Menlo, monospace`)
- **client interactivity**: Vanilla lightweight client script for interactive category filtering (`Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`), live search, and visual keypress simulation.
- **performance & accessibility**: WCAG 2.2 AA compliant contrast, zero layout shift (CLS 0.0), fast rendering with no external CDN dependencies.
- **browser support**: Modern Evergreen Browsers (Safari 16+, Chrome 110+, Firefox 115+, Edge)

## Relevant Subsystems for US-WEB-027

- `web/src/components/BentoGrid.astro`: 6-card Bento Grid presenting the 6 core pillars of FlowSnap (Top-Edge Picker, Collinear 2D Resize, Current Space Anchoring, Workspaces & Presets, Quake Scratchpad, Multi-Monitor Topology) with crisp SVG/WebP vector previews, badge indicators, and hover elevation.
- `web/src/components/MetricsProof.astro`: Verifiable metrics banner/strip showcasing FlowSnap engineering milestones (Swift 6 Strict Concurrency, 0 Private APIs, 470+ Unit Tests, < 1ms Snap Math, 60 FPS Divider Resize).
- `web/src/components/ShortcutMatrix.astro`: Interactive keyboard shortcut explorer with real-time category filters (`All`, `Window`, `Display`, `Workspace`, `Utilities`), keycap pills with authentic macOS modifier symbols (`⌘`, `⌥`, `⌃`, `⇧`), and description/action mapping.
- `web/src/pages/index.astro`: Replace placeholder boxes in `#features` and `#shortcuts` with live, interactive components.

## Hard Constraints (from web/DESIGN.md & Anti-AI-Slop Governance)

- **Zero Generic AI Slop**: Strictly forbid unrequested multi-color neon gradients, excessive floating neon orbs, or clunky animations.
- **Hairline Precision**: 1px borders using `var(--color-border)` (`rgba(255, 255, 255, 0.08)` dark, `#e4e4e7` light).
- **Embossed Shortcut Keycaps**: Keycaps must use authentic macOS keyboard styling (SF Mono, subtle border, elevation, rounded corners).
- **Responsive Layout**: Bento grid must adapt from desktop 3-column / asymmetric bento to 2-column on tablet and 1-column on mobile (< 768px).
