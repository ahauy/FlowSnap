# 04 — Risk Register & Scope Lock — universal-fullscreen-escape

## Consolidated Assumptions

- **`ASM-FSE-001`**: Three-tier escape sequence (Tier 0: Fast attribute write -> Tier 1: AX button press -> Tier 2: CGEvent `⌃⌘F` fallback).
- **`ASM-FSE-002`**: Foreground activation of target application prior to `CGEvent` dispatch to prevent WindowServer key event drops.
- **`ASM-FSE-003`**: Adaptive transition polling every 100ms up to 800ms maximum ceiling with early exit upon state change.

---

## Risk Register

| Risk ID            | Description                                                                       | Severity | Likelihood | Mitigation Strategy                                                                                                                                                  |
| :----------------- | :-------------------------------------------------------------------------------- | :------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`RISK-FSE-001`** | Ứng dụng tùy biến lại phím tắt khiến `⌃⌘F` không còn là lệnh thoát Full Screen    | Medium   | Low        | Luôn ưu tiên Tier 0 và Tier 1 (bấm nút vật lý qua AX) trước khi fallback sang Tier 2; phím tắt chỉ là cứu cánh cuối cùng.                                            |
| **`RISK-FSE-002`** | Kích hoạt foreground ứng dụng ở Tier 2 làm thay đổi tiêu điểm ứng dụng người dùng | Low      | Medium     | Trong kịch bản Restore Workspace, `WorkspaceManager+Restore` đã có bước `launcher.reveal()` cuối cùng để đưa đúng app làm việc chính lên trên cùng sau khi hoàn tất. |
| **`RISK-FSE-003`** | Độ trễ thoát Space trên máy đời cũ vượt quá 800ms                                 | Low      | Low        | Áp dụng best-effort sau 800ms; `WindowManager` đã có cơ chế Tiered Backoff Retry 3 lần cho `setFrame`.                                                               |

---

## MoSCoW Scope Lock

### Must-Have

- [x] Cơ chế thoát Full Screen 3 tầng: Fast Attribute Write -> AX FullScreen Button Press -> CGEvent `⌃⌘F`.
- [x] Kích hoạt foreground tiến trình đích trước khi post `CGEvent`.
- [x] Vòng lặp thăm dò thích ứng (adaptive polling) mỗi 100ms với trần 800ms và thoát sớm ngay khi cửa sổ rời trạng thái Full Screen.
- [x] Tích hợp mượt mà vào `AXAccessibilityService.exitFullScreen`, `WindowManager.move`, và `WorkspaceManager+Restore`.
- [x] Unit test kiểm thử đầy đủ 3 tầng thoát với mock service.

### Won't-Have (Out of Scope for this feature)

- ❌ Can thiệp private APIs (`CGSSetWindowSpaces`, `SLSGetWindowSpaces`).
- ❌ Inject code/dylib vào tiến trình của ứng dụng bên thứ ba.
- ❌ Thay đổi phím tắt hệ thống của macOS trong System Settings.
