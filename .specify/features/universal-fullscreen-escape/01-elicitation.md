# 01 — Elicitation Record (Stage 2) — universal-fullscreen-escape

> Interview conducted on 2026-09-03 via interactive interview gate for US-WORK-019.
> Confirmed decisions: `ASM-FSE-001`, `ASM-FSE-002`, `ASM-FSE-003`.

## Confirmed Decisions

### ASM-FSE-001 — Three-Tier Fullscreen Escape Sequence

- **Decision**: Thiết kế cơ chế thoát Native Full Screen đa tầng linh hoạt:
  1. **Tier 0 (Fast Attribute Write)**: Thử gán `AXFullscreen = false` và `AXFullScreen = false` vào window qua `AXUIElementSetAttributeValue`. Nếu trả về `kAXErrorSuccess`, hoàn tất tức thì (< 1ms) cho các ứng dụng macOS Cocoa truyền thống (Finder, Safari, TextEdit, Terminal).
  2. **Tier 1 (AX FullScreen Button Press)**: Nếu Tier 0 trả về `kAXErrorCannotComplete` hoặc thất bại (đặc trưng của Electron / Chromium như VS Code, Brave, Slack, Antigravity):
     - Truy vấn nút Fullscreen / Zoom qua `kAXFullScreenButtonAttribute` trên window element (hoặc fallback tìm button có subrole `kAXFullScreenButtonSubrole` / `kAXZoomButtonSubrole`).
     - Thực thi hành động bấm nút qua `AXUIElementPerformAction(button, kAXPressAction as CFString)`.
  3. **Tier 2 (Synthesized `⌃⌘F` via CGEvent)**: Nếu không tìm thấy nút hoặc bấm nút không phản hồi:
     - Gửi tổ hợp phím tắt chuẩn của macOS `Control + Command + F` trực tiếp tới PID của tiến trình sở hữu cửa sổ bằng `CGEvent`.
- **Rationale**: Tối ưu tốc độ tối đa cho ứng dụng native (không tốn thời gian duyệt cây AX hay tổng hợp phím nếu không cần thiết), đồng thời đảm bảo khả năng thoát Full Screen 100% đối với các ứng dụng bên thứ ba và Electron không cho phép can thiệp ghi thuộc tính trực tiếp.

### ASM-FSE-002 — Target App Activation Prior to CGEvent Dispatch

- **Decision**: Khi phải kích hoạt Tier 2 (gửi `⌃⌘F` qua `CGEvent`):
  - Kích hoạt ứng dụng mục tiêu lên foreground thông qua `NSRunningApplication.activate(options: [.activateIgnoringOtherApps])`.
  - Tạo `CGEvent` key-down và key-up cho phím `F` (virtual key code `0x03` / `kVK_ANSI_F`) kèm cờ flags `[.maskControl, .maskCommand]`.
  - Điều phối sự kiện phím bằng `CGEvent.postToPid(pid)`.
- **Rationale**: macOS WindowServer thường bỏ qua hoặc không dispatch các sự kiện tổ hợp phím có modifier keys (`⌃`, `⌘`) nếu ứng dụng nhận đang ở background. Kích hoạt ứng dụng đảm bảo WindowServer chuyển tiếp tổ hợp phím thoát Fullscreen chính xác 100%.

### ASM-FSE-003 — Adaptive Transition Polling with 800ms Ceiling

- **Decision**: Cơ chế chờ và xác nhận thoát Full Screen sau khi gửi tín hiệu thoát:
  - Thay vì ngủ cứng cố định 700ms, FlowSnap sử dụng vòng lặp thăm dò thích ứng (adaptive polling loop):
    - Chu kỳ kiểm tra: mỗi 100ms.
    - Thời gian chờ tối đa (ceiling): 800ms.
    - Điều kiện thoát sớm (early return): Kiểm tra xem cửa sổ đã chuyển khỏi trạng thái Fullscreen (hoặc frame không còn trùng khít với `screen.frame` toàn phần, hoặc `checkFullScreen` trả về `false`).
    - Nếu phát hiện cửa sổ đã về Space bình thường tại mốc 300ms–400ms, FlowSnap tiếp tục ngay bước `setFrame` mà không lãng phí thêm thời gian chờ.
    - Nếu hết 800ms mà trạng thái chưa đổi (do máy chậm hoặc animation kéo dài), FlowSnap vẫn tiếp tục với best-effort để không treo chuỗi xử lý.
- **Rationale**: Cải thiện đáng kể độ trễ phản hồi của hệ thống, đặc biệt trên các máy Mac Apple Silicon đời mới nơi animation thoát Space chỉ mất khoảng 350ms–400ms.

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Public APIs Only**: Tuyệt đối không sử dụng private APIs (như `CGSSetWindowSpaces`). Toàn bộ cơ chế dựa trên `AXUIElement` và `CGEvent`.
- **Integration Points**: Tích hợp trực tiếp vào `AXAccessibilityService.exitFullScreen` (hoặc mở rộng signature với `window: ManagedWindow` / `pid: pid_t`), `WindowManager.move`, và `WorkspaceManager+Restore`.
- **Swift 6 Concurrency**: Toàn bộ logic chạy an toàn với async/await, actor isolation `@MainActor`, Sendable types.
