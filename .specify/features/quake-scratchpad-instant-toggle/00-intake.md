# Intake: Quake-Style Quick Scratchpad & Instant Window Toggle (US-SNAP-022)

- **Date**: 2026-09-04
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 15, US-SNAP-022)
- **Classification**: Bounded Task (Effort: M, Context-budget: multi-session)
- **Classification signals**:
  - New/changed domain entities: 1 (`ScratchpadCoordinating`, `ScratchpadState`, `ScratchpadRecord`)
  - Existing storage schema change: Additive (`PreferencesStore` keys for scratchpad toggle hotkey, assign hotkey, dismissOnBlur, dismissOnEsc)
  - Screens/flows touched: 3 (`ScratchpadCoordinator`, `GlobalHotkeyManager`, `MenuBarView` / `MenuBarViewModel`, `SettingsView`)
  - User roles affected: 1 (macOS Desktop Power User wanting instant temporary access to a reference/utility window without resizing the main application)
  - Cross-cutting impact: Pre-summon focus preservation and restoration, event monitoring for click-outside / ESC, instant activation and hiding via AXUIElement / NSRunningApplication
  - Estimated code lines changed: 250–400 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 → 4 → 5 → 6 → 7 → 8; Stage 3 gap-analysis skipped)
- **Override**: None
- **Depends-on**: `US-SNAP-021` ✅
- **Blocks**: _(none)_

## One-line problem statement

Người dùng làm việc toàn màn hình hoặc chia khung trên macOS cần một cơ chế triệu hồi và giấu tức thì một cửa sổ phụ trợ (terminal, ghi chú, máy tính, từ điển,...) bằng phím tắt toàn cục (`⌥Space` hoặc tùy biến) mà không làm co nhỏ hay dịch chuyển ứng dụng đang làm việc nền (zero-shrink preservation), hỗ trợ tự động ẩn khi nhấn ESC hoặc click ra ngoài, và hoàn trả tiêu điểm chính xác về ứng dụng trước đó trong < 50ms.
