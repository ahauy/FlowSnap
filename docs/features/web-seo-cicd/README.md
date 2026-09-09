# Feature: SEO, OpenGraph, JSON-LD Schema & Automated GitHub Pages CI/CD (`web-seo-cicd`)

## Overview

- **User Story**: `US-WEB-029` (SEO, OpenGraph, JSON-LD Schema & Automated GitHub Pages CI/CD)
- **Epic**: `EPIC 16` — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal (Sprint 8)
- **Platform**: Web (`web/`), static SSG via Astro v7 & GitHub Actions CI/CD
- **Design System**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)

---

## Architectural Highlights

1. **GitHub Pages Deployment Seam & Base Path (`web/astro.config.mjs`)**:
   - Sets `site: 'https://ahauy.github.io'` and `base: process.env.BASE_PATH ?? '/FlowSnap'`.
   - Ensures all static bundles (`_astro/`), favicons, and social assets automatically inherit the `/FlowSnap` subpath for GitHub Pages project sites without broken links or 404s.
   - Allows seamless override via `BASE_PATH` environment variable when binding a custom apex or subdomain.

2. **Rich Head Metadata & Social Cards (`web/src/layouts/BaseLayout.astro`)**:
   - Comprehensive OpenGraph implementation: `og:title`, `og:description`, `og:url` (canonical), `og:image` (absolute URL), `og:image:width` (1200), `og:image:height` (630), `og:site_name`, `og:locale`.
   - Complete Twitter Card specification: `twitter:card` (`summary_large_image`), `twitter:title`, `twitter:description`, `twitter:image`, `twitter:site` (`@ahauy`), `twitter:creator` (`@ahauy`).
   - Theme color tags adapting automatically to dark (`#09090b`) and light (`#ffffff`) operating system color schemes.

3. **Schema.org Structured Data (`SoftwareApplication` JSON-LD)**:
   - Injects valid Schema.org graph for Google Search Console rich snippets:
     - `@type`: `SoftwareApplication`
     - `operatingSystem`: `macOS 14.0+`
     - `applicationCategory`: `UtilitiesApplication`
     - `softwareVersion`: `1.3.1`
     - `downloadUrl`: Direct release download link for `FlowSnap.dmg`
     - `screenshot`: Absolute URL to high-res preview
     - `offers`: Free open-source software (`price: "0"`, `priceCurrency: "USD"`)
     - `author`: `ahauy` (`https://github.com/ahauy`)
     - `license`: MIT License

4. **Production Social Preview Asset (`web/public/og-preview.png`)**:
   - 1200x630px high-resolution social preview image conforming strictly to Apple HIG and FlowSnap's obsidian design aesthetic.
   - Visualizes the 70/30 collinear split window layout, native traffic light dots, product branding, and key performance verification badges (Swift 6, 0 Private APIs, 470+ tests, < 1ms snap math).
   - Zero AI-slop: No generic multi-color neon gradients, blurred orbs, or stock graphics.

5. **Search Engine Crawling Directives**:
   - `web/public/robots.txt`: Grants open access to all search engines (`User-agent: *`, `Allow: /`) and directs crawlers to the XML sitemap.
   - `web/public/sitemap.xml`: Standard XML sitemap pointing to the canonical landing page with weekly change frequency and priority 1.0.

6. **Test-Gated Automated CI/CD Pipeline (`.github/workflows/deploy-pages.yml`)**:
   - Trigger: push to `main` with path filters (`web/**`, `.github/workflows/deploy-pages.yml`) and `workflow_dispatch`.
   - Setup Node.js 22 with npm cache.
   - **Test Gate**: Runs `npm test` across all 4 test suites before building. If any test fails, deployment is aborted.
   - **Build Step**: Executes `npm run build` using Astro SSG.
   - **Deploy Step**: Leverages official GitHub Pages actions (`actions/configure-pages@v5`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4`).

---

## Deliverables & File Tree

```
FlowSnap/
├── .github/
│   └── workflows/
│       └── deploy-pages.yml             # GitHub Actions CI/CD deployment workflow
├── web/
│   ├── astro.config.mjs                 # site: https://ahauy.github.io, base: /FlowSnap
│   ├── package.json                     # test runner covering all 4 test suites
│   ├── public/
│   │   ├── favicon.ico
│   │   ├── favicon.svg
│   │   ├── og-preview.png               # 1200x630 high-res social preview card
│   │   ├── robots.txt                   # Search crawler directives
│   │   └── sitemap.xml                  # XML sitemap
│   ├── src/
│   │   └── layouts/
│   │       └── BaseLayout.astro         # Expanded SEO, OpenGraph, Twitter & JSON-LD
│   └── tests/
│       ├── desktop-simulator.test.mjs
│       ├── bento-shortcuts.test.mjs
│       ├── distribution-hub.test.mjs
│       └── seo-cicd.test.mjs            # 6 test cases verifying SEO & CI/CD contracts
```

---

## Verification Evidence

All 4 test suites pass cleanly via `npm test` inside `web/`:

- `desktop-simulator.test.mjs`: 8/8 test cases passed.
- `bento-shortcuts.test.mjs`: 8/8 test cases passed.
- `distribution-hub.test.mjs`: 6/6 test cases passed.
- `seo-cicd.test.mjs`: 6/6 test cases passed.
- `astro build`: Compiles `web/dist/` in < 350ms with 0 errors and valid subpath asset references.
