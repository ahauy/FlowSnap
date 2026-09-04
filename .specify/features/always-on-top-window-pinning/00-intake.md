# Intake: Universal Always-On-Top Pinning & Stage Manager Launch Co-existence (US-SNAP-021)

- **Date**: 2026-09-04
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 15)
- **Classification**: Full Feature (Effort: L, Context-budget: multi-session)
- **Classification signals**:
  - New/changed domain entities: 2+ (`WindowPinningCoordinating`, `PinnedWindowRecord`, `StageManagerLaunchCoordinating`)
  - Existing storage schema change: Additive (`PreferencesStore` keys for Pinning Hotkey, Pin Indicator Badge style, and Stage Manager Launch Co-existence toggle)
  - Screens/flows touched: 2+ (`WindowPinningCoordinator`, `StageManagerLaunchCoordinator`, `GlobalHotkeyManager`, `MenuBarView` / `MenuBarViewModel`, `SettingsView`)
  - User roles affected: 1 (macOS Desktop Power User with multi-window & Stage Manager workflow)
  - Cross-cutting impact: Window Z-Order management via AXUIElement, Focus change observation, Stage Manager launch interception via NSWorkspace & AXObserver, Global Hotkeys (`⌃⌥P`), Menu Bar status indicators
  - Estimated code lines changed: 300–500 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Full Feature (Stages 1 → 8 with interactive elicitation interview at Stage 2)
- **Override**: None
- **Depends-on**: `US-WORK-014` ✅, `US-WORK-018` ✅
- **Blocks**: _(none)_

## One-line problem statement

Người dùng macOS cần khả năng ghim nổi bất kỳ cửa sổ nào luôn trên cùng (Always-on-Top) bằng phím tắt toàn cục (`⌃⌥P`) với cơ chế xếp lớp động LIFO Z-Stacking trên nền tảng Public API (Zero Private API), đồng thời hòa hợp tuyệt đối với Stage Manager khi mở ứng dụng mới (ngăn chặn hành vi mặc định của macOS cô lập ứng dụng mới và đẩy các cửa sổ đang làm việc ra dải cánh gà).
