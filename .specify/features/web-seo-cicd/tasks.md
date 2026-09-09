# Implementation Tasks: FlowSnap SEO, OpenGraph, JSON-LD & GitHub Pages CI/CD (US-WEB-029)

## Phase 1: Test Scaffolding & Specifications

- [x] `TASK-SEO-001`: Create `test-plan.md` mapping `US-SEO-001..003` to test cases `TC-SEO-001..006`.
- [x] `TASK-SEO-002`: Implement `web/tests/seo-cicd.test.mjs` test runner asserting OpenGraph tags, JSON-LD schema structure, static asset files, and GitHub Actions workflow configuration.
- [x] `TASK-SEO-003`: Update `web/package.json` test script to include `seo-cicd.test.mjs` and `distribution-hub.test.mjs`.

## Phase 2: Static Assets & Crawling Policies

- [x] `TASK-SEO-004`: Create `web/public/robots.txt` allowing indexing and pointing to `https://ahauy.github.io/FlowSnap/sitemap.xml`.
- [x] `TASK-SEO-005`: Create `web/public/sitemap.xml` with canonical URL, `lastmod`, `changefreq: weekly`, and `priority: 1.0`.
- [x] `TASK-SEO-006`: Generate production-ready 1200x630px social card `web/public/og-preview.png` matching FlowSnap Obsidian design language and Apple HIG.

## Phase 3: Base Configuration & Layout Metadata

- [x] `TASK-SEO-007`: Update `web/astro.config.mjs` with `site: 'https://ahauy.github.io'` and `base: process.env.BASE_PATH ?? '/FlowSnap'`.
- [x] `TASK-SEO-008`: Update `web/src/layouts/BaseLayout.astro` to render comprehensive OpenGraph tags, Twitter Card tags, absolute canonical/image URLs, and Schema.org `SoftwareApplication` JSON-LD script.

## Phase 4: Automated CI/CD Deployment Workflow

- [x] `TASK-SEO-009`: Create `.github/workflows/deploy-pages.yml` with push trigger on `main` (path filter `web/**`), Node 22 setup, `npm test` gate, `npm run build`, and `actions/deploy-pages@v4`.

## Phase 5: Full Verification & Quality Audit

- [x] `TASK-SEO-010`: Run `npm test` across all 4 web test suites and verify 100% pass rate.
- [x] `TASK-SEO-011`: Run `npm run build` and verify that `web/dist/` contains valid index.html with correct subpath assets.

## Phase 6: Adversarial Review & Documentation

- [x] `TASK-SEO-012`: Conduct dual-pass code review (Standards + Spec fidelity).
- [x] `TASK-SEO-013`: Create technical documentation `docs/features/web-seo-cicd/README.md`.
- [x] `TASK-SEO-014`: Create user guide `docs/user-guides/web-seo-cicd.md`.
- [x] `TASK-SEO-015`: Mark US-WEB-029 as `[x]` in `docs/PRODUCT_BACKLOG_ROADMAP.md`.
