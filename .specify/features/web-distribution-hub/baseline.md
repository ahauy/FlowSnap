# Domain Baseline: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

- **Feature**: `web-distribution-hub` (US-WEB-028)
- **Version**: `SIGNED-OFF v1.0`
- **Author**: Senior Business Analyst & PO
- **Approved by**: User (PO Confirmation Gate 1)
- **Date**: 2026-09-08

---

## 1. Executive Summary & Problem Scope

FlowSnap cần một trung tâm phân phối cài đặt (Distribution Hub) trực quan, bảo mật và minh bạch trên trang chủ Web (`#download`), giúp người dùng chuyển đổi từ trải nghiệm tìm hiểu tính năng sang cài đặt ứng dụng thực tế trên macOS trong vòng dưới 10 giây.

Trung tâm phân phối giải quyết 3 điểm chạm cốt lõi:

1. **Acquisition & Dual-Mode Installation**: Cho phép tải trực tiếp file `.dmg` phổ thông hoặc sao chép lệnh Terminal One-Line (`curl` hoặc `brew`) bằng 1-click với phản hồi thị giác rõ ràng.
2. **Trust & Privacy Reassurance**: Xóa bỏ mọi e ngại về bảo mật khi cài tiện ích can thiệp cửa sổ bằng bản Tuyên ngôn Quyền riêng tư (100% Offline, Zero Telemetry, Giải thích minh bạch quyền Trợ năng `AXUIElement`).
3. **Frictionless Gatekeeper Bypass**: Hướng dẫn minh bạch và cung cấp nút copy 1-click cho lệnh `xattr -cr /Applications/FlowSnap.app` để vượt qua cảnh báo "Unidentified Developer" trên macOS Sequoia & Sonoma mà không gây hoang mang.

---

## 2. Settled Decisions & Traceability

- **DEC-DIST-001**: Khung Terminal hỗ trợ Tab toggle giữa 2 công cụ quen thuộc của macOS developers: `cURL` (mặc định) và `Homebrew Cask`.
- **DEC-DIST-002**: Bố cục 2 cột (Split View) cân xứng trên Desktop: Cột trái cho Download & Terminal Installer, Cột phải cho Privacy Manifesto & Gatekeeper Guidance; tự động chuyển sang 1 cột xếp tầng trên Mobile (< 768px).
- **DEC-DIST-003**: Hướng dẫn vượt rào Gatekeeper trình bày dạng Accordion mở rộng tinh tế với nút copy 1-click riêng biệt cho lệnh `xattr -cr /Applications/FlowSnap.app`.

---

## 3. Business Rules Index (`BR-DIST-###`)

- **BR-DIST-001**: Nút tải file `.dmg` liên kết trực tiếp tới `https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg` kèm thông số Universal Binary (Apple Silicon + Intel), dung lượng, và yêu cầu macOS 14.0+.
- **BR-DIST-002**: Khung Terminal hỗ trợ chuyển đổi mượt mà giữa lệnh `curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash` và `brew install --cask ahauy/tap/flowsnap`.
- **BR-DIST-003**: Nút Copy trên khung Terminal sao chép chính xác câu lệnh của tab đang kích hoạt (loại bỏ khoảng trắng thừa hoặc ký tự xuống dòng).
- **BR-DIST-004**: Hiệu ứng phản hồi copy chuyển nhãn sang "Copied!" và icon dấu tích trong đúng 2000ms.
- **BR-DIST-005**: Privacy Manifesto trình bày 3 trụ cột không khoan nhượng: 100% Offline, Zero Telemetry, và Trợ năng Trực quan (không bao giờ ghi nhận phím gõ).
- **BR-DIST-006**: Hướng dẫn Gatekeeper cung cấp lệnh chuẩn `xattr -cr /Applications/FlowSnap.app` có nút copy 1-click riêng.
- **BR-DIST-007**: Toàn bộ giao diện tuân thủ tuyệt đối Design Tokens từ `web/DESIGN.md`, không dùng gradient neon lòe loẹt (Anti-AI-Slop), đạt chuẩn WCAG 2.2 AA.

---

## 4. Acceptance Criteria & Handover to Speckit

| Roadmap AC Item                                                                                                      | Domain Specification Mapping   | Verification Method                              |
| :------------------------------------------------------------------------------------------------------------------- | :----------------------------- | :----------------------------------------------- |
| Khung lệnh Terminal One-Line Installer kèm nút Copy 1-click có phản hồi thị giác trực quan                           | `REQ-DIST-002`, `REQ-DIST-003` | Automated Playwright clipboard click test        |
| Nút tải file `.dmg` trực tiếp trỏ đến bản phát hành GitHub Releases mới nhất                                         | `REQ-DIST-001`                 | Automated link verification & download assertion |
| Cam kết bảo mật & quyền riêng tư rõ ràng: 100% Offline, Zero Telemetry, giải thích quyền Accessibility `AXUIElement` | `REQ-DIST-004`                 | DOM element & content assertion                  |
| Hướng dẫn khắc phục cảnh báo Gatekeeper (`xattr -cr`) minh bạch, chi tiết                                            | `REQ-DIST-005`                 | Accordion expand & copy command assertion        |
