# Functional Specification: FlowSnap SEO, OpenGraph, JSON-LD & GitHub Pages CI/CD (US-WEB-029)

## 1. Functional Requirements (`REQ-SEO-###`)

- **`REQ-SEO-001` (Comprehensive OpenGraph & Twitter Cards Meta Tags)**:
  - `BaseLayout.astro` SHALL provide semantic and valid OpenGraph tags:
    - `og:type`: `"website"`
    - `og:url`: Absolute canonical URL (e.g. `https://ahauy.github.io/FlowSnap`)
    - `og:title`: Title of the page or fallback `"FlowSnap — macOS Window Manager with Intent & Snap Precision"`
    - `og:description`: Accurate description of FlowSnap features and architecture
    - `og:image`: Absolute URL `https://ahauy.github.io/FlowSnap/og-preview.png`
    - `og:image:width`: `"1200"`
    - `og:image:height`: `"630"`
    - `og:image:alt`: `"FlowSnap — macOS Window Manager with Intent & Snap Precision"`
    - `og:image:type`: `"image/png"`
    - `og:site_name`: `"FlowSnap"`
    - `og:locale`: `"en_US"`
  - `BaseLayout.astro` SHALL provide standard Twitter Cards tags:
    - `twitter:card`: `"summary_large_image"`
    - `twitter:url`: Absolute canonical URL
    - `twitter:title`: Title matching OpenGraph title
    - `twitter:description`: Description matching OpenGraph description
    - `twitter:image`: Absolute URL `https://ahauy.github.io/FlowSnap/og-preview.png`
    - `twitter:creator`: `"@ahauy"`
    - `twitter:site`: `"@ahauy"`
  - _Derived from_: `BR-SEO-001`, `DEC-SEO-002`, `US-SEO-002`.

- **`REQ-SEO-002` (Schema.org `SoftwareApplication` JSON-LD Structured Data)**:
  - `BaseLayout.astro` SHALL inject an inline `<script type="application/ld+json">` tag containing a strictly valid JSON-LD graph.
  - The graph SHALL describe a `SoftwareApplication`:
    - `@context`: `"https://schema.org"`
    - `@type`: `"SoftwareApplication"`
    - `name`: `"FlowSnap"`
    - `applicationCategory`: `"UtilitiesApplication"`
    - `operatingSystem`: `"macOS 14.0+"`
    - `softwareVersion`: `"1.3.1"`
    - `description`: `"Native macOS window manager with Windows 11-style snap picker, multi-display intent restoration, Quake scratchpad, and zero private APIs."`
    - `url`: `"https://ahauy.github.io/FlowSnap"`
    - `downloadUrl`: `"https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg"`
    - `screenshot`: `"https://ahauy.github.io/FlowSnap/og-preview.png"`
    - `offers`: Object with `@type: "Offer"`, `price: "0"`, `priceCurrency: "USD"`
    - `author`: Object with `@type: "Person"`, `name: "ahauy"`, `url: "https://github.com/ahauy"`
    - `license`: `"https://opensource.org/licenses/MIT"`
  - _Derived from_: `BR-SEO-002`, `ASM-SEO-002`, `US-SEO-001`.

- **`REQ-SEO-003` (High-Resolution Social Preview Card Asset)**:
  - A production-ready 1200x630 pixel static asset SHALL be located at `web/public/og-preview.png`.
  - The preview asset SHALL adhere to Apple HIG and FlowSnap's obsidian design palette (`#09090b` canvas, 1px hairline border, crisp window snap geometry, metrics badge: 470+ tests, < 1ms math, 0 private APIs).
  - _Derived from_: `BR-SEO-005`, `DEC-SEO-002`, `US-SEO-002`.

- **`REQ-SEO-004` (Search Engine Indexing Directives & Sitemap)**:
  - `web/public/robots.txt` SHALL be provided with:
    ```txt
    User-agent: *
    Allow: /
    Sitemap: https://ahauy.github.io/FlowSnap/sitemap.xml
    ```
  - `web/public/sitemap.xml` SHALL declare the canonical URL with `<lastmod>`, `<changefreq>weekly</changefreq>`, and `<priority>1.0</priority>`.
  - _Derived from_: `BR-SEO-006`, `ASM-SEO-003`, `US-SEO-001`.

- **`REQ-SEO-005` (Test-Gated GitHub Actions CI/CD Workflow)**:
  - A workflow file `.github/workflows/deploy-pages.yml` SHALL automate static deployment to GitHub Pages.
  - Trigger conditions:
    - `push` to branch `main` with paths filter: `web/**`, `.github/workflows/deploy-pages.yml`.
    - `workflow_dispatch` (manual one-click trigger).
  - Environment permissions:
    - `contents: read`, `pages: write`, `id-token: write`.
  - Steps execution pipeline:
    1. Checkout code (`actions/checkout@v4`).
    2. Setup Node.js 22 (`actions/setup-node@v4` with cache: `npm`, cache-dependency-path: `web/package-lock.json`).
    3. Install dependencies (`npm ci` in `web`).
    4. Execute test suite (`npm test` in `web`). Any failure terminates the run before build.
    5. Build static site (`npm run build` in `web`).
    6. Configure GitHub Pages (`actions/configure-pages@v5`).
    7. Upload Pages artifact (`actions/upload-pages-artifact@v3`, path: `web/dist`).
    8. Deploy to GitHub Pages (`actions/deploy-pages@v4`).
  - _Derived from_: `BR-SEO-004`, `DEC-SEO-003`, `US-SEO-003`.

- **`REQ-SEO-006` (Base Path & GitHub Pages Subpath Compatibility)**:
  - `web/astro.config.mjs` SHALL declare:
    - `site: 'https://ahauy.github.io'`
    - `base: process.env.BASE_PATH ?? '/FlowSnap'`
  - All internal links and static assets in components and layouts SHALL respect `import.meta.env.BASE_URL` or Astro's base routing so that pages and assets render without 404 on `https://ahauy.github.io/FlowSnap/`.
  - _Derived from_: `BR-SEO-003`, `DEC-SEO-001`.

---

## 2. Non-Functional Requirements (`NFR-SEO-###`)

- **`NFR-SEO-001` (Zero Cumulative Layout Shift & FOIT/FOUT)**: The inclusion of OpenGraph meta tags, JSON-LD scripts, and social cards SHALL introduce 0.0ms blocking render overhead and zero layout shift.
- **`NFR-SEO-002` (Lighthouse Audit Score >= 95+)**: The built output SHALL score >= 95 in Performance, Accessibility, Best Practices, and SEO.
- **`NFR-SEO-003` (Pipeline Speed)**: The GitHub Actions build and deploy pipeline SHALL execute in under 2 minutes on standard GitHub-hosted runners.
- **`NFR-SEO-004` (Zero Telemetry & Privacy Integrity)**: No external tracker or third-party analytics script SHALL ever be introduced.
