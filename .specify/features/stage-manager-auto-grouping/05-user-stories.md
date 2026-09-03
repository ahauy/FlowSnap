# 05 — User Stories & Acceptance Scenarios: stage-manager-auto-grouping (US-WORK-017)

## US-SMA-001: Stage Manager Multi-Window Auto-Grouping on Restore

- **Derived from**: `docs/PRODUCT_BACKLOG_ROADMAP.md` — `US-WORK-017`
- **As a**: macOS Power User using Stage Manager to organize workflow
- **I want**: FlowSnap to automatically group all windows belonging to a restored Workspace onto a single active Stage
- **So that**: macOS does not push my previous apps into the sidebar strip, and I can immediately see and use my split workspace (e.g. 50/50, 60/40) side-by-side.

### Scenario 1: Restore Multi-Window Workspace with Stage Manager ON (Happy Path)

- **Given**: Stage Manager đang được BẬT trên hệ thống (`com.apple.WindowManager GloballyEnabled = 1`).
- **And**: Người dùng kích hoạt lệnh khôi phục Workspace "Coding" gồm 2 ứng dụng: VS Code (Left 60%) và Chrome (Right 40%).
- **When**: `WorkspaceManager.restore(workspace:)` được gọi.
- **Then**: FlowSnap xác định VS Code là Anchor App (vị trí đầu tiên/diện tích lớn nhất), di chuyển về khung 60% bên trái và kích hoạt app qua `launcher.reveal()`.
- **And**: FlowSnap di chuyển Chrome về khung 40% bên phải, gọi `accessibilityService.raise(window:)` qua `kAXRaiseAction` mà **KHÔNG** gọi `app.activate()`.
- **And**: Cả hai cửa sổ cùng hiển thị đồng thời trên một Stage duy nhất tại màn hình làm việc, không cửa sổ nào bị đẩy vào dải Stage Manager strip bên trái.
- **And**: Tiêu điểm bàn phím (Keyboard Focus) được khóa trên cửa sổ chính của VS Code.

### Scenario 2: Restore Multi-Window Workspace with Stage Manager OFF (Backward Compatibility)

- **Given**: Stage Manager đang TẮT trên hệ thống (`GloballyEnabled = 0`).
- **When**: Người dùng khôi phục Workspace "Coding".
- **Then**: `StageManagerDetector` phát hiện Stage Manager không hoạt động.
- **And**: FlowSnap thực hiện luồng khôi phục tiêu chuẩn (gọi `launcher.reveal()` cho từng ứng dụng tuần tự).
- **And**: Cả hai ứng dụng hiển thị bình thường trên màn hình Desktop truyền thống.

### Scenario 3: Restore Workspace with Hidden Secondary App

- **Given**: Stage Manager đang BẬT.
- **And**: Ứng dụng phụ (Chrome) đang ở trạng thái ẩn (`app.isHidden == true`).
- **When**: Khôi phục Workspace.
- **Then**: FlowSnap thực hiện `app.unhide()`, định vị lại kích thước cửa sổ và nâng lên Stage qua `kAXRaiseAction`.
- **And**: Chrome xuất hiện trên cùng Stage với Anchor App mà không gây hoán đổi vị trí của Anchor App.

### Scenario 4: Single-Window Workspace with Stage Manager ON

- **Given**: Stage Manager đang BẬT.
- **When**: Người dùng khôi phục Workspace chỉ chứa 1 ứng dụng (ví dụ: Full Screen Browser).
- **Then**: Ứng dụng duy nhất được định vị và kích hoạt bình thường như một Anchor App.
