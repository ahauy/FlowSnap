# Tech Context: FlowSnap SEO, OpenGraph, JSON-LD Schema & Automated GitHub Pages CI/CD (US-WEB-029)

> Source: YAML frontmatter in `docs/PRODUCT_BACKLOG_ROADMAP.md` (schema-version 1.1) and `web/DESIGN.md`.
> This file is the single source of truth for tech-stack facts of the web SEO & CI/CD deployment feature.
> Subagents and execution phases read this file first.

## Stack

- **framework**: Astro (v7.3.1, static output mode `static`, zero-JS baseline where possible)
- **language**: TypeScript / JavaScript (ESM) / GitHub Actions YAML
- **styling**: Vanilla CSS + Semantic CSS Variables (`web/src/styles/design-tokens.css`)
- **design system**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)
- **structured data**: Schema.org JSON-LD (`SoftwareApplication`, `OperatingSystem: macOS 14.0+`, `ApplicationCategory: UtilitiesApplication`)
- **meta specifications**: OpenGraph (og:title, og:description, og:image, og:url, og:type, og:locale), Twitter Cards (`summary_large_image`)
- **crawling & indexing**: `robots.txt`, XML sitemap (`sitemap.xml`) or Astro sitemap integration, canonical URL normalization
- **continuous deployment**: GitHub Actions (`.github/workflows/deploy-pages.yml`) deploying static dist artifact to GitHub Pages with official actions (`actions/configure-pages`, `actions/upload-pages-artifact`, `actions/deploy-pages`)
- **test runner**: Node.js test scripts (`web/tests/seo-cicd.test.mjs`) verifying tag completeness, valid JSON-LD structure, asset presence, and GitHub Actions workflow syntax

## Relevant Subsystems for US-WEB-029

- `web/astro.config.mjs`:
  - Configure `site: 'https://ahauy.github.io'` and `base: '/FlowSnap'` (or dynamic/environment-driven) for GitHub Pages compatibility.
- `web/src/layouts/BaseLayout.astro`:
  - Expand head metadata: comprehensive OpenGraph tags, Twitter cards, meta keywords, author tags, robots directive, and JSON-LD structured data script.
- `web/public/`:
  - `og-preview.png`: 1200x630px high-resolution social preview card with FlowSnap brand typography, window snapping visual, and Apple HIG aesthetic.
  - `robots.txt`: Standard crawling directives allowing all search engines and referencing sitemap.
  - `sitemap.xml`: XML sitemap with landing page URL, priority, and changefreq.
- `.github/workflows/deploy-pages.yml`:
  - GitHub Actions CI/CD pipeline triggered on push to `main` (with path filtering for `web/**`).
  - Sets up Node 22, installs dependencies (`npm ci` inside `web`), builds static output (`npm run build`), uploads GitHub Pages artifact from `web/dist`, and deploys via GitHub Pages environment.

## Hard Constraints & Governance Rules

- **Zero Private API & Accurate Product Truth**: All SEO metadata, JSON-LD attributes, and OpenGraph descriptions must reflect authentic product facts (macOS 14.0+, Apple Silicon & Intel, 100% Offline, Zero Telemetry, Free Open Source MIT).
- **Zero AI-Slop Social Preview**: The social preview asset must follow obsidian dark theme, clean typography, 1px hairline border, and crisp branding without neon gradients or generic stock visuals.
- **Lighthouse 95+ Compliance**: Zero blocking render scripts, clean semantic markup, explicit image dimensions and alt text, optimized crawlability.
