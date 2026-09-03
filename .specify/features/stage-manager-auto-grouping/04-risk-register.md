# 04 — Risk Register & Scope Lock: stage-manager-auto-grouping (US-WORK-018)

## 1. Risk Register

| Risk ID          | Description                                                                                                     | Severity | Likelihood | Mitigation Strategy                                                                                                                                                                                    |
| :--------------- | :-------------------------------------------------------------------------------------------------------------- | :------- | :--------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-SMA-001** | Lệnh `kAXRaiseAction` thất bại trên một số ứng dụng đặc thù (như cửa sổ dạng utility, app bảo mật cao).         | Medium   | Low        | Triển khai theo nguyên tắc Best-Effort: nếu `raise` trả về lỗi hoặc không hỗ trợ, vẫn duy trì vị trí `setFrame`, unhide app và tiếp tục quy trình cho các app còn lại, không làm dừng cả pass restore. |
| **RISK-SMA-002** | Xung đột thời gian (Timing Race Condition) giữa hoạt ảnh di chuyển cửa sổ và cơ chế gom nhóm của WindowManager. | Medium   | Low        | Thực hiện tuần tự: `setFrame` hoàn tất trước khi gọi `kAXRaiseAction`. Cửa sổ đã nằm đúng tọa độ khi xuất hiện trên Stage sẽ không bị giật hay nảy vị trí.                                             |
| **RISK-SMA-003** | Quyền đọc `com.apple.WindowManager` bị chặn trên một số phiên bản macOS hoặc khi sandbox thay đổi.              | Low      | Low        | Sử dụng `CFPreferencesCopyAppValue` là public CoreFoundation C-API chuẩn, có fallback về `UserDefaults(suiteName:)` và giá trị mặc định an toàn là `false` (Standard Restore).                         |

---

## 2. Consolidated Assumptions (`ASM-`)

- **ASM-SMA-001**: Anchor-App Activation + AXRaise Chaining: Chỉ kích hoạt `app.activate()` cho ứng dụng chính đầu tiên, các ứng dụng phụ trợ được nâng lên bằng `kAXRaiseAction` mà không gọi `app.activate()`.
- **ASM-SMA-002**: Primary Window Focus Lock: Đảm bảo cửa sổ chính của Anchor App nhận tiêu điểm bàn phím cuối cùng sau khi hoàn tất toàn bộ quá trình gom nhóm.
- **ASM-SMA-003**: Dynamic Detection: Đọc trực tiếp `com.apple.WindowManager GloballyEnabled` ở mỗi lượt restore, tự động fallback nếu Stage Manager tắt.

---

## 3. MoSCoW Scope Lock

### Must-Have

- [x] Protocol `StageManagerDetecting` và class triển khai `StageManagerDetector` đọc `com.apple.WindowManager GloballyEnabled`.
- [x] Phương thức `raise(element:)` và `raise(window:)` trong `AccessibilityServing` / `AXAccessibilityService` thực thi `kAXRaiseAction`.
- [x] Cập nhật `WorkspaceManager+Restore.swift`: kiểm tra Stage Manager và áp dụng Smart Stage Coordination (chỉ reveal app đầu tiên, gọi raise cho các app sau).
- [x] Giữ tiêu điểm (focus) cho cửa sổ chính của Anchor App sau khi restore xong.
- [x] Bộ unit test kiểm thử toàn diện với MockStageManagerDetector (test cả 2 trường hợp Stage Manager ON và OFF).

### Should-Have

- [x] Đăng ký `StageManagerDetecting` vào `AppDependencies` để hỗ trợ Dependency Injection chuẩn mực.

### Won't-Have (Strictly Out of Scope)

- ❌ Tuyệt đối không sử dụng bất kỳ Private CGS / SLS APIs nào.
- ❌ Không can thiệp hoặc tái định vị dải thumbnail (Stage strip) của macOS.
- ❌ Không giả lập thao tác chuột kéo thả từ Stage strip vào màn hình chính.
