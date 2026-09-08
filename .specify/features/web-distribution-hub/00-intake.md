# Intake: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

- **Date**: 2026-09-08
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 16, US-WEB-028)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: Web distribution components (`DistributionHub.astro` / `TerminalInstaller.astro`, `DmgCard.astro`, `PrivacyManifesto.astro`, `GatekeeperGuide.astro`).
  - Existing storage schema change: None (static presentation and client-side clipboard script).
  - Screens/flows touched: Web landing page (`web/src/pages/index.astro`), section `#download`.
  - User roles affected: 1 (Prospective user downloading, verifying, or installing FlowSnap on macOS).
  - Cross-cutting impact: Visual consistency with Apple HIG & Shadcn design tokens (`web/DESIGN.md`), 1-click clipboard API accessibility with visual feedback, zero telemetry / offline privacy clarity, transparent Gatekeeper troubleshooting (`xattr -cr`).
  - Estimated code lines changed: ~400–600 lines.
  - Reversible without user impact: Yes (isolated web presentation layer).
- **Protocol selected**: Bounded Task (Stages 1 → 2 (interactive interview) → 4 (light) → 5 (light) → 6 (user stories) → 7 → 8; Stage 3 gap-analysis skipped).
- **Override**: None (matches Roadmap Effort: M).
- **Depends-on**: `US-WEB-027` ✅
- **Blocks**: `US-WEB-029` (SEO, OpenGraph, JSON-LD Schema & GitHub Pages CI/CD).

## One-line problem statement

Người dùng truy cập trang web FlowSnap cần một trung tâm phân phối cài đặt (Distribution Hub) trực quan, cho phép sao chép lệnh cài đặt Terminal 1 dòng bằng 1 click hoặc tải trực tiếp file `.dmg`, đồng thời được giải tỏa mọi lo ngại bảo mật thông qua bản tuyên ngôn quyền riêng tư (100% Offline, Zero Telemetry, giải thích quyền Accessibility `AXUIElement`) và hướng dẫn xử lý cảnh báo macOS Gatekeeper minh bạch.
