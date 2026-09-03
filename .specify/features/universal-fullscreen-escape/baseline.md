# Domain Decision Baseline: Universal Fullscreen Escape for Electron/Native Apps (US-WORK-019)

**Status**: SIGNED-OFF v1.0  
**Version**: 1.0.0  
**Story ID**: `US-WORK-019`  
**Feature Slug**: `universal-fullscreen-escape`  
**Date**: 2026-09-03

---

## Executive Summary

US-WORK-019 nâng cấp toàn diện năng lực thoát chế độ Toàn màn hình (macOS Native Full Screen / Separate Spaces) của FlowSnap:

1. **Chuỗi thoát 3 tầng (Three-Tier Escape)**:
   - **Tier 0**: Ghi thuộc tính nhanh `AXFullscreen = false` (< 1ms cho Cocoa Native).
   - **Tier 1**: Bấm nút Fullscreen trực tiếp qua Accessibility (`kAXFullScreenButtonAttribute` + `kAXPressAction`), giải quyết triệt để lỗi `cannotComplete` trên các ứng dụng Electron/Chromium (VS Code, Brave, Slack, Antigravity).
   - **Tier 2**: Tự động kích hoạt foreground và gửi phím tắt `⌃⌘F` qua `CGEvent` tới PID đích nếu ứng dụng tùy biến không có nút chuẩn.
2. **Thăm dò thích ứng (Adaptive Polling)**:
   - Kiểm tra trạng thái cửa sổ mỗi 100ms với trần 800ms; kết thúc sớm khi cửa sổ vừa rời khỏi Fullscreen Space, tiết kiệm 300–400ms so với chờ cố định.
3. **Phục hồi an toàn (Non-Destructive)**:
   - Thất bại không gây crash hay dừng pass restore workspace; tiến hành di chuyển cửa sổ best-effort.

---

## 1. Traceability & Decision Matrix

- **Intake**: [00-intake.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/universal-fullscreen-escape/00-intake.md) (Bounded Task, Effort: M).
- **Tech Context**: [00-tech-context.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/universal-fullscreen-escape/00-tech-context.md).
- **Elicitation Decisions**: [01-elicitation.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/universal-fullscreen-escape/01-elicitation.md) (`ASM-FSE-001`, `ASM-FSE-002`, `ASM-FSE-003`).
- **Domain Model & State Machine**: [03-domain-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/universal-fullscreen-escape/03-domain-model.md) (`BR-FSE-001`..`004`).
- **Risk Register & MoSCoW**: [04-risk-register.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/universal-fullscreen-escape/04-risk-register.md).
- **User Stories & Scenarios**: [05-user-stories.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/universal-fullscreen-escape/05-user-stories.md).
- **Architectural Decision Record**: [adr/0012-universal-fullscreen-escape.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0012-universal-fullscreen-escape.md).

---

## 2. Handover Brief for Technical Planning (Phase 2)

- **Input Artifacts**: `03-domain-model.md`, `05-user-stories.md`, `adr/0012-universal-fullscreen-escape.md`.
- **Target Components**:
  - `Domain/Window/`: `FullScreenEscapeTier.swift`, `FullScreenEscapeResult.swift`.
  - `Infrastructure/Accessibility/`: `FullScreenEscapeCoordinator.swift`, `AXAccessibilityService.swift` (tích hợp `FullScreenEscapeCoordinating`).
  - `Core/Window/`: `WindowManager.swift` (thay thế sleep 700ms cứng bằng adaptive escape).
  - `Core/Workspace/`: `WorkspaceManager+Restore.swift`.
  - `Tests/`: `FullScreenEscapeCoordinatorTests.swift`, `AXAccessibilityServiceTests.swift`.
- **Handover Acceptance Sign-Off**: Ready for `speckit-plan` and task decomposition.
