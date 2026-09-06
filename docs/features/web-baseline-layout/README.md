# Feature: Astro Baseline, Shadcn-Inspired Design Tokens & Base Layout (`web-baseline-layout`)

## Overview

- **User Story**: `US-WEB-025` (Khung kiến trúc Astro, Shadcn Design Tokens & Base Responsive Layout)
- **Epic**: `EPIC 16` — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal (Sprint 8)
- **Platform**: Web (`web/`), static HTML generation via Astro v7
- **Design System**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)

---

## Architectural Highlights

1. **Static-First & Zero Runtime Overhead**:
   - Built with Astro in static mode (`output: "static"`).
   - Fast loading (< 1s), Cumulative Layout Shift (CLS) = 0.
   - Strictly uses native system font stack (`-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", sans-serif`, `"SF Mono", Menlo, monospace`) to eliminate webfont network lag (Zero FOIT/FOUT).
2. **Zero-FOUC Theme Management**:
   - Inline blocking script synchronously loaded in `<head>` of `BaseLayout.astro`.
   - Reads `localStorage.getItem('flowsnap-theme')` or system `prefers-color-scheme: dark`.
   - Sets `data-theme` attribute on `<html>` before any DOM paint.
   - Accessible `ThemeToggle.astro` component allows toggling between Obsidian Dark (`#09090b`) and Clean Light (`#ffffff`).
3. **macOS Liquid Glass Sticky Header**:
   - `Header.astro` stays pinned to the top of the viewport (`position: sticky; top: 0; z-index: 50`).
   - Liquid glass translucency (`backdrop-filter: blur(20px)`), 1px hairline bottom border (`var(--border-color)`).
   - Includes FlowSnap icon, version badge (`v1.3.1`), section anchors (`#features`, `#showcase`, `#shortcuts`, `#download`), GitHub button, and `ThemeToggle`.
   - Sections configure `scroll-margin-top: 80px` to prevent header overlay.
4. **Open-Source Attribution & Footer**:
   - `Footer.astro` includes MIT License attribution, author link (`@ahauy`), architecture manifesto, and links to Guides, Releases, and Issues.

---

## Deliverables & File Tree

```
web/
├── src/
│   ├── components/
│   │   ├── Header.astro           # Sticky macOS header with brand, anchors & actions
│   │   ├── Footer.astro           # Open-source MIT footer with links & manifesto
│   │   └── ThemeToggle.astro      # Zero-layout-shift Dark/Light switcher
│   ├── layouts/
│   │   └── BaseLayout.astro       # Root HTML layout with SEO, OpenGraph & anti-FOUC script
│   ├── pages/
│   │   └── index.astro            # Entry landing page assembling all components
│   └── styles/
│       └── design-tokens.css      # Shadcn-inspired semantic CSS variables & utilities
```

---

## Verification

- **Build**: `npm run build` completed cleanly in `285ms`.
- **Static Artifacts**: `web/dist/index.html` generated with valid metadata, inline scripts, and CSS bundle.
