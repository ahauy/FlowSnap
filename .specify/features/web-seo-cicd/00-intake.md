# Intake: SEO, OpenGraph, JSON-LD Schema & Automated GitHub Pages CI/CD (US-WEB-029)

- **Date**: 2026-09-08
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 16, US-WEB-029)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: Web SEO metadata, OpenGraph tags, Twitter Card tags, Schema.org `SoftwareApplication` JSON-LD, `robots.txt`, `sitemap.xml`, social preview banner (`og-preview.png`), and GitHub Actions workflow (`.github/workflows/deploy-pages.yml`).
  - Existing storage schema change: None (static presentation and CI/CD workflow configuration).
  - Screens/flows touched: `BaseLayout.astro`, `astro.config.mjs`, `public/`, `.github/workflows/`.
  - User roles affected: 2 (Search engines/crawlers indexing the site, prospective users viewing social links on Twitter/LinkedIn/Discord/iMessage, and project maintainer triggering deployments on push to `main`).
  - Cross-cutting impact: Social card sharing fidelity, Google search snippet richness, zero-maintenance automated GitHub Pages deployment pipeline, 95+ Lighthouse score.
  - Estimated code lines changed: ~200–350 lines.
  - Reversible without user impact: Yes (metadata and CI/CD configuration).
- **Protocol selected**: Bounded Task (Stages 1 → 2 (interactive interview) → 4 (light) → 5 (light) → 6 (user stories) → 7 → 8; Stage 3 gap-analysis skipped).
- **Override**: None (matches Roadmap Effort: M).
- **Depends-on**: `US-WEB-028` ✅
- **Blocks**: _(none — final story of Sprint 8 / EPIC 16)_

## One-line problem statement

Trang web FlowSnap cần được tối ưu hóa toàn diện về SEO, thẻ mạng xã hội OpenGraph / Twitter Cards chuẩn mực với ảnh đại diện chia sẻ chất lượng cao, dữ liệu có cấu trúc `SoftwareApplication` JSON-LD để hiển thị rich snippet trên Google Search, đồng thời trang bị quy trình GitHub Actions CI/CD tự động build và xuất bản lên GitHub Pages mỗi khi commit vào nhánh `main`.
