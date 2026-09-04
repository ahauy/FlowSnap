# Domain Baseline: Universal Always-On-Top Pinning & Stage Manager Launch Co-existence (US-SNAP-021)

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0 (Confirmation Gate 1 Approved)
- **Feature Slug**: `always-on-top-window-pinning`
- **Related Roadmap Item**: `US-SNAP-021` (EPIC 15 — Universal Always-On-Top Pinning & Stage Manager Launch Co-existence)

---

## 1. Domain Summary

Nâng cấp toàn diện cơ chế kiểm soát cửa sổ nổi trên macOS trên nền tảng Public API (Zero Private API):

1. **Always-On-Top Pinning (`⌃⌥P`)**: Cho phép ghim cửa sổ của bất kỳ ứng dụng bên thứ 3 nào luôn nổi trên bề mặt các ứng dụng khác thông qua cơ chế **Active Re-assertion Coordination** (lắng nghe sự kiện đổi focus và tự động nâng các cửa sổ ghim bằng `kAXRaiseAction`).
2. **Dynamic LIFO Z-Stacking**: Hỗ trợ ghim không giới hạn số lượng cửa sổ. Cửa sổ ghim nào được tương tác gần nhất sẽ nằm trên các cửa sổ ghim trước đó; toàn bộ nhóm ghim luôn nằm trên các cửa sổ chưa ghim.
3. **Stage Manager Launch Co-existence**: Khi Stage Manager BẬT, đánh chặn sự kiện khởi chạy ứng dụng mới từ Dock / Spotlight / Raycast / Finder (`NSWorkspace.didLaunchApplicationNotification`), snapshot cửa sổ của Stage cũ, chờ cửa sổ mới tạo xong qua `ApplicationObserver`, và thực hiện Multi-Raise gom toàn bộ vào cùng một Stage duy nhất mà không bị macOS đẩy ra dải cánh gà.
4. **An toàn hệ thống (System Modal Safety & Space Scoping)**: Tạm hoãn re-assertion khi active window là modal bảo mật (Keychain, Touch ID, SecurityAgent). Giữ nguyên phạm vi Desktop Space cục bộ, không tự động bám dính sang Space khác.
5. **Trực quan hóa & Cấu hình**: Phản hồi tức thì qua HUD Toast (1.0s) khi bấm `⌃⌥P`, hiển thị danh sách cửa sổ ghim trong Menu Bar, và cung cấp toggle Stage Manager Co-existence trong Settings.

---

## 2. Business Rules Reference

- **BR-PIN-001**: Toggle Pin State — Chuyển đổi trạng thái ghim qua phím tắt `⌃⌥P` hoặc Menu Bar.
- **BR-PIN-002**: Dynamic LIFO Z-Stacking — Xếp lớp động không giới hạn cửa sổ ghim theo thứ tự LIFO.
- **BR-PIN-003**: Active Re-assertion Coordination — Nâng cửa sổ ghim bằng `kAXRaiseAction` khi app nền nhận focus.
- **BR-PIN-004**: System Modal Safety — Miễn trừ re-assertion với các modal bảo mật hệ thống.
- **BR-PIN-005**: Local Space Scoping — Ghim cố định tại Desktop Space hiện tại.
- **BR-PIN-006**: Stage Manager Launch Co-existence — Multi-raise gom app mới và cũ vào 1 Stage duy nhất.
- **BR-PIN-007**: Automatic Window Lifecycle Cleanup — Dọn dẹp bản ghi khi cửa sổ đóng hoặc app terminate.
- **BR-PIN-008**: HUD Feedback & Menu Bar Synchronization — HUD Toast 1.0s và cập nhật Menu Bar.

---

## 3. Assumptions Register

- `ASM-PIN-001`: Active Re-assertion Coordination via Focus Observation & LIFO AXRaise.
- `ASM-PIN-002`: Event-driven Stage Manager Launch Interception & Multi-Raise Coordination.
- `ASM-PIN-003`: Menu Bar Status Management & Temporary HUD Toast Indicator.

---

## 4. Scope (MoSCoW)

- **Must-Have**:
  - `WindowPinningCoordinating` & `PinnedWindowRecord`.
  - `WindowPinningCoordinator` quản lý LIFO stacking và re-assertion qua `kAXRaiseAction`.
  - `StageManagerLaunchCoordinating` & `StageManagerLaunchCoordinator`.
  - Global Hotkey `⌃⌥P` (`ShortcutAction.togglePinFocusedWindow`).
  - Toggle trong `PreferencesStore` và `SettingsView`.
  - Menu Bar status item list + HUD Toast feedback.
  - Test suite hoàn chỉnh với Swift Testing và Mocks.
- **Should-Have**:
  - Tự động dọn dẹp khi app terminate qua `didTerminateApplicationNotification`.
  - DI container integration trong `AppDependencies`.
- **Won't-Have**:
  - ❌ Tuyệt đối không dùng Private CGS / SLS APIs.
  - ❌ Không can thiệp overlay hay code injection vào app bên thứ 3.
  - ❌ Không hỗ trợ ghim bám dính (sticky) xuyên Desktop Spaces.
