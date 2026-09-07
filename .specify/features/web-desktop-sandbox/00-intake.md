# Intake: 3D Interactive macOS Desktop Simulator (US-WEB-026)

- **Date**: 2026-09-07
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 16, US-WEB-026)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: 1 interactive simulator component (`DesktopSimulator.astro` or vanilla JS module), mock window state machine (dragging, snapping, snapped zones, top-edge trigger, reset), HUD preview overlay, top-edge layout picker.
  - Existing storage schema change: None (client-side in-memory interaction).
  - Screens/flows touched: Web entrypoint (`web/src/pages/index.astro`), section `#showcase`.
  - User roles affected: 1 (Prospective user testing FlowSnap interactions directly in browser).
  - Cross-cutting impact: Performance budget (< 16ms drag latency, 0.0% idle CPU via `IntersectionObserver`), touch & mobile responsiveness, Apple HIG visual fidelity.
  - Estimated code lines changed: 350–500 lines.
  - Reversible without user impact: Yes (isolated component within `web/`).
- **Protocol selected**: Bounded Task (Stages 1 → 2 (interactive interview) → 4 (light) → 5 (light) → 6 (user stories) → 7 → 8; Stage 3 gap-analysis skipped).
- **Override**: None (matches Roadmap Effort: M).
- **Depends-on**: `US-WEB-025` ✅
- **Blocks**: `US-WEB-027` (Bento Grid), `US-WEB-028` (Distribution Hub), `US-WEB-029` (SEO/CI-CD).

## One-line problem statement

Người dùng truy cập trang web FlowSnap cần một không gian mô phỏng màn hình macOS chân thực và mượt mà ngay trên trình duyệt, cho phép kéo thả thử một cửa sổ ảo để trực tiếp trải nghiệm cơ chế kéo chạm cạnh (Drag-to-Snap), bật thanh Top-Edge Snap Picker khi chạm đỉnh màn hình, xem lớp kính mờ HUD Preview đón trước và cảm nhận triết lý quản lý cửa sổ của FlowSnap trước khi tải ứng dụng.
