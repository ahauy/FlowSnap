# Tech Context: FlowSnap Web Landing Page (US-WEB-025)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1) and `web/DESIGN.md`.
> This file is the single source of truth for tech-stack facts of the web portal. Every subagent
> reads this file first; do not re-paste this blob into dispatch `task` arguments.

## Stack

- **framework**: Astro (v7.x, static output mode, zero-JS baseline by default)
- **language**: TypeScript / JavaScript (ESM)
- **styling**: Vanilla CSS + Semantic CSS Variables (`web/src/styles/design-tokens.css`)
- **design system**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)
- **typography**: System font stack (`-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif`, `"SF Mono", Menlo, monospace`) for zero-latency 0ms FCP/LCP
- **package manager**: npm / node (`>= 22.12.0`)
- **rendering**: Static HTML Generation (`astro build` -> `web/dist/`)
- **browser support**: Modern Evergreen Browsers (Safari 16+, Chrome 110+, Firefox 115+, Edge)

## Relevant Subsystems for US-WEB-025

- `web/src/layouts/BaseLayout.astro`: Core HTML skeleton, SEO metadata, theme toggle script, font configurations, anti-FOUC inline script.
- `web/src/components/Header.astro`: Sticky macOS-style navigation header with FlowSnap logo/icon, version badge (`v1.3.1`), GitHub repo link with stars badge, theme toggle button, and smooth blur backdrop.
- `web/src/components/Footer.astro`: Professional open-source footer, MIT license disclosure, author link (`@ahauy`), navigation anchors to Guides, Documentation, and GitHub Releases.
- `web/src/components/ThemeToggle.astro`: Zero-layout-shift theme switcher (Light / Dark) persisting to `localStorage` and respecting `prefers-color-scheme`.
- `web/src/styles/design-tokens.css`: Core design system variables, hairline borders, macOS liquid glass tints, elevation shadows, spring transition easing curves.
- `web/src/pages/index.astro`: Entry page rendering `BaseLayout`, `Header`, slot/content area, and `Footer`.

## Hard Constraints (from web/DESIGN.md & Anti-AI-Slop Governance)

- **Zero Generic AI Slop**: Strictly forbid unrequested multi-color gradients (`bg-gradient-to-r from-purple-500 to-indigo-600`), floating blurred neon orbs, or heavy dark-mode glassmorphism that harms readability.
- **Zero FOUC (Flash of Unstyled Content) & FOIT**: Theme resolution script MUST run inline in `<head>` before body render to guarantee seamless dark/light mode hydration without a flash of white/black.
- **System Font Stack First**: Use native system fonts for zero network latency and instant 0ms FCP.
- **1px Hairline Precision**: Borders must be `1px solid var(--border-color)` (`#e4e4e7` on light, `rgba(255, 255, 255, 0.08)` on dark).
- **Sub-1s Load Budget**: Static output, minimal JS payload.
