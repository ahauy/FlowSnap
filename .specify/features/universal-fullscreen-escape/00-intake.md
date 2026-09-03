# Intake: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-018)

- **Date**: 2026-09-03
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — Sprint 5)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: 0 (Refines `exitFullScreen` in `AccessibilityServing` and `WindowManager`)
  - Existing storage schema change: None
  - Screens/flows touched: 2 (`WindowManager.move`, `WorkspaceManager+Restore`)
  - User roles affected: 1 (macOS Desktop Power User with mixed Electron & Native Cocoa apps in fullscreen)
  - Cross-cutting impact: Accessibility API interactions, CGEvent keyboard synthesis, animation wait timing, window space recovery
  - Estimated code lines changed: 100–200 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 interactive interview → 4 light → 5 light → 6 user stories → 7 → 8)
- **Override**: Matches roadmap Effort: M.
- **Blocks**: `US-WORK-017` (Stage Manager Multi-Window Auto-Grouping)

## One-line problem statement

Lệnh gán thuộc tính `AXFullscreen = false` truyền thống bị lỗi `cannotComplete` trên các ứng dụng Electron/Chromium (VS Code, Brave, Slack, Antigravity) khiến FlowSnap không thể thoát Full Screen để khôi phục Workspace; cần cơ chế thoát Full Screen đa tầng đáng tin cậy 100% kết hợp nhấn nút Fullscreen qua AX và fallback phím tắt hệ thống `⌃⌘F` qua CGEvent.
