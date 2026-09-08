# Elicitation Interview: Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto (US-WEB-028)

- **Feature**: US-WEB-028 (Distribution Hub, 1-Click Terminal Copy, DMG & Privacy Manifesto)
- **Date**: 2026-09-08
- **Participants**: Senior Business Analyst & Product Owner (User)
- **Status**: Completed & Confirmed

---

## 1. Interview Summary & Confirmed Decisions

### Q1: Định dạng lệnh cài đặt Terminal One-Line Installer

- **Confirmed Decision**: Cung cấp Tab toggle giữa 2 phương thức cài đặt phổ biến cho macOS power users:
  - **Tab 1 (Default / Recommended)**: `curl -fsSL https://raw.githubusercontent.com/ahauy/FlowSnap/main/install.sh | bash`
  - **Tab 2 (Homebrew Tap)**: `brew install --cask ahauy/tap/flowsnap`
- **Business Rationale**: Giúp mọi lập trình viên hoặc người dùng macOS có thể chọn công cụ quản lý package quen thuộc, giảm thiểu thời gian cài đặt xuống dưới 5 giây.
- **Traceability ID**: `DEC-DIST-001`

### Q2: Cấu trúc bố cục (Layout) của khu vực Distribution Hub (#download)

- **Confirmed Decision**: Bố cục 2 cột (Split View) trên Desktop, tự động chuyển thành cột đơn xếp tầng (Stacked) trên Mobile (< 768px):
  - **Cột Trái (Acquisition & CLI Engine)**: Thẻ Download DMG trực tiếp với huy hiệu phiên bản mới nhất, dung lượng, kiến trúc Universal Binary, cùng khung Terminal One-Line Installer có tab chuyển đổi curl / brew và nút Copy 1-click có animation phản hồi.
  - **Cột Phải (Trust, Transparency & Onboarding)**: Tuyên ngôn quyền riêng tư (Privacy Manifesto: 100% Offline, Zero Telemetry, Giải thích quyền Trợ năng `AXUIElement`) kết hợp cùng khối hướng dẫn giải tỏa rào cản macOS Gatekeeper.
- **Business Rationale**: Tạo sự cân bằng hoàn hảo giữa động lực tải app nhanh (Conversion) và xây dựng niềm tin tuyệt đối (Trust & Privacy) cho ứng dụng tiện ích hệ thống macOS.
- **Traceability ID**: `DEC-DIST-002`

### Q3: Hình thức hiển thị hướng dẫn giải quyết cảnh báo macOS Gatekeeper

- **Confirmed Decision**: Dạng Accordion mở rộng / Callout tinh tế có sẵn nút 1-click copy lệnh `xattr -cr /Applications/FlowSnap.app` ngay bên dưới khu vực tải DMG.
- **Business Rationale**: Tránh làm người dùng hoang mang khi macOS hiển thị cảnh báo "Unidentified Developer", cung cấp giải pháp kỹ thuật minh bạch, dễ hiểu và cho phép copy lệnh xử lý chỉ với 1 cú nhấp chuột.
- **Traceability ID**: `DEC-DIST-003`

---

## 2. Explicit Assumptions Register (`ASM-`)

- **ASM-DIST-001**: Bản phát hành mới nhất của FlowSnap trên GitHub Releases luôn có tệp nhị phân `.dmg` tại đường dẫn chuẩn `https://github.com/ahauy/FlowSnap/releases/latest/download/FlowSnap.dmg`.
- **ASM-DIST-002**: Lệnh `install.sh` trên GitHub repository sẽ tự động tải phiên bản DMG mới nhất, mount volume, sao chép `FlowSnap.app` vào thư mục `/Applications`, và unmount disk image an toàn.
- **ASM-DIST-003**: Clipboard API (`navigator.clipboard.writeText`) được hỗ trợ trên 100% trình duyệt hiện đại trên macOS (Safari, Chrome, Edge, Firefox), với fallback `document.execCommand('copy')` cho môi trường hạn chế quyền.
- **ASM-DIST-004**: Trạng thái copy sẽ duy trì phản hồi thị giác (đổi icon sang dấu tích xanh, hiển thị text "Copied!") trong đúng 2000ms trước khi quay lại trạng thái ban đầu.
