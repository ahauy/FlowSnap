# Architecture & Technical Implementation Plan: FlowSnap SEO, OpenGraph, JSON-LD & GitHub Pages CI/CD (US-WEB-029)

## 1. Architectural Approach & Seam Discipline

Following the Deep Module principles and Apple HIG / Astro Best Practices:

1. **Config Layer (`web/astro.config.mjs`)**:
   - Centralizes `site: 'https://ahauy.github.io'` and `base: process.env.BASE_PATH ?? '/FlowSnap'`.
   - Ensures Astro's asset pipeline, client hydration scripts, and CSS files automatically inherit the appropriate base subpath on production GitHub Pages.
2. **Layout Metadata Seam (`web/src/layouts/BaseLayout.astro`)**:
   - Consolidates meta tag generation into a single declarative template in `<head>`.
   - Computes canonical URL and absolute social image URL using `Astro.site` and `import.meta.env.BASE_URL`.
   - Serializes Schema.org `SoftwareApplication` JSON-LD data structure directly into `<script type="application/ld+json">` with zero client-side JavaScript overhead (pure SSG output).
3. **Static Assets Seam (`web/public/`)**:
   - `og-preview.png`: 1200x630px high-resolution social card.
   - `robots.txt`: Search crawler indexing policy pointing to canonical sitemap.
   - `sitemap.xml`: Standard XML sitemap containing site entry with last modified date, change frequency, and priority.
4. **CI/CD Pipeline Seam (`.github/workflows/deploy-pages.yml`)**:
   - Isolates web deployment into a standard, test-gated GitHub Actions workflow.
   - Triggers only when `web/**` or the workflow itself changes, protecting CI runner minutes.
   - Enforces `npm test` before `npm run build` to prevent broken releases.

---

## 2. File Modification & Creation Inventory

| Action     | Path                                 | Description                                                                                       |
| :--------- | :----------------------------------- | :------------------------------------------------------------------------------------------------ |
| `[MODIFY]` | `web/astro.config.mjs`               | Add `site` and `base` configuration for GitHub Pages deployment.                                  |
| `[MODIFY]` | `web/src/layouts/BaseLayout.astro`   | Expand `<head>` with OpenGraph, Twitter Cards, theme color, canonical link, and JSON-LD script.   |
| `[NEW]`    | `web/public/og-preview.png`          | 1200x630 high-resolution social preview image asset.                                              |
| `[NEW]`    | `web/public/robots.txt`              | Crawler directive file.                                                                           |
| `[NEW]`    | `web/public/sitemap.xml`             | XML sitemap file.                                                                                 |
| `[NEW]`    | `.github/workflows/deploy-pages.yml` | GitHub Actions workflow for test, build, and deploy to GitHub Pages.                              |
| `[NEW]`    | `web/tests/seo-cicd.test.mjs`        | Comprehensive automated test suite verifying metadata, JSON-LD schema, workflow YAML, and assets. |
| `[MODIFY]` | `web/package.json`                   | Include `seo-cicd.test.mjs` in the `npm test` script runner.                                      |

---

## 3. Detailed Component Designs

### 3.1. `web/astro.config.mjs`

```javascript
// @ts-check
import { defineConfig } from "astro/config";

// https://astro.build/config
export default defineConfig({
  site: "https://ahauy.github.io",
  base: process.env.BASE_PATH ?? "/FlowSnap",
});
```

### 3.2. `BaseLayout.astro` JSON-LD Graph Injection

```astro
const schemaData = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'FlowSnap',
  operatingSystem: 'macOS 14.0+',
  applicationCategory: 'UtilitiesApplication',
  softwareVersion: '1.3.1',
  description: description,
  url: canonicalUrl,
  downloadUrl: 'https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg',
  screenshot: absoluteOgImage,
  offers: {
    '@type': 'Offer',
    price: '0',
    priceCurrency: 'USD',
  },
  author: {
    '@type': 'Person',
    name: 'ahauy',
    url: 'https://github.com/ahauy',
  },
  license: 'https://opensource.org/licenses/MIT',
};
```

---

## 4. Verification & Testing Strategy

1. **Automated Unit & Contract Tests (`web/tests/seo-cicd.test.mjs`)**:
   - `TC-SEO-001`: Inspect `BaseLayout.astro` rendered head tags (OpenGraph title, description, url, image, type, site_name, locale).
   - `TC-SEO-002`: Inspect Twitter Cards tags (`summary_large_image`, title, description, image, creator, site).
   - `TC-SEO-003`: Parse and validate Schema.org JSON-LD structure (`SoftwareApplication`, macOS 14.0+, UtilitiesApplication, offers, author).
   - `TC-SEO-004`: Validate `og-preview.png` asset existence, non-empty size, and file signature.
   - `TC-SEO-005`: Validate `robots.txt` and `sitemap.xml` format and URLs.
   - `TC-SEO-006`: Validate `.github/workflows/deploy-pages.yml` YAML syntax, required permissions (`pages: write`, `id-token: write`), and test-gated build steps.
2. **Build Verification**:
   - Run `npm test` in `web` (all suites: desktop-simulator, bento-shortcuts, distribution-hub, seo-cicd).
   - Run `npm run build` in `web` and confirm `web/dist/` contains index.html with correct subpath assets.
