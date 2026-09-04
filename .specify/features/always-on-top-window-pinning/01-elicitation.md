# 01 — Elicitation Record (Stage 2) — always-on-top-window-pinning

> Interview conducted on 2026-09-04 via interactive interview gate for US-SNAP-021.
> Confirmed decisions: `ASM-PIN-001`, `ASM-PIN-002`, `ASM-PIN-003`.

## Confirmed Decisions

### ASM-PIN-001 — Active Re-assertion Coordination via Focus Observation & LIFO AXRaise

- **Decision**: Nhằm duy trì trạng thái Always-On-Top cho các cửa sổ ứng dụng bên thứ 3 mà không vi phạm nguyên tắc Zero Private API (không gọi CGS/SLS private symbols):
  1. FlowSnap quản lý danh sách các cửa sổ được ghim (`pinnedWindowIDs: [CGWindowID]`) theo thứ tự LIFO (Last-In, First-Out) trong `WindowPinningCoordinator`.
  2. Lắng nghe các sự kiện kích hoạt ứng dụng / đổi tiêu điểm (`NSWorkspace.didActivateApplicationNotification` và `kAXFocusedWindowChangedNotification`).
  3. Khi một cửa sổ thông thường (không nằm trong danh sách ghim) nhận tiêu điểm (người dùng click sang ứng dụng khác bên dưới), `WindowPinningCoordinator` ngay lập tức thực hiện vòng lặp điều phối nâng tuần tự các cửa sổ trong danh sách ghim từ đáy lên đỉnh LIFO bằng `kAXRaiseAction` (`AXUIElementPerformAction(element, kAXRaiseAction as CFString)`).
  4. Đảm bảo cửa sổ ghim luôn nổi trên mặt trước của tất cả các ứng dụng nền, đồng thời cửa sổ ghim vừa tương tác gần nhất luôn nằm trên các cửa sổ ghim trước đó.
- **Rationale**: Hoàn toàn tuân thủ các API công khai của macOS (Public Accessibility API), ổn định 100% qua các phiên bản hệ điều hành (macOS 14+ Sonoma, macOS 15+ Sequoia), không gây xung đột sandbox hay Hardened Runtime.

### ASM-PIN-002 — Event-driven Stage Manager Launch Interception & Multi-Raise Coordination

- **Decision**: Để hòa hợp hoàn hảo với Stage Manager khi mở ứng dụng mới:
  1. Sử dụng kiến trúc hướng sự kiện (Event-driven): `StageManagerLaunchCoordinator` đăng ký lắng nghe `NSWorkspace.didLaunchApplicationNotification`.
  2. Khi ứng dụng mới bắt đầu khởi chạy trong lúc Stage Manager đang BẬT (`StageManagerDetector.isStageManagerEnabled == true`):
     - Lập tức chụp lại danh sách cửa sổ hiện có trên Stage hiện tại (`activeStageWindowIDs`).
     - Tận dụng `ApplicationObserver` (`kAXWindowCreatedNotification` từ US-WORK-013) để đón bắt chính xác thời điểm cửa sổ đầu tiên của ứng dụng mới được tạo lập.
     - Sau khi cửa sổ mới xuất hiện, thực hiện điều phối chuỗi nâng `kAXRaiseAction` cho toàn bộ các cửa sổ thuộc Stage cũ.
  3. Nhờ đó, macOS gom cả ứng dụng mới và các ứng dụng đang làm việc vào chung một Stage hiện hành mà không đẩy bất kỳ ứng dụng nào ra dải cánh gà (sidebar strip).
- **Rationale**: Loại bỏ hoàn toàn cơ chế Polling lặp, tiêu thụ 0% CPU khi nhàn rỗi, tương thích triệt để với triết lý thiết kế module sâu và phản ứng sự kiện đã được kiểm chứng tại US-WORK-018.

### ASM-PIN-003 — Menu Bar Status Management & Temporary HUD Toast Indicator

- **Decision**: Chỉ báo trạng thái ghim được triển khai đồng bộ:
  1. **Menu Bar Status Item**: Hiển thị trạng thái số lượng cửa sổ đang ghim (ví dụ icon 📌 kèm badge số lượng nếu > 0); menu xổ xuống cung cấp danh sách tên các app đang ghim và tùy chọn "Unpin All" hoặc unpin từng cửa sổ.
  2. **HUD Toast Phản hồi Tức thì**: Khi người dùng nhấn phím tắt toàn cục `⌃⌥P` (`Pin/Unpin Focused Window`):
     - Hiển thị một HUD Toast nổi nhẹ nhàng ở góc màn hình trong 1.0 giây (ví dụ: `📌 Pinned [VS Code]` hoặc `Bỏ ghim [Safari]`).
     - Không vẽ overlay trực tiếp đè lên khung cửa sổ của ứng dụng thứ 3 để tránh lỗi visual glitches khi di chuyển/resize cửa sổ.
- **Rationale**: Đảm bảo giao diện người dùng tinh gọn, thẩm mỹ macOS chuẩn mực, phản hồi thị giác tức thì mà không làm rối mắt hay suy giảm hiệu năng render của hệ thống.

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Global Hotkey `⌃⌥P`**: Đăng ký trong `GlobalHotkeyManager` theo mẫu `ShortcutAction.togglePinFocusedWindow`.
- **Space Scoping**: Cửa sổ ghim cố định tại Desktop Space hiện tại, không tự động bám dính (sticky) sang Space khác khi người dùng chuyển Desktop Space.
- **System Modal Safety**: Bỏ qua re-assertion nếu active element là cửa sổ hệ thống (SecurityAgent, Touch ID dialog, Keychain modal, File Dialogs).
- **Settings Configuration**: Cung cấp toggle bật/tắt tính năng Stage Manager Launch Co-existence (mặc định BẬT) và tùy biến phím tắt ghim trong FlowSnap Settings.
- **Swift 6 Strict Concurrency**: Toàn bộ các class/actor tuân thủ 100% `Sendable` và `@MainActor`.
