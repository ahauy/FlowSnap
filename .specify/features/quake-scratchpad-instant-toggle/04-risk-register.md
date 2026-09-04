# 04 — Risk Register & Scope Boundary (MoSCoW) — quake-scratchpad-instant-toggle

> Feature: `US-SNAP-022: Quake-Style Quick Scratchpad & Instant Window Toggle`  
> Stage 5: Risk & Contradiction Scan

---

## 1. Consolidated Assumptions Register

| ID                | Title                                              | Pillar                 | Status                    |
| :---------------- | :------------------------------------------------- | :--------------------- | :------------------------ |
| `ASM-SCRATCH-001` | Hybrid Process & Window Dismiss Coordination       | Workflows & Edge Cases | Confirmed (Customer Gate) |
| `ASM-SCRATCH-002` | Granular Dismiss on Blur vs ESC Configuration      | UX / Rules             | Confirmed (Customer Gate) |
| `ASM-SCRATCH-003` | Safe Lifecycle Detach & Ghost Reference Prevention | States & Lifecycle     | Confirmed (Customer Gate) |

---

## 2. Risk Register & Mitigations

| Risk ID            | Description & Severity                                                              | Likelihood | Impact | Mitigation Strategy                                                                                                                                                                                                         |
| :----------------- | :---------------------------------------------------------------------------------- | :--------- | :----- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `RISK-SCRATCH-001` | **Xung đột phím ESC trong ứng dụng dòng lệnh (Vim, Helix, Nano)** (Medium)          | Medium     | Medium | Thêm tùy chọn `dismissOnEsc: Bool` (mặc định BẬT) trong Settings. Người dùng chuyên Vim/Terminal có thể tắt để phím ESC truyền nguyên vẹn vào terminal mà không kích hoạt ẩn cửa sổ.                                        |
| `RISK-SCRATCH-002` | **Ứng dụng nền trước đó bị đóng/crash trong lúc mở Scratchpad** (Low)               | Low        | Low    | Khi thực hiện hoàn trả focus, kiểm tra tính hợp lệ của `preSummonPID` qua `NSRunningApplication(processIdentifier:)`. Nếu tiến trình đã chết, fallback an toàn về frontmost app của macOS, tránh ném lỗi hay treo hệ thống. |
| `RISK-SCRATCH-003` | **Xung đột phím tắt toàn cục với Raycast / Alfred / Spotlight** (`⌥Space`) (Medium) | Medium     | Medium | Hỗ trợ ghi đè và tùy biến phím tắt tự do trong Settings qua `ShortcutRecorderField`. Nếu đăng ký hotkey thất bại (`Carbon error`), thông báo trực quan cho người dùng đổi phím khác.                                        |
| `RISK-SCRATCH-004` | **Ứng dụng Scratchpad có nhiều cửa sổ bị giấu toàn bộ nếu gọi `hide()`** (High)     | Medium     | High   | Triển khai triệt để cơ chế Hybrid Dismiss theo `ASM-SCRATCH-001`: Nếu ứng dụng có ≥ 2 cửa sổ mở, không gọi `hide()` mà hạ layer và kích hoạt app trước đó.                                                                  |
| `RISK-SCRATCH-005` | **Trễ phản hồi khi triệu hồi trên hệ thống đang tải nặng** (Low)                    | Low        | Low    | Sử dụng trực tiếp `kAXRaiseAction` và `activate(options: .activateIgnoringOtherApps)`, không blocking luồng chính, đảm bảo ngân sách `< 50ms`.                                                                              |

---

## 3. Scope Boundary (MoSCoW)

### Must-Have (Bắt buộc phải có để hoàn thành DoD)

- `ScratchpadRecord`, `ScratchpadState`, `PreSummonFocus` domain models.
- `ScratchpadCoordinating` protocol và `ScratchpadCoordinator` (@MainActor).
- Phím tắt toàn cục `ShortcutAction.toggleScratchpad` (`⌥Space`) và `ShortcutAction.assignScratchpad` (`⌃⌥Space`).
- Cơ chế Hybrid Dismiss (`ASM-SCRATCH-001`) và hoàn trả tiêu điểm chính xác (`BR-SCRATCH-004`).
- Tự động hủy gán khi app terminate (`ASM-SCRATCH-003`).
- Tích hợp Menu Bar: hiển thị trạng thái Scratchpad (tên app/window) kèm nút Toggle và Detach (`BR-SCRATCH-008`).
- Cấu hình trong `PreferencesStore` và `SettingsView`: toggles `dismissOnBlur` và `dismissOnEsc`.
- Test suite với Swift Testing kiểm thử đầy đủ các kịch bản state transitions.

### Should-Have (Nên có nếu không gây chậm tiến độ)

- Cảnh báo âm thanh nhẹ (system sound) khi gán hoặc hủy gán Scratchpad.
- Hiển thị HUD Toast nhỏ báo trạng thái khi gán hoặc triệu hồi.

### Could-Have (Có thể mở rộng trong các bản sau)

- Tùy biến hoạt ảnh xuất hiện (trượt từ mép trên kiểu Quake cổ điển).

### Won't-Have (Dứt khoát KHÔNG làm trong phạm vi này)

- ❌ Không can thiệp mã nguồn hay inject DLL/dylib vào ứng dụng bên thứ 3.
- ❌ Không sử dụng bất kỳ Private CGS / SLS APIs nào.
- ❌ Không hỗ trợ gán nhiều cửa sổ làm Scratchpad cùng lúc (chỉ 1 active Scratchpad duy nhất tại một thời điểm để đảm bảo tính tức thì và đơn giản).
- ❌ Không di chuyển Scratchpad xuyên Desktop Spaces nếu người dùng đang ở Space khác.
