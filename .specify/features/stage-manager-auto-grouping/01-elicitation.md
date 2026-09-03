# 01 — Elicitation Record (Stage 2) — stage-manager-auto-grouping

> Interview conducted on 2026-09-03 via interactive interview gate for US-WORK-017.
> Confirmed decisions: `ASM-SMA-001`, `ASM-SMA-002`, `ASM-SMA-003`.

## Confirmed Decisions

### ASM-SMA-001 — Anchor-App Activation + AXRaise Chaining

- **Decision**: Khi Stage Manager đang BẬT (`GloballyEnabled = 1`), FlowSnap áp dụng cơ chế điều phối sân khấu thông minh (**Smart Stage Coordination**):
  1. Chỉ gọi `app.activate(options: [.activateAllWindows])` hoặc `launcher.reveal()` cho ứng dụng chính đầu tiên (**Primary Anchor App** - ứng dụng có diện tích lớn nhất hoặc placement đầu tiên trong Workspace). Hành động này kéo Anchor App lên trung tâm Stage hiện hành.
  2. Đối với các ứng dụng tiếp theo trong danh sách placements (**Secondary Apps**):
     - Unhide nếu app đang bị ẩn (`app.unhide()`).
     - Định vị cửa sổ vào frame tương ứng thông qua `WindowManager.move()`.
     - Tuyệt đối **KHÔNG** gọi `app.activate()`. Thay vào đó, gửi trực tiếp hành động nâng cửa sổ `kAXRaiseAction` lên từng window AXUIElement (`AXUIElementPerformAction(element, kAXRaiseAction as CFString)`).
     - Hành động `kAXRaiseAction` đưa cửa sổ lên mặt phẳng hiển thị của Stage hiện tại mà không kích hoạt logic hoán đổi sân khấu (Stage swap) của macOS WindowManager.
- **Rationale**: Ngăn chặn triệt để hiện tượng macOS đẩy các app đã restore trước đó về dải thumbnail bên cạnh (Stage strip), đảm bảo tất cả 2–3 cửa sổ của Workspace hiển thị đồng thời trên một Stage duy nhất.

### ASM-SMA-002 — Primary Window Focus on Restore Completion

- **Decision**: Sau khi toàn bộ các cửa sổ trong Workspace đã được di chuyển và nâng lên Stage thành công:
  - FlowSnap thực hiện một lượt kích hoạt tiêu điểm cuối cùng dành cho **Primary Window** (cửa sổ chính của Anchor App, ví dụ IDE hoặc Document Editor).
  - Sử dụng `kAXRaiseAction` hoặc `NSRunningApplication.activate` có kiểm soát để đưa Primary Window trở thành cửa sổ nhận keyboard focus chính thức.
- **Rationale**: Người dùng mong muốn sau khi bấm Restore có thể bắt đầu gõ phím ngay trong ứng dụng chính (như tiếp tục viết code trong VS Code) mà không cần phải dùng chuột click chọn lại.

### ASM-SMA-003 — Dynamic Detection of Stage Manager State

- **Decision**: FlowSnap phát hiện trạng thái Stage Manager theo cơ chế động thời gian thực (**Dynamic Detection on Each Restore Pass**):
  - Khởi tạo protocol `StageManagerDetecting` và implementation `StageManagerDetector`.
  - Đọc trực tiếp thiết lập `GloballyEnabled` từ preference domain `com.apple.WindowManager` (sử dụng `CFPreferencesGetAppBooleanValue` hoặc `UserDefaults(suiteName: "com.apple.WindowManager")`).
  - Thực hiện kiểm tra ở mỗi lượt Restore:
    - Nếu `isStageManagerEnabled == true`: Kích hoạt nhánh xử lý `restoreWithStageManager`.
    - Nếu `isStageManagerEnabled == false`: Tự động sử dụng luồng restore tiêu chuẩn (`app.activate()` cho từng app như trước).
  - Tích hợp fallback an toàn: Nếu không đọc được preference do quyền hạn hoặc lỗi hệ thống, mặc định coi là `false` để duy trì tương thích.
- **Rationale**: Cho phép ứng dụng tự thích ứng ngay lập tức khi người dùng bật/tắt Stage Manager trong macOS Control Center mà không cần khởi động lại FlowSnap, đồng thời không gây overhead do đọc CFPreferences cực nhanh (< 1ms).

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Zero Private APIs**: Tuyệt đối không dùng các private CGS APIs (như `CGSSetWindowSpaces` hay `SLSSetWindowListProperties`). Chỉ sử dụng public preferences và `kAXRaiseAction`.
- **Integration Points**:
  - `Domain/`: `StageManagerDetecting` protocol.
  - `Infrastructure/`: `StageManagerDetector.swift`, mở rộng `AccessibilityServing` / `AXAccessibilityService` hỗ trợ `raise(element:)`.
  - `Core/`: Nhánh điều phối `restoreStageManagerWorkspace` trong `WorkspaceManager+Restore.swift`.
- **Swift 6 Strict Concurrency**: Toàn bộ các class/actor tuân thủ 100% `Sendable` và `@MainActor`.
