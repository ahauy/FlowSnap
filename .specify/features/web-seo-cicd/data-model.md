# Data Models & Contracts: FlowSnap SEO & GitHub Pages CI/CD (US-WEB-029)

## 1. Layout Props Contract (`PageMetaProps`)

```typescript
export interface PageMetaProps {
  title?: string;
  description?: string;
  canonicalUrl?: string;
  ogImage?: string;
  keywords?: string[];
  author?: string;
}
```

Default Values:

```typescript
const DEFAULT_META: Required<PageMetaProps> = {
  title: "FlowSnap — macOS Window Manager with Intent & Snap Precision",
  description:
    "Native macOS window manager with Windows 11-style snap picker, multi-display intent restoration, Quake scratchpad, and zero private APIs.",
  canonicalUrl: "https://ahauy.github.io/FlowSnap",
  ogImage: "https://ahauy.github.io/FlowSnap/og-preview.png",
  keywords: [
    "FlowSnap",
    "macOS window manager",
    "snap layouts",
    "Windows 11 snap macOS",
    "Swift 6",
    "macOS utility",
    "tiling window manager",
    "multi-monitor macOS",
    "Quake scratchpad",
  ],
  author: "ahauy",
};
```

---

## 2. Schema.org JSON-LD Contract (`JsonLdSoftwareApplication`)

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "FlowSnap",
  "operatingSystem": "macOS 14.0+",
  "applicationCategory": "UtilitiesApplication",
  "softwareVersion": "1.3.1",
  "description": "Native macOS window manager with Windows 11-style snap picker, multi-display intent restoration, Quake scratchpad, and zero private APIs.",
  "url": "https://ahauy.github.io/FlowSnap",
  "downloadUrl": "https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg",
  "screenshot": "https://ahauy.github.io/FlowSnap/og-preview.png",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  },
  "author": {
    "@type": "Person",
    "name": "ahauy",
    "url": "https://github.com/ahauy"
  },
  "license": "https://opensource.org/licenses/MIT"
}
```

---

## 3. GitHub Actions Workflow Contract (`.github/workflows/deploy-pages.yml`)

```yaml
name: Deploy FlowSnap Web to GitHub Pages

on:
  push:
    branches: [main]
    paths:
      - "web/**"
      - ".github/workflows/deploy-pages.yml"
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build-and-deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Node.js 22
        uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: "npm"
          cache-dependency-path: web/package-lock.json

      - name: Install dependencies
        run: npm ci
        working-directory: web

      - name: Run Web Test Suite
        run: npm test
        working-directory: web

      - name: Build static site with Astro
        run: npm run build
        working-directory: web

      - name: Setup Pages
        uses: actions/configure-pages@v5

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: web/dist

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```
