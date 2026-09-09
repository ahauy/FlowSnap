# Test Plan: FlowSnap SEO, OpenGraph, JSON-LD Schema & GitHub Pages CI/CD

**Feature slug**: `web-seo-cicd`  
**Baseline version**: `1.0 (SIGNED-OFF)`  
**Written by**: AI (`frontend-developer` / `backend-developer` TDD Scaffolding)  
**Traces to**: `.specify/features/web-seo-cicd/06-spec-and-stories.md`

---

## 1. Test Suite Specifications

### TC-SEO-001: OpenGraph Meta Tags Completeness & Absolute URLs

```gherkin
Given BaseLayout.astro is rendered with default or custom props
When  an external crawler inspects the <head> tags
Then  og:title, og:description, og:type, og:site_name, og:locale, og:url are present
  And og:image is an absolute URL containing "https://ahauy.github.io/FlowSnap/og-preview.png"
  And og:image:width is 1200 and og:image:height is 630
```

- **File**: `web/tests/seo-cicd.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-SEO-001`, `US-SEO-002` Scenario 1

---

### TC-SEO-002: Twitter Cards Summary Large Image

```gherkin
Given BaseLayout.astro is rendered
When  Twitter crawler inspects Twitter meta tags
Then  twitter:card equals "summary_large_image"
  And twitter:title, twitter:description, twitter:image are present
  And twitter:image is an absolute URL
  And twitter:site and twitter:creator are "@ahauy"
```

- **File**: `web/tests/seo-cicd.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-SEO-001`, `US-SEO-002` Scenario 1

---

### TC-SEO-003: Schema.org SoftwareApplication JSON-LD Structured Data

```gherkin
Given BaseLayout.astro is rendered
When  Google Rich Snippet parser extracts <script type="application/ld+json">
Then  JSON payload is valid and has @type "SoftwareApplication"
  And operatingSystem is "macOS 14.0+"
  And applicationCategory is "UtilitiesApplication"
  And offers.price is "0" and offers.priceCurrency is "USD"
  And author.name is "ahauy"
  And downloadUrl points to GitHub Releases DMG
```

- **File**: `web/tests/seo-cicd.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-SEO-002`, `US-SEO-001` Scenario 1

---

### TC-SEO-004: Social Preview Card Asset Presence & Format

```gherkin
Given web/public/ directory
When  the crawler requests og-preview.png
Then  web/public/og-preview.png exists
  And file size is greater than 10KB and less than 500KB
  And file header begins with PNG binary signature (0x89 0x50 0x4E 0x47)
```

- **File**: `web/tests/seo-cicd.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-SEO-003`, `US-SEO-002`

---

### TC-SEO-005: Crawling Policy Directives (robots.txt & sitemap.xml)

```gherkin
Given web/public/ directory
When  search crawlers inspect robots.txt and sitemap.xml
Then  web/public/robots.txt contains "User-agent: *" and "Allow: /"
  And robots.txt references "Sitemap: https://ahauy.github.io/FlowSnap/sitemap.xml"
  And web/public/sitemap.xml is valid XML containing the canonical landing page URL
```

- **File**: `web/tests/seo-cicd.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-SEO-004`, `US-SEO-001` Scenario 2

---

### TC-SEO-006: GitHub Actions Workflow & Subpath Configuration

```gherkin
Given .github/workflows/deploy-pages.yml and web/astro.config.mjs
When  workflow file and config are validated
Then  workflow triggers on push to main with web/** and workflow path filter
  And workflow requires "contents: read", "pages: write", "id-token: write"
  And workflow runs npm test before npm run build (Test Gate)
  And uses actions/configure-pages@v5, upload-pages-artifact@v3, deploy-pages@v4
  And astro.config.mjs declares site "https://ahauy.github.io" and base with "/FlowSnap" fallback
```

- **File**: `web/tests/seo-cicd.test.mjs`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-SEO-005`, `REQ-SEO-006`, `US-SEO-003`
