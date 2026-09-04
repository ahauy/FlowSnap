# 04 — Risk Register & Scope Lock: always-on-top-window-pinning (US-SNAP-021)

## 1. Risk Register

| Risk ID          | Description                                                                                                                                      | Severity | Likelihood | Mitigation Strategy                                                                                                                                                                                                         |
| :--------------- | :----------------------------------------------------------------------------------------------------------------------------------------------- | :------- | :--------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-PIN-001** | **Re-assertion Focus Thrashing**: Vòng lặp re-assertion cướp tiêu điểm bàn phím của ứng dụng nền mà người dùng đang gõ/click.                    | High     | Low        | **Chỉ dùng `kAXRaiseAction`**: Nâng lớp hiển thị (Z-order visual layering) mà tuyệt đối KHÔNG gọi `activate()` hay cướp keyboard focus khỏi ứng dụng nền người dùng đang thao tác.                                          |
| **RISK-PIN-002** | **Che khuất Modal bảo mật hệ thống**: Cửa sổ ghim nằm đè lên các hộp thoại Keychain, Touch ID, hoặc File Dialogs.                                | Critical | Low        | **System Modal Detection**: Kiểm tra bundle identifier hoặc window role; nếu ứng dụng đang kích hoạt là `com.apple.SecurityAgent` hoặc `com.apple.CoreAuthUI`, tạm hoãn re-assertion cho đến khi người dùng đóng hộp thoại. |
| **RISK-PIN-003** | **Orphan Pinned Window Leaks**: Người dùng đóng cửa sổ ghim hoặc quit app, ID cửa sổ vẫn nằm trong danh sách gây leak bộ nhớ và gọi AX vô nghĩa. | Medium   | Medium     | Lắng nghe `NSWorkspace.didTerminateApplicationNotification` để auto-remove theo PID, đồng thời khi `raise` trả về `kAXErrorInvalidUIElement` thì tự động xóa bản ghi khỏi danh sách.                                        |
| **RISK-PIN-004** | **Launch Co-existence Race Condition**: App mới mất nhiều thời gian khởi động, danh sách Stage cũ bị trôi mất trước khi cửa sổ mới xuất hiện.    | Medium   | Low        | Snapshot danh sách cửa sổ của Stage ngay tại thời điểm `didLaunchApplicationNotification`, kết hợp `ApplicationObserver` chờ sự kiện `kAXWindowCreatedNotification` với timeout tối đa 5.0s.                                |

---

## 2. Consolidated Assumptions (`ASM-`)

- **ASM-PIN-001**: Active Re-assertion Coordination: Sử dụng `kAXRaiseAction` nâng tuần tự danh sách cửa sổ ghim theo thứ tự LIFO khi có sự kiện chuyển tiêu điểm, không dùng Private API.
- **ASM-PIN-002**: Event-driven Stage Manager Launch Interception: Đón bắt `NSWorkspace.didLaunchApplicationNotification` + `ApplicationObserver` để thực hiện Multi-Raise gom chung app mới và cũ vào 1 Stage duy nhất.
- **ASM-PIN-003**: Menu Bar & Temporary HUD Toast Indicator: Phản hồi tức thì 1.0 giây bằng HUD toast khi bấm `⌃⌥P` và hiển thị danh sách trong Menu Bar.

---

## 3. MoSCoW Scope Lock

### Must-Have

- [x] Protocol `WindowPinningCoordinating` và model `PinnedWindowRecord`.
- [x] Class `WindowPinningCoordinator` quản lý danh sách LIFO và re-assertion qua `kAXRaiseAction`.
- [x] Protocol `StageManagerLaunchCoordinating` và class `StageManagerLaunchCoordinator`.
- [x] Đăng ký phím tắt toàn cục `⌃⌥P` (`ShortcutAction.togglePinFocusedWindow`).
- [x] Tích hợp toggle Stage Manager Launch Co-existence trong `PreferencesStore` và `SettingsView`.
- [x] Cập nhật `MenuBarViewModel` hiển thị danh sách cửa sổ ghim và nút Unpin.
- [x] Hệ thống HUD Toast thông báo phản hồi trạng thái Pin/Unpin.
- [x] Bộ test suite đạt 100% pass với Swift Testing & Mocks.

### Should-Have

- [x] Clean architecture DI injection trong `AppDependencies`.
- [x] Tự động dọn dẹp cửa sổ ghim khi app sở hữu bị terminate.

### Won't-Have (Strictly Out of Scope)

- ❌ Tuyệt đối KHÔNG sử dụng Private APIs (`CGSSetWindowLevel`, `SLSSetWindowProperty`).
- ❌ Không can thiệp vẽ overlay hay hook view vào tiến trình của ứng dụng bên thứ 3.
- ❌ Không hỗ trợ ghim bám dính (sticky) xuyên Desktop Spaces (giữ đúng nguyên tắc Space Scoping).
