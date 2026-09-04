# 01 — Elicitation Record (Stage 2) — quake-scratchpad-instant-toggle

> Interview conducted on 2026-09-04 via interactive interview gate for US-SNAP-022.
> Confirmed decisions: `ASM-SCRATCH-001`, `ASM-SCRATCH-002`, `ASM-SCRATCH-003`.

## Confirmed Decisions

### ASM-SCRATCH-001 — Hybrid Process & Window Dismiss Coordination

- **Decision**: Nhằm giấu nhanh cửa sổ Scratchpad trong < 50ms mà không gây ảnh hưởng tiêu cực tới các ứng dụng đa cửa sổ (ví dụ: Terminal/Chrome/Finder có nhiều tab hoặc cửa sổ phụ):
  1. Khi nhận lệnh ẩn (Dismiss), `ScratchpadCoordinator` kiểm tra số lượng cửa sổ thuộc tiến trình của ứng dụng Scratchpad:
     - Nếu ứng dụng chỉ có duy nhất 1 cửa sổ (đặc thù của các app utility như iTerm2 Quake window, Calculator, Quick Note): gọi trực tiếp `NSRunningApplication.hide()` để ẩn toàn bộ tiến trình và hệ điều hành tự động giấu cửa sổ tức thì.
     - Nếu ứng dụng có từ 2 cửa sổ trở lên đang mở: không gọi `hide()` toàn ứng dụng (tránh làm biến mất các cửa sổ công việc khác của app đó), mà chuyển quyền kích hoạt tiêu điểm và nâng cửa sổ ứng dụng trước đó (`preSummonApp` / `kAXRaiseAction`), đồng thời đẩy cửa sổ Scratchpad xuống lớp dưới.
  2. Hoàn trả tiêu điểm bàn phím chính xác cho ứng dụng và cửa sổ đang làm việc trước khi triệu hồi (`preSummonPID` & `preSummonWindowID`).
- **Rationale**: Đảm bảo trải nghiệm giấu cửa sổ mượt mà, tức thì, bảo vệ trọn vẹn mạch làm việc của người dùng mà không gây tác dụng phụ ẩn nhầm cửa sổ khác.

### ASM-SCRATCH-002 — Granular Dismiss on Blur vs ESC Configuration

- **Decision**: Tách bạch hai cơ chế tự động ẩn để đáp ứng thói quen sử dụng đa dạng của người dùng:
  1. **ESC Key Dismiss**: Mặc định kích hoạt (BẬT). Khi Scratchpad đang nhận tiêu điểm, nhấn phím `ESC` sẽ lập tức giấu cửa sổ Scratchpad và trả tiêu điểm về ứng dụng trước đó. Bộ lắng nghe `ESC` chỉ hoạt động cục bộ khi Scratchpad là frontmost window, tuyệt đối không nuốt (consume) phím `ESC` của các ứng dụng nền khác.
  2. **Click-Outside Dismiss (Dismiss on Blur)**: Cung cấp tùy chọn toggle độc lập trong FlowSnap Settings (`dismissOnBlur: Bool`, mặc định TẮT hoặc tùy biến).
     - Khi TẮT: Người dùng có thể thoải mái click chuột sang cửa sổ Brave / tài liệu nền để bôi đen, copy văn bản hoặc đối chiếu dữ liệu mà Scratchpad vẫn nổi cố định trước mặt.
     - Khi BẬT: Bất kỳ thao tác click chuột nào bên ngoài phạm vi khung hình (`frame`) của Scratchpad sẽ lập tức kích hoạt chu trình dismiss.
- **Rationale**: Trao quyền kiểm soát tối đa cho người dùng; tránh sự ức chế phổ biến khi cửa sổ ghi chú/terminal vừa click ra ngoài đã biến mất trong lúc đang cần copy dữ liệu giữa hai bên.

### ASM-SCRATCH-003 — Safe Lifecycle Detach & Ghost Reference Prevention

- **Decision**: Ngăn chặn triệt để lỗi tham chiếu ma (ghost/zombie window reference) khi ứng dụng được gán Scratchpad bị đóng hoặc tắt:
  1. `ScratchpadCoordinator` đăng ký theo dõi `NSWorkspace.didTerminateApplicationNotification`. Nếu PID của ứng dụng trùng với PID đang gán làm Scratchpad, tự động thực hiện hủy gán (`detachScratchpad()`).
  2. Trong mỗi lần triệu hồi (Summon), nếu `AXUIElement` của cửa sổ không còn phản hồi hoặc bị hủy hợp lệ (`kAXErrorInvalidUIElement`), tự động giải phóng bản ghi gán, phát âm thanh cảnh báo nhẹ hoặc thông báo trạng thái.
  3. Cập nhật Menu Bar tức thì về trạng thái "Chưa gán Scratchpad" (`Unassigned`).
- **Rationale**: Giữ cho trạng thái hệ thống luôn nhất quán, không tiêu tốn tài nguyên và không gây crash hay đóng băng khi gọi lệnh trên tiến trình đã chết.

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Global Hotkey `⌥Space`**: Đăng ký trong `GlobalHotkeyManager` theo mẫu `ShortcutAction.toggleScratchpad` và phím tắt gán nhanh `ShortcutAction.assignScratchpad` (`⌃⌥Space`).
- **Zero-Shrink Preservation**: Ứng dụng nền (Brave, VS Code) giữ nguyên 100% kích thước và vị trí, hoàn toàn không bị co nhỏ hay xáo trộn bố cục khi Scratchpad xuất hiện hoặc biến mất.
- **Sub-50ms Latency Budget**: Instant summon và instant dismiss thực thi dưới 50ms từ thời điểm nhấn phím tắt.
- **Stage Manager & Spaces Co-existence**: Cửa sổ Scratchpad được triệu hồi trực tiếp trên Space và Stage hiện hành mà không kích hoạt hiệu ứng chuyển Space của macOS.
- **Settings Configuration**: Cung cấp toggle bật/tắt trong `PreferencesStore` và `SettingsView`.
- **Swift 6 Strict Concurrency**: Toàn bộ các class/actor tuân thủ 100% `Sendable` và `@MainActor`.
