# 04 — Risk Register & Contradiction Scan: workspace-cross-display-migration (US-DISP-017)

## 1. Analytical Contradiction & Compatibility Scan

| Aspect                            | Evaluation                                                                                                     | Result                                                                                                                                                                                    |
| :-------------------------------- | :------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Stage Manager Auto-Grouping**   | Liệu việc di chuyển nhiều cửa sổ cùng lúc có kích hoạt `app.activate()` làm rã Stage trên màn hình đích không? | **Tương thích hoàn toàn:** `WorkspaceMigrator` tái sử dụng `SmartStageCoordination` (kết hợp `kAXRaiseAction` và Staggered IPC delay 40ms) như đã chuẩn hóa ở US-WORK-018.                |
| **Adaptive Divider Coordination** | Khi Workspace di chuyển sang màn hình mới, dải phân cách có bị kẹt lại ở màn hình cũ không?                    | **Tương thích hoàn toàn:** `AdaptiveDividerCoordinator` có phương thức cập nhật `activeDisplay` hoặc reset lại overlays, chuyển dải phân cách sang màn hình đích và hủy ở màn hình nguồn. |
| **Hotkeys Registration**          | Phím tắt `⌃⌥⇧⌘→` / `⌃⌥⇧⌘←` có bị xung đột với phím tắt hệ thống macOS không?                                   | **Không xung đột:** Tổ hợp 4 phím bổ trợ (`Control + Option + Shift + Command`) là tổ hợp đặc quyền (hyper-chord) ít khi bị macOS chiếm dụng.                                             |
| **Single-Monitor Setup**          | Khi người dùng chỉ có 1 màn hình duy nhất (MacBook standalone)?                                                | **An toàn:** Bắt sớm điều kiện `displays.count <= 1`, trả về `.noOp(.singleDisplay)` êm dịu, không giật màn hình.                                                                         |

---

## 2. Risk Register (`RISK-MIG-###`)

| ID             | Risk Description                                                                                                                                                                            | Severity | Likelihood | Mitigation Strategy                                                                                                                                    |
| :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | :------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RISK-MIG-001` | **WindowServer Clamping Collision**: Di chuyển cửa sổ lớn sang màn hình đích có độ phân giải nhỏ hơn có thể bị WindowServer tự động ép kích thước (clamping), làm mất tỉ lệ layout ban đầu. | Medium   | Medium     | Sử dụng `RelativeFrameScaler` kết hợp `FrameClampingHelper.clamp(..., minVisibilityRatio: 1.0)` và 2-phase move ordering (thu nhỏ trước, mở rộng sau). |
| `RISK-MIG-002` | **Stage Manager Strip Ejection**: Khi di chuyển nhanh, macOS WindowManager có thể đưa cửa sổ phụ vào dải Stage Manager thumbnail nếu chuyển đổi không có độ trễ hợp lý.                     | High     | Medium     | Áp dụng Staggered delay 40ms giữa các cửa sổ và kích hoạt `kAXRaiseAction` trên cửa sổ phụ thay vì `app.activate()`.                                   |
| `RISK-MIG-003` | **Cursor Warping Failure / Accessibility Permission**: Người dùng chưa cấp quyền trợ năng hoặc CoreGraphics không thể warp chuột.                                                           | Low      | Low        | Kiểm tra `accessibilityService.isTrusted`; warp chuột qua `CursorWarping` bọc trong try/catch an toàn.                                                 |

---

## 3. MoSCoW Scope Lock

- **Must-Have (P0)**:
  - Phím tắt toàn cục mặc định `⌃⌥⇧⌘→` và `⌃⌥⇧⌘←` di chuyển Workspace sang Next/Previous display.
  - Tự động phát hiện active workspace trên display hiện tại của focused window/cursor.
  - Ánh xạ tọa độ đa cửa sổ qua `RelativeFrameScaler`.
  - 2-Phase move ordering (khi Stage Manager tắt) và Staggered IPC + `kAXRaiseAction` (khi Stage Manager bật).
  - Tự động chuyển dải phân cách và warp chuột tới tâm primary window trên màn hình đích.
  - Safe no-op khi có 1 display hoặc không có workspace active.
- **Should-Have (P1)**:
  - Menu item "Move Workspace to Next Display" / "Move Workspace to Previous Display" trong Menu Bar Status Item.
  - Cấu hình tùy chỉnh phím tắt trong Preferences Shortcuts.
- **Won't-Have (v1.0 Out of Scope)**:
  - Animation kéo trượt trực quan cửa sổ bay qua không gian giữa 2 màn hình (macOS WindowServer không hỗ trợ mượt mà qua Accessibility API).
  - Tự động thay đổi thứ tự cửa sổ trong layout khi di chuyển.
