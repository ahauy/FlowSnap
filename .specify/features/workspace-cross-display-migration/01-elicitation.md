# Domain Elicitation: Atomic Workspace Cross-Display Migration (US-DISP-017)

- **Feature**: `workspace-cross-display-migration`
- **Story ID**: `US-DISP-017`
- **Date**: 2026-09-04
- **Stakeholder**: User (macOS Power User)

---

## 1. Confirmed Requirements & Domain Decisions

### Q1: Target Workspace Resolution

- **Decision**: Khi người dùng kích hoạt hotkey (`⌃⌥⇧⌘→` / `⌃⌥⇧⌘←`) hoặc Menu Bar action:
  - Xác định màn hình nguồn (`sourceDisplay`) dựa trên vị trí của cửa sổ đang có tiêu điểm (focused window) hoặc vị trí con trỏ chuột hiện tại.
  - Tìm Workspace đang active trên màn hình nguồn này (`activeWorkspace`).
  - Nếu không có Workspace nào active trên màn hình đó (hoặc hệ thống chỉ có 1 màn hình duy nhất), hệ thống thực hiện no-op êm dịu (graceful no-op), tuyệt đối không giật rung màn hình hay phát sinh lỗi ngoại lệ.
- **Trace ID**: `ASM-MIG-001`, `BR-MIG-001`

### Q2: Move Ordering & IPC Staggering Strategy

- **Decision**: Áp dụng cơ chế thích ứng theo trạng thái Stage Manager:
  - **Khi Stage Manager BẬT (`GloballyEnabled == true`)**:
    - Xác định cửa sổ Anchor (cửa sổ đầu tiên của Workspace).
    - Di chuyển cửa sổ Anchor sang màn hình đích trước.
    - Áp dụng độ trễ IPC Stagger (30–50ms) giữa các lần di chuyển cửa sổ kế tiếp.
    - Gọi `kAXRaiseAction` trên các cửa sổ phụ để đưa lên cùng mặt phẳng hiển thị mà không kích hoạt `app.activate()`, giữ vững liên kết nhóm trên cùng một Sân khấu (Stage) duy nhất.
  - **Khi Stage Manager TẮT (`GloballyEnabled == false`)**:
    - Áp dụng thứ tự di chuyển 2 pha: Các cửa sổ có kích thước thu nhỏ được di chuyển trước, sau đó tới các cửa sổ mở rộng (shrink before expand).
    - Thực thi với độ trễ tối thiểu để chuyển màn hình tức thì, ngăn ngừa hiện tượng va chạm khung hình hoặc clamping sai lệch của WindowServer.
- **Trace ID**: `ASM-MIG-002`, `BR-MIG-002`

### Q3: Mouse Warping & Adaptive Divider Coordination

- **Decision**: Sau khi tất cả các cửa sổ trong Workspace đã hoàn tất di chuyển sang màn hình đích:
  - Tự động di chuyển con trỏ chuột (warp cursor via `CursorWarping`) đến tâm của cửa sổ chính (primary window) trên màn hình đích.
  - Tái thiết lập và điều phối dải phân cách (`AdaptiveDividerCoordinator`) trên màn hình đích tương ứng với các cửa sổ vừa di chuyển, đồng thời hủy bỏ hoàn toàn dải phân cách trên màn hình nguồn.
  - Giữ vững tiêu điểm bàn phím trên cửa sổ chính của Workspace.
- **Trace ID**: `ASM-MIG-003`, `BR-MIG-003`

---

## 2. Explicit Assumptions & Constraints Register

| ID            | Category             | Summary                                                                                                   | Resolution / Impact              |
| :------------ | :------------------- | :-------------------------------------------------------------------------------------------------------- | :------------------------------- |
| `ASM-MIG-001` | Workspace Resolution | Xác định workspace active theo display của focused window hoặc mouse cursor                               | Đã xác nhận qua phỏng vấn        |
| `ASM-MIG-002` | IPC & Ordering       | 2-phase move ordering khi Stage Manager tắt; anchor + 40ms stagger + kAXRaiseAction khi Stage Manager bật | Đã xác nhận qua phỏng vấn        |
| `ASM-MIG-003` | Post-Move Handoff    | Warp mouse cursor tới tâm cửa sổ chính trên target display và chuyển dải phân cách                        | Đã xác nhận qua phỏng vấn        |
| `ASM-MIG-004` | Coordinate Math      | Sử dụng `RelativeFrameScaler` để ánh xạ từ `sourceDisplay.visibleFrame` sang `targetDisplay.visibleFrame` | Kế thừa từ US-DISP-015           |
| `ASM-MIG-005` | Hotkey Defaults      | Mặc định `⌃⌥⇧⌘→` (Next Display) và `⌃⌥⇧⌘←` (Previous Display), có thể tùy chỉnh trong Settings            | Kế thừa từ US-DISP-015 & roadmap |
