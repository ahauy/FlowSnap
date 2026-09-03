# Intake: Atomic Workspace Cross-Display Migration (US-DISP-017)

- **Date**: 2026-09-04
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — EPIC 13)
- **Classification**: Bounded Task (Effort: M, Context-budget: single-session)
- **Classification signals**:
  - New/changed domain entities: 1-2 (`WorkspaceMigrationService` / `WorkspaceManager+Migration.swift`)
  - Existing storage schema change: None (reuses existing `Workspace` & `WindowPlacement` models)
  - Screens/flows touched: `WorkspaceManager.swift`, `AdaptiveDividerCoordinator.swift`, `GlobalHotkeyManager.swift`, `MenuBarViewModel.swift`
  - User roles affected: 1 (macOS Desktop Power User with multi-monitor workstation)
  - Cross-cutting impact: Cross-display coordinate mapping (`RelativeFrameScaler`), 2-phase move ordering & IPC staggering (Stage Manager cohesion), mouse warping & divider repositioning.
  - Estimated code lines changed: 200–350 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Bounded Task (Stages 1 → 2 [interactive interview] → 4 → 5 → 6 → 7 → 8; Stage 3 skipped)
- **Override**: None
- **Depends-on**: `US-DISP-015` ✅, `US-WORK-011` ✅, `US-WORK-018` ✅
- **Blocks**: _(none)_

## One-line problem statement

Người dùng đa màn hình cần di chuyển nguyên vẹn toàn bộ một Workspace (gồm 2–3 cửa sổ đang được chia tỉ lệ cạnh nhau) từ màn hình hiện tại sang màn hình kế tiếp hoặc chỉ định bằng phím tắt toàn cục (`⌃⌥⇧⌘→` / `⌃⌥⇧⌘←`) hoặc Menu Bar, bảo toàn tuyệt đối tỉ lệ tương đối giữa các cửa sổ, không làm rã nhóm Stage Manager, đồng thời tự động chuyển tiêu điểm chuột và dải phân cách (`AdaptiveDividerCoordinator`) sang màn hình đích.
