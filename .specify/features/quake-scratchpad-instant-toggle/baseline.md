# Domain Baseline: Quake-Style Quick Scratchpad & Instant Window Toggle (US-SNAP-022)

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0 (Confirmation Gate 1 Approved)
- **Feature Slug**: `quake-scratchpad-instant-toggle`
- **Related Roadmap Item**: `US-SNAP-022` (EPIC 15 — Universal Always-On-Top Pinning & Stage Manager Launch Co-existence)

---

## 1. Domain Summary

Nâng cấp cơ chế quản lý cửa sổ tiện ích tức thì kiểu Quake (Quake-style Scratchpad Overlay) hoàn toàn trên nền tảng Public macOS APIs (Zero Private API):

1. **Chỉ định Scratchpad tức thì (`BR-SCRATCH-001`)**: Cho phép người dùng gán bất kỳ cửa sổ nào (iTerm2, Ghi chú, Calculator, Finder...) làm Quick Scratchpad qua phím tắt (`⌃⌥Space` hoặc tùy biến) hoặc từ Menu Bar.
2. **Instant Summon trong < 50ms & Zero-Shrink (`BR-SCRATCH-002`)**: Nhấn phím tắt toàn cục (`⌥Space`), cửa sổ Scratchpad nhảy ngay lên trước mặt người dùng, nhận tiêu điểm bàn phím tức thì. Ứng dụng nền (Brave, VS Code) được bảo toàn 100% kích thước và vị trí, tuyệt đối không co nhỏ hay chuyển Space.
3. **Cơ chế Hybrid Dismiss & Hoàn trả tiêu điểm (`BR-SCRATCH-003`, `BR-SCRATCH-004`)**:
   - Đối với ứng dụng đơn cửa sổ: Ẩn tiến trình bằng `NSRunningApplication.hide()`.
   - Đối với ứng dụng đa cửa sổ (≥ 2 cửa sổ): Hạ layer và chuyển quyền kích hoạt về ứng dụng trước đó (`preSummonFocus`) mà không làm biến mất các cửa sổ công việc khác của app đó.
   - Tiêu điểm bàn phím tự động hoàn trả về ứng dụng và cửa sổ đang mở trước đó trong < 50ms.
4. **Đa dạng cơ chế tự động ẩn (`BR-SCRATCH-005`)**: Mặc định hỗ trợ ẩn bằng phím `ESC` khi Scratchpad đang nhận tiêu điểm; cung cấp tùy chọn toggle độc lập `dismissOnBlur` trong Settings để người dùng có thể click app nền đối chiếu dữ liệu mà không làm mất Scratchpad.
5. **Dọn dẹp vòng đời an toàn (`BR-SCRATCH-006`)**: Tự động hủy gán và cập nhật Menu Bar khi ứng dụng bị đóng hoặc cửa sổ bị hủy, tránh tham chiếu rác.
6. **Menu Bar Status & Quake Actions (`BR-SCRATCH-008`)**: Menu Bar hiển thị trạng thái Scratchpad đang gán, nút Triệu hồi / Ẩn và nút Hủy gán (Detach).

---

## 2. Business Rules Reference

- **BR-SCRATCH-001**: Instant Assignment & Registration — Gán cửa sổ hiện hành làm Scratchpad qua phím tắt hoặc Menu Bar.
- **BR-SCRATCH-002**: Instant Summon Latency (< 50ms) & Zero-Shrink — Triệu hồi cửa sổ Scratchpad nổi lên trên cùng, giữ nguyên kích thước vị trí, không co nhỏ app nền.
- **BR-SCRATCH-003**: Hybrid Dismiss Mechanism — Với app 1 cửa sổ thì gọi `hide()`; với app ≥ 2 cửa sổ thì hạ layer và trả tiêu điểm mà không ẩn toàn bộ app.
- **BR-SCRATCH-004**: Accurate Pre-Summon Focus Restoration — Ghi nhớ PID và windowID của app trước đó, hoàn trả tiêu điểm chính xác khi dismiss.
- **BR-SCRATCH-005**: Dual Dismiss Triggers (ESC & Blur) — Phím ESC kích hoạt dismiss khi Scratchpad có focus; Click-outside dismiss được cấu hình qua PreferencesStore.
- **BR-SCRATCH-006**: Safe Lifecycle Detach & Ghost Avoidance — Tự động hủy gán khi app terminate hoặc window invalid.
- **BR-SCRATCH-007**: Stage Manager & Spaces Co-existence — Triệu hồi trực tiếp trên Space/Stage hiện hành.
- **BR-SCRATCH-008**: Menu Bar Status Synchronization — Menu Bar hiển thị tên app đang gán, nút Triệu hồi / Ẩn và nút Detach.

---

## 3. Assumptions Register

- `ASM-SCRATCH-001`: Hybrid Process & Window Dismiss Coordination (Ưu tiên `app.hide()`, nhưng de-activate hạ layer nếu app có nhiều cửa sổ).
- `ASM-SCRATCH-002`: Granular Dismiss on Blur vs ESC Configuration (ESC mặc định BẬT; Blur là toggle riêng trong Settings).
- `ASM-SCRATCH-003`: Safe Lifecycle Detach & Ghost Reference Prevention (Tự động gỡ gán khi app bị đóng hoặc terminate).

---

## 4. Scope (MoSCoW)

- **Must-Have**:
  - `ScratchpadRecord`, `ScratchpadState`, `PreSummonFocus` domain models.
  - `ScratchpadCoordinating` protocol và `ScratchpadCoordinator` (@MainActor).
  - Phím tắt toàn cục `ShortcutAction.toggleScratchpad` (`⌥Space`) và `ShortcutAction.assignScratchpad` (`⌃⌥Space`).
  - Cơ chế Hybrid Dismiss (`ASM-SCRATCH-001`) và hoàn trả tiêu điểm chính xác (`BR-SCRATCH-004`).
  - Tự động hủy gán khi app terminate (`ASM-SCRATCH-003`).
  - Tích hợp Menu Bar: hiển thị trạng thái Scratchpad (tên app/window) kèm nút Toggle và Detach (`BR-SCRATCH-008`).
  - Cấu hình trong `PreferencesStore` và `SettingsView`: toggles `dismissOnBlur` và `dismissOnEsc`.
  - Test suite với Swift Testing kiểm thử đầy đủ các kịch bản state transitions.
- **Should-Have**:
  - Cảnh báo âm thanh nhẹ (system sound) khi gán hoặc hủy gán Scratchpad.
  - Hiển thị HUD Toast nhỏ báo trạng thái khi gán hoặc triệu hồi.
- **Won't-Have**:
  - ❌ Tuyệt đối không dùng Private CGS / SLS APIs.
  - ❌ Không can thiệp mã nguồn hay inject DLL/dylib vào app bên thứ 3.
  - ❌ Không hỗ trợ gán nhiều cửa sổ làm Scratchpad cùng lúc (1 active Scratchpad duy nhất).
  - ❌ Không hỗ trợ chuyển Scratchpad xuyên Desktop Spaces nếu người dùng đang ở Space khác.
