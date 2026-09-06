# Intake: Astro Baseline, Shadcn-Inspired Design Tokens & Base Layout (US-WEB-025)

- **Date**: 2026-09-06
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 16, US-WEB-025)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: 4 Astro layout & component modules (`BaseLayout`, `Header`, `Footer`, `ThemeToggle`)
  - Existing storage schema change: None (uses browser `localStorage` for theme preference)
  - Screens/flows touched: Web entrypoint (`web/src/pages/index.astro`), layouts (`BaseLayout.astro`), components (`Header.astro`, `Footer.astro`, `ThemeToggle.astro`), styles (`design-tokens.css`)
  - User roles affected: 1 (Prospective or existing macOS power user visiting the official web showcase)
  - Cross-cutting impact: Brand visual foundation, zero-FOUC theme switching, mobile-to-desktop responsive viewport constraints, SEO baseline meta tags
  - Estimated code lines changed: 250–400 lines
  - Reversible without user impact: Yes (isolated static site package in `web/`)
- **Protocol selected**: Bounded Task (Stages 1 → 2 → 4 → 5 → 6 → 7 → 8; Stage 3 gap-analysis skipped)
- **Override**: None (matches Roadmap Effort: M)
- **Depends-on**: `(none)` ✅
- **Blocks**: `US-WEB-026` (Hero 3D Showcase), `US-WEB-027` (Bento Grid), `US-WEB-028` (Download Hub), `US-WEB-029` (SEO/CI-CD)

## One-line problem statement

Khách truy cập cần một trang giới thiệu chính thức cho FlowSnap với tốc độ tải siêu tốc (< 1s), thiết kế chuẩn mực Apple HIG kết hợp phong cách Shadcn tối giản, hỗ trợ tự động nhận diện và chuyển đổi mượt mà giữa Dark mode và Light mode không bị chớp giật (Zero FOUC), cùng thanh điều hướng (Sticky Header) và chân trang (Footer) tiêu chuẩn mã nguồn mở.
