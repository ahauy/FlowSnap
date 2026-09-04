# 05 — User Stories & Acceptance Criteria — quake-scratchpad-instant-toggle

> Feature: `US-SNAP-022: Quake-Style Quick Scratchpad & Instant Window Toggle`  
> Traceability: Derived from `BR-SCRATCH-001` to `BR-SCRATCH-008` & `ASM-SCRATCH-001` to `ASM-SCRATCH-003`.

---

### US-SCRATCH-001: Đăng ký và Hủy gán Scratchpad Window

**As a** macOS Power User  
**I want to** chỉ định một cửa sổ đang mở (iTerm2, Notes, Calculator) làm Quick Scratchpad hoặc hủy gán bất kỳ lúc nào  
**So that** tôi có một tiện ích chuyên biệt sẵn sàng triệu hồi tức thì mà không cần tìm kiếm hay chuyển màn hình.

- **Scenario 1.1: Gán thành công cửa sổ có tiêu điểm qua phím tắt (Happy Path)**
  - **Given** Tôi đang mở cửa sổ iTerm2 và cửa sổ này đang nhận tiêu điểm (focused)
  - **When** Tôi nhấn tổ hợp phím `⌃⌥Space` (hoặc chọn "Gán cửa sổ này làm Scratchpad" trong Menu Bar)
  - **Then** FlowSnap lưu `ScratchpadRecord` cho cửa sổ này, Menu Bar hiển thị trạng thái "Scratchpad: iTerm2", và phát tín hiệu hoàn tất.

- **Scenario 1.2: Gán đè cửa sổ mới khi đã có Scratchpad cũ**
  - **Given** FlowSnap đã gán Scratchpad là iTerm2
  - **When** Tôi chuyển sang ứng dụng Calculator và nhấn `⌃⌥Space`
  - **Then** Scratchpad cũ được thay thế bằng Calculator mà không cần thao tác hủy gán thủ công trước đó.

- **Scenario 1.3: Hủy gán thủ công từ Menu Bar**
  - **Given** Đang có một cửa sổ được gán làm Scratchpad
  - **When** Tôi mở Menu Bar và nhấn nút "Hủy gán Scratchpad"
  - **Then** Trạng thái chuyển về `unassigned`, Menu Bar hiển thị "Chưa gán Scratchpad", và phím tắt triệu hồi sẽ không thực hiện hành động nào cho đến khi gán mới.

---

### US-SCRATCH-002: Triệu hồi tức thì (Instant Summon) và Bảo tồn ứng dụng nền

**As a** Developer hoặc Writer đang làm việc tập trung trên Brave full-screen hoặc chia màn hình  
**I want to** nhấn `⌥Space` để cửa sổ Scratchpad nhảy ngay lên trên cùng trước mặt tôi trong < 50ms  
**So that** tôi có thể tra cứu hoặc gõ lệnh ngay lập tức mà không làm co nhỏ hoặc xê dịch ứng dụng nền.

- **Scenario 2.1: Triệu hồi khi Scratchpad đang ẩn (Happy Path)**
  - **Given** Scratchpad đã được gán (iTerm2) và đang ở trạng thái `hidden`
  - **And** Tôi đang lướt web trên Brave ở chế độ toàn màn hình hoặc chia nửa
  - **When** Tôi nhấn phím tắt toàn cục `⌥Space`
  - **Then** FlowSnap ghi nhận `PreSummonFocus` (Brave PID & WindowID)
  - **And** Cửa sổ iTerm2 xuất hiện nổi lên trên cùng trước mặt tôi trong `< 50ms`, nhận ngay tiêu điểm bàn phím
  - **And** Cửa sổ Brave giữ nguyên 100% kích thước và vị trí, không bị co nhỏ hay đổi Space.

- **Scenario 2.2: Triệu hồi khi chưa gán Scratchpad (Edge Case)**
  - **Given** Chưa có cửa sổ nào được gán làm Scratchpad (`state == .unassigned`)
  - **When** Tôi nhấn `⌥Space`
  - **Then** FlowSnap không crash, có thể hiển thị thông báo nhẹ hoặc gợi ý gán cửa sổ trước.

---

### US-SCRATCH-003: Giấu tức thì (Instant Dismiss) và Hoàn trả tiêu điểm chuẩn xác

