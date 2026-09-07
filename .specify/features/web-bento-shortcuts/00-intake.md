# Intake: Bento Grid Features Showcase, Proof & Interactive Shortcut Matrix (US-WEB-027)

- **Date**: 2026-09-08
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 16, US-WEB-027)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: 3 web components (`BentoGrid.astro`, `MetricsProof.astro`, `ShortcutMatrix.astro`), category filtering and shortcut data models.
  - Existing storage schema change: None (static marketing and interactive client component).
  - Screens/flows touched: Web landing page (`web/src/pages/index.astro`), sections `#features` and `#shortcuts`.
  - User roles affected: 1 (Prospective user & power user evaluating FlowSnap feature set and keyboard navigation).
  - Cross-cutting impact: Visual consistency with Apple HIG and Shadcn tokens (`web/DESIGN.md`), performance budget (< 100KB gzipped, zero external webfonts, zero FOIT/FOUT), keyboard a11y (ARIA tabs/filters).
  - Estimated code lines changed: 400–600 lines.
  - Reversible without user impact: Yes (isolated web presentation layer).
- **Protocol selected**: Bounded Task (Stages 1 → 2 (interactive interview) → 4 (light) → 5 (light) → 6 (user stories) → 7 → 8; Stage 3 gap-analysis skipped).
- **Override**: None (matches Roadmap Effort: M).
- **Depends-on**: `US-WEB-026` ✅
- **Blocks**: `US-WEB-028` (Distribution Hub), `US-WEB-029` (SEO/CI-CD).

## One-line problem statement

Người dùng truy cập trang web FlowSnap cần một bảng giới thiệu tính năng dạng Bento Grid trực quan (6 tính năng trụ cột), một dải số liệu kỹ thuật minh bạch chứng minh chất lượng (Swift 6 Strict Concurrency, 0 Private APIs, 470+ Unit Tests, < 1ms Snap Math) và một bảng tra cứu phím tắt tương tác có lọc theo danh mục để nhanh chóng nắm bắt sức mạnh và sự tiện lợi của FlowSnap trước khi cài đặt.
