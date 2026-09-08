# Specifications & User Stories: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

- **Feature**: `web-distribution-hub` (US-WEB-028)
- **Status**: Complete

---

## 1. System Requirements Specification (`REQ-DIST-###`)

### REQ-DIST-001: Nút tải trực tiếp file `.dmg`

- **Mô tả**: Giao diện cung cấp nút CTA chính (Primary Call-To-Action) cho phép tải trực tiếp file `FlowSnap.dmg` từ GitHub Releases.
- **Derived from**: `BR-DIST-001`, `DEC-DIST-002`.
- **Tiêu chí**:
  - Trỏ đến `https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg`.
  - Hiển thị đầy đủ nhãn phiên bản (`v1.3.1`), kiến trúc Universal Binary (Apple Silicon + Intel x86_64), yêu cầu macOS 14.0+.
  - Có liên kết phụ "View all releases" trỏ về danh sách phiên bản GitHub.

### REQ-DIST-002: Khung lệnh Terminal One-Line Installer kèm Tab Toggle

- **Mô tả**: Khung giao diện Terminal chuyên nghiệp giả lập phong cách macOS với 2 tab cài đặt: `cURL` (mặc định) và `Homebrew`.
- **Derived from**: `BR-DIST-002`, `DEC-DIST-001`.
- **Tiêu chí**:
  - Tab 1 (cURL): `curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash`
  - Tab 2 (Homebrew): `brew install --cask ahauy/tap/flowsnap`
  - Khi người dùng bấm đổi tab, khối lệnh hiển thị cập nhật ngay lập tức không giật layout.

### REQ-DIST-003: Cơ chế sao chép 1-click kèm phản hồi thị giác

- **Mô tả**: Nút Copy trên khung Terminal cho phép chép lệnh vào clipboard chỉ với 1 thao tác bấm chuột hoặc phím Enter.
- **Derived from**: `BR-DIST-003`, `BR-DIST-004`, `ASM-DIST-003`, `ASM-DIST-004`.
- **Tiêu chí**:
  - Sao chép chính xác nội dung câu lệnh của tab đang chọn.
  - Phản hồi tức thì: icon chuyển sang dấu checkmark xanh, nhãn nút chuyển sang "Copied!" trong đúng 2000ms.
  - Hỗ trợ fallback an toàn nếu trình duyệt chặn Clipboard API.

### REQ-DIST-004: Tuyên ngôn Quyền riêng tư (Privacy & Trust Manifesto)

- **Mô tả**: Khu vực minh bạch hóa quyền riêng tư với 3 trụ cột niềm tin vững chắc.
- **Derived from**: `BR-DIST-005`, `DEC-DIST-002`.
- **Tiêu chí**:
  - _100% Offline_: Không tạo kết nối mạng nền, không phụ thuộc server đám mây.
  - _Zero Telemetry_: Không nạp công cụ theo dõi hay phân tích hành vi người dùng.
  - _AXUIElement Transparency_: Giải thích quyền Trợ năng chỉ dùng để dịch chuyển cửa sổ, không đọc phím gõ.

### REQ-DIST-005: Hướng dẫn vượt rào cản macOS Gatekeeper

- **Mô tả**: Khối Accordion có thể mở rộng/thu gọn hướng dẫn xử lý cảnh báo "Unidentified Developer" trên macOS.
- **Derived from**: `BR-DIST-006`, `DEC-DIST-003`, `RISK-DIST-002`.
- **Tiêu chí**:
  - Trình bày trực quan lý do macOS hiển thị cảnh báo (cơ chế Gatekeeper quarantine).
  - Cung cấp câu lệnh chuẩn: `xattr -cr /Applications/FlowSnap.app` kèm nút 1-click copy riêng biệt.

---

## 2. User Stories & Gherkin Scenarios (`US-DIST-###`)

### US-DIST-001: Tải file DMG trực tiếp

- **Given** người dùng đang ở phần `#download` trên trang web FlowSnap
- **When** người dùng nhấp vào nút "Download FlowSnap for macOS"
- **Then** trình duyệt bắt đầu tải tệp `FlowSnap.dmg` từ đường dẫn GitHub Releases chính thức
- **And** người dùng thấy rõ thông tin phiên bản `v1.3.1` và kiến trúc Universal tương thích cả M-series và Intel.

### US-DIST-002: Chuyển đổi giữa các tab cài đặt Terminal

- **Given** khung Terminal One-Line Installer đang hiển thị tab mặc định `cURL`
- **When** người dùng nhấp vào tab "Homebrew"
- **Then** câu lệnh trong khung Terminal lập tức chuyển thành `brew install --cask ahauy/tap/flowsnap`
- **And** tab Homebrew được đánh dấu active với hiệu ứng thị giác rõ ràng.

### US-DIST-003: Sao chép lệnh Terminal bằng 1 cú nhấp chuột

- **Given** người dùng đang xem khung Terminal với tab `cURL` đang mở
- **When** người dùng bấm nút "Copy"
- **Then** toàn bộ câu lệnh `curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash` được sao chép vào bộ nhớ tạm
- **And** nút hiển thị trạng thái "Copied!" với biểu tượng checkmark trong 2000ms trước khi trở về trạng thái "Copy".

### US-DIST-004: Tìm hiểu Tuyên ngôn Quyền riêng tư

- **Given** người dùng băn khoăn về vấn đề an toàn bảo mật của ứng dụng tiện ích
- **When** người dùng đọc cột Privacy Manifesto ở bên phải
- **Then** người dùng thấy rõ 3 cam kết: 100% Offline, Zero Telemetry và giải thích minh bạch quyền Trợ năng `AXUIElement`
- **And** có liên kết kiểm tra trực tiếp mã nguồn mở trên GitHub.

### US-DIST-005: Xử lý cảnh báo Gatekeeper trên macOS

- **Given** người dùng tải bản phát hành nguồn mở và gặp thông báo cách ly của macOS
- **When** người dùng bấm mở khối "Encountering macOS Gatekeeper warning?"
- **Then** hướng dẫn chi tiết hiện ra giải thích cơ chế quarantine
- **And** cung cấp nút copy 1-click cho lệnh `xattr -cr /Applications/FlowSnap.app` để người dùng mở app thành công.