**As a** Power User vừa hoàn tất tra cứu / gõ lệnh trên Scratchpad  
**I want to** nhấn lại `⌥Space`, nhấn phím `ESC`, hoặc click ra ngoài để giấu Scratchpad  
**So that** tôi lập tức quay lại làm việc trên ứng dụng trước đó mà không cần dùng chuột chuyển cửa sổ.

- **Scenario 3.1: Ẩn bằng phím tắt triệu hồi `⌥Space` (Toggle Dismiss)**
  - **Given** Scratchpad (iTerm2) đang mở nổi trên màn hình và nhận tiêu điểm
  - **When** Tôi nhấn lại phím `⌥Space`
  - **Then** Cửa sổ iTerm2 lập tức ẩn đi theo cơ chế Hybrid Dismiss
  - **And** Tiêu điểm bàn phím tự động hoàn trả về cho Brave trong `< 50ms`.

- **Scenario 3.2: Ẩn bằng phím `ESC`**
  - **Given** Scratchpad đang hiển thị và nhận tiêu điểm, và cài đặt `dismissOnEsc == true`
  - **When** Tôi nhấn phím `ESC`
  - **Then** Scratchpad ẩn đi ngay lập tức và trả tiêu điểm về ứng dụng trước đó.

- **Scenario 3.3: Tự động ẩn khi Click chuột ra ngoài (Click-Outside Blur)**
  - **Given** Scratchpad đang hiển thị và cài đặt `dismissOnBlur == true`
  - **When** Tôi click chuột vào vùng làm việc của ứng dụng Brave bên dưới
  - **Then** FlowSnap phát hiện click ngoài bounds của Scratchpad, lập tức ẩn Scratchpad và Brave tiếp tục nhận click/tiêu điểm bình thường.

---

### US-SCRATCH-004: Tự động dọn dẹp vòng đời (Lifecycle Detach)

**As a** User đóng cửa sổ Scratchpad hoặc thoát ứng dụng đó  
**I want to** FlowSnap tự động hủy gán và dọn dẹp bản ghi  
**So that** hệ thống không lưu trữ tham chiếu rác (zombie reference) hay gây lỗi trong các lần triệu hồi sau.

- **Scenario 4.1: Ứng dụng Scratchpad bị thoát (App Terminated)**
  - **Given** iTerm2 đang được gán làm Scratchpad
  - **When** Tôi bấm `⌘Q` thoát hoàn toàn iTerm2
  - **Then** `ScratchpadCoordinator` nhận thông báo terminate từ `NSWorkspace`, tự động chuyển trạng thái về `unassigned` và cập nhật Menu Bar.

- **Scenario 4.2: Cửa sổ Scratchpad bị đóng nhưng ứng dụng vẫn chạy**
  - **Given** Calculator đang gán Scratchpad và người dùng bấm nút đỏ đóng cửa sổ đó
  - **When** Người dùng nhấn `⌥Space` để triệu hồi
  - **Then** FlowSnap phát hiện cửa sổ không còn tồn tại hợp lệ qua AX API, tự động hủy gán và đưa ra phản hồi phù hợp.

---

### US-SCRATCH-005: Tùy biến phím tắt và Cấu hình trong Settings

**As a** User có thói quen sử dụng phím tắt và hành vi đóng mở riêng  
**I want to** tùy chỉnh phím tắt triệu hồi, phím tắt gán, và các nút toggle Dismiss on Blur / ESC trong Settings  
**So that** FlowSnap thích ứng tối đa với luồng làm việc cá nhân của tôi.

- **Scenario 5.1: Cấu hình phím tắt mới trong Settings**
  - **Given** Tôi mở mục Settings > Shortcuts của FlowSnap
  - **When** Tôi ghi lại tổ hợp phím mới cho `ShortcutAction.toggleScratchpad` (ví dụ `⌃⌥T`)
  - **Then** `GlobalHotkeyManager` giải phóng hotkey cũ và đăng ký thành công hotkey mới.

- **Scenario 5.2: Bật/Tắt Dismiss on Blur và Dismiss on ESC**
  - **Given** Tôi mở mục Settings > General / Behavior của FlowSnap
  - **When** Tôi toggle `dismissOnBlur` hoặc `dismissOnEsc`
  - **Then** Giá trị được lưu vào `PreferencesStore` và áp dụng ngay lập tức mà không cần khởi động lại ứng dụng.
