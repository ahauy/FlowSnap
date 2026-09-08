# Risk & Contradiction Scan: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

- **Feature**: `web-distribution-hub` (US-WEB-028)
- **Status**: Complete

---

## 1. Risk Register (`RISK-DIST-###`)

| ID                | Nguy cơ / Rủi ro                                                                                                                                         | Mức độ | Biện pháp giảm thiểu (Mitigation Strategy)                                                                                                                                                                                                            |
| :---------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-DIST-001** | Trình duyệt chặn quyền truy cập Clipboard API (`navigator.clipboard`) khi ở môi trường iframe hoặc HTTP.                                                 | Medium | Triển khai cơ chế phòng thủ kép (Dual fallback): Kiểm tra `navigator.clipboard` trước; nếu không khả dụng, tạo thẻ `<textarea>` ẩn tạm thời và gọi `document.execCommand('copy')`.                                                                    |
| **RISK-DIST-002** | macOS Sequoia (macOS 15) loại bỏ tùy chọn "Open Anyway" trong menu chuột phải đối với app chưa ký Apple Notarization, gây hoang mang cho người dùng mới. |  High  | Nhấn mạnh giải pháp kỹ thuật `xattr -cr /Applications/FlowSnap.app` (xóa cờ quarantine) ngay trong phần hướng dẫn Gatekeeper, cung cấp nút copy 1-click để người dùng dán vào Terminal là chạy ngay.                                                  |
| **RISK-DIST-003** | Liên kết tải DMG trực tiếp bị lỗi 404 nếu tên file phát hành trên GitHub Releases bị thay đổi định dạng.                                                 | Medium | Chuẩn hóa đường dẫn canonical: `https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg`, kèm link phụ trực tiếp tới trang danh sách releases `https://github.com/ahauy/FlowSnap/releases`.                                           |
| **RISK-DIST-004** | Người dùng lo ngại quyền Trợ năng (Accessibility) là một dạng keylogger đánh cắp mật khẩu.                                                               |  High  | Xây dựng khối "Accessibility Transparency" giải thích chi tiết, minh bạch: FlowSnap chỉ dùng API `AXUIElement` để lấy tọa độ và đặt kích thước cửa sổ; 0% can thiệp luồng gõ phím của app khác; mã nguồn mở 100% trên GitHub cho cộng đồng kiểm toán. |

---

## 2. Contradiction & Edge Case Scan

- **Contradiction Scan**:
  - _Xung đột giữa tính đơn giản và tính đầy đủ_: Người dùng kỹ thuật muốn copy lệnh Terminal ngay, trong khi người dùng văn phòng muốn nút tải DMG bấm chuột truyền thống. -> _Giải pháp_: Chia đôi 2 cột (Split View): Cột trái đáp ứng cả 2 nhu cầu (DMG nút to + Terminal box có tabs), không bắt buộc phải chọn 1 trong 2.
  - _Xung đột về an toàn và cảnh báo Gatekeeper_: Nếu cảnh báo Gatekeeper quá lớn sẽ làm người dùng sợ không dám tải; nếu giấu đi thì khi gặp lỗi người dùng sẽ bỏ cuộc. -> _Giải pháp_: Đặt dưới dạng Accordion / Callout mở rộng tinh tế, có tiêu đề thân thiện "Gặp thông báo Unidentified Developer khi mở app? (Gatekeeper)", giải thích bình tĩnh và đưa ra lệnh khắc phục trong 1 giây.

---

## 3. Scope Lock (MoSCoW)

- **Must-Have (P0)**:
  - Thẻ tải file `.dmg` trực tiếp với đầy đủ thông tin: Phiên bản mới nhất (`v1.3.1`), kiến trúc Universal Binary (Apple Silicon M1-M4 & Intel), yêu cầu hệ thống macOS 14.0+, giấy phép MIT.
  - Khung lệnh Terminal One-Line Installer với 2 tabs (`cURL` và `Homebrew`), nút Copy 1-click có hiệu ứng đổi trạng thái ("Copied!", icon checkmark xanh trong 2000ms).
  - Tuyên ngôn quyền riêng tư (Privacy Manifesto) 3 trụ cột: 100% Offline, Zero Telemetry / No Tracking, Giải thích quyền Accessibility `AXUIElement`.
  - Hướng dẫn vượt rào Gatekeeper dạng Accordion với câu lệnh `xattr -cr /Applications/FlowSnap.app` và nút 1-click copy riêng.
  - Bố cục thích ứng hoàn hảo trên Desktop (2 cột) và Mobile (< 768px, 1 cột xếp tầng).

- **Should-Have (P1)**:
  - Hiển thị mã băm SHA-256 Checksum mẫu hoặc link xác thực tính toàn vẹn gói cài đặt.
  - Liên kết xem Changelog / Release Notes chi tiết trên GitHub.

- **Won't-Have (Explicit Out-of-Scope)**:
  - Hệ thống đăng ký tài khoản, thu thập email khách hàng (trái với cam kết Zero Telemetry).
  - Giả lập máy ảo macOS đầy đủ trên trình duyệt (đã được bao hàm ở sandbox trực quan `US-WEB-026`).
  - Cổng thanh toán hoặc bản quyền thương mại (FlowSnap là phần mềm nguồn mở 100% miễn phí).
