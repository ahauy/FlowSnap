# Domain Baseline: Stage Manager Multi-Window Auto-Grouping (US-WORK-018)

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0 (Confirmation Gate 1 Approved)
- **Feature Slug**: `stage-manager-auto-grouping`
- **Related Roadmap Item**: `US-WORK-018` (Epic 14 — Stage Manager Co-existence & Fullscreen Harmony)

---

## 1. Domain Summary

Giải quyết triệt để xung đột cố hữu giữa cơ chế khôi phục đa cửa sổ của FlowSnap và tính năng Stage Manager của macOS (macOS 13+):
Khi Stage Manager đang BẬT (`com.apple.WindowManager GloballyEnabled = 1`), FlowSnap tự động kích hoạt **Smart Stage Coordination**:

1. Kích hoạt và đưa **Anchor App** (ứng dụng chính có diện tích lớn nhất / placement đầu tiên) lên Stage trung tâm bằng `app.activate()`.
2. Định vị và đưa các **Secondary Apps** tiếp theo lên cùng Stage đó bằng hành động `kAXRaiseAction` của Accessibility API (`AXUIElementPerformAction(element, kAXRaiseAction)`), tuyệt đối không gọi `app.activate()`.
3. Khóa tiêu điểm bàn phím (Keyboard Focus) trên cửa sổ của Anchor App để người dùng sẵn sàng làm việc ngay lập tức.
4. Khi Stage Manager TẮT (`GloballyEnabled = 0`), tự động fallback về luồng khôi phục tuần tự truyền thống.

---

## 2. Business Rules Reference

- **BR-SMA-001**: Kiểm tra trạng thái Stage Manager theo thời gian thực (Dynamic Detection via CFPreferences) ở mỗi lượt restore.
- **BR-SMA-002**: Anchor-First Activation — chỉ kích hoạt `app.activate()` cho ứng dụng đầu tiên.
- **BR-SMA-003**: Secondary Window Raising via `kAXRaiseAction` — các app phụ chỉ gọi `raise(element:)`, unhide nếu cần, không gọi `activate()`.
- **BR-SMA-004**: Final Focus Lock — đặt tiêu điểm chính vào cửa sổ của Anchor App khi hoàn tất.
- **BR-SMA-005**: Graceful Fallback — fallback về luồng thường nếu Stage Manager tắt hoặc không đọc được cấu hình.

---

## 3. Assumptions Register

- `ASM-SMA-001`: Anchor-App Activation + AXRaise Chaining.
- `ASM-SMA-002`: Primary Window Focus on Restore Completion.
- `ASM-SMA-003`: Dynamic Detection of Stage Manager via `com.apple.WindowManager`.

---

## 4. Scope (MoSCoW)

- **Must-Have**: `StageManagerDetecting` protocol, `StageManagerDetector` implementation, `raise(element:)` / `raise(window:)` in `AccessibilityServing`, Smart Stage Coordination in `WorkspaceManager+Restore`, Primary window focus lock, comprehensive unit tests.
- **Should-Have**: DI integration in `AppDependencies`.
- **Won't-Have**: Private CGS/SLS APIs, manipulating Stage Manager sidebar strip thumbnails directly.
