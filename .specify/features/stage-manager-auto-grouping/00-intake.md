# Intake: Stage Manager Multi-Window Auto-Grouping on Restore (US-WORK-018)

- **Date**: 2026-09-03
- **Requested by**: Product Backlog Roadmap (`docs/PRODUCT_BACKLOG_ROADMAP.md` — Sprint 5)
- **Classification**: Full Feature (Effort: L, Context-budget: multi-session)
- **Classification signals**:
  - New/changed domain entities: 1-2 (`StageManagerCoordinating`, `StageManagerDetector`)
  - Existing storage schema change: None
  - Screens/flows touched: `WorkspaceManager+Restore.swift`, `AppLauncher.swift`, `AccessibilityServing` / `AXAccessibilityService`
  - User roles affected: 1 (macOS Desktop Power User with Stage Manager enabled)
  - Cross-cutting impact: Stage Manager detection (`com.apple.WindowManager`), window raise semantics (`kAXRaiseAction`), multi-app grouping on single Stage without app ejection, workspace restoration flow
  - Estimated code lines changed: 150–300 lines
  - Reversible without user impact: Yes
- **Protocol selected**: Full Feature (Stages 1 → 8 with interactive elicitation interview at Stage 2)
- **Override**: None
- **Depends-on**: `US-WORK-011` ✅, `US-WORK-014` ✅, `US-WORK-018` ✅
- **Blocks**: _(none)_

## One-line problem statement

Khi khôi phục một Workspace đa cửa sổ (ví dụ: 2-3 app chia 50/50 hoặc 60/40) trong khi Stage Manager đang bật (`GloballyEnabled = 1`), cơ chế kích hoạt app tuần tự `app.activate()` của macOS tự động đẩy các app trước đó ra dải thu nhỏ (sidebar strip), khiến chỉ có app cuối cùng hiển thị trên sân khấu; FlowSnap cần cơ chế điều phối thông minh (Smart Stage Coordination) bằng `kAXRaiseAction` để gom tất cả các app trong Workspace vào cùng một Sân khấu duy nhất.
