# 05 — User Stories & Acceptance Scenarios — web-baseline-layout

> Feature: `US-WEB-025` (Astro Baseline, Shadcn Design Tokens & Base Responsive Layout)  
> Stage: Stage 6 (Spec Writer)

## US-WEB-025: Khung kiến trúc Astro, Shadcn Design Tokens & Base Responsive Layout

**Là một** khách truy cập trang web FlowSnap,  
**Tôi muốn** trang web tải tức thì (< 1s), giao diện đồng nhất chuẩn mực Apple HIG (hỗ trợ Dark/Light mode tự động) và không bị giật lag font (Zero FOIT/FOUT),  
**Để** tôi có được ấn tượng đầu tiên chuyên nghiệp, đẳng cấp và dễ dàng khám phá các tính năng quản lý cửa sổ của FlowSnap.

---

### Scenario 1: Initial Page Load with Zero FOUC & System Fonts (Happy Path)

- **Given** người dùng truy cập trang web lần đầu và hệ thống chưa lưu `flowsnap-theme` trong `localStorage`
- **When** trình duyệt tải trang HTML từ server tĩnh
- **Then** mã script inline tại `<head>` được thực thi đồng bộ trước khi render body
- **And** thuộc tính `data-theme` được gán chính xác (`dark` theo mặc định hoặc tương ứng với `prefers-color-scheme`)
- **And** toàn bộ văn bản hiển thị tức thì bằng system font stack (`SF Pro Display`, `SF Pro Text`, `Inter`) mà không có hiện tượng chớp font (Zero FOIT) hay chớp màu nền (Zero FOUC).

### Scenario 2: Theme Switching & Persistence (Happy Path)

- **Given** người dùng đang ở giao diện Dark mode (`data-theme="dark"`)
- **When** người dùng click vào nút `ThemeToggle` trên thanh Header
- **Then** thuộc tính `data-theme` trên thẻ `<html>` chuyển sang `"light"` tức thì
- **And** màu nền chuyển sang màu trắng `#ffffff` và màu chữ chuyển sang `#09090b` thông qua các biến CSS tokens
- **And** giá trị `'light'` được lưu vào `localStorage.setItem('flowsnap-theme', 'light')`
- **When** người dùng reload lại trang web
- **Then** trang web vẫn hiển thị trực tiếp ở giao diện Light mode mà không bị chớp đen.

### Scenario 3: Sticky Header & Anchor Navigation (Happy Path)

- **Given** trang web đang hiển thị và người dùng cuộn chuột xuống bên dưới
- **When** vị trí cuộn vượt quá chiều cao của thanh Header
- **Then** thanh Header vẫn bám dính ở cạnh trên cùng của màn hình (`position: sticky; top: 0`)
- **And** nền của Header hiển thị hiệu ứng mờ kính lỏng macOS (`backdrop-filter: blur(20px)`) và viền dưới hairline 1px
- **When** người dùng click vào một liên kết neo (ví dụ `#features`)
- **Then** trang web cuộn mượt mà (`scroll-behavior: smooth`) tới đúng phần tử có ID tương ứng
- **And** nội dung đầu mục không bị che lấp bởi thanh Header nhờ `scroll-margin-top: 80px`.

### Scenario 4: Professional Open-Source Footer (Happy Path)

- **Given** người dùng cuộn trang xuống cuối cùng
- **When** phần Footer hiển thị trên màn hình
- **Then** Footer cung cấp đầy đủ thông tin:
  - Thông báo bản quyền MIT License
  - Liên kết tác giả `@ahauy` trỏ tới `https://github.com/ahauy`
  - Liên kết mã nguồn trỏ tới repository `https://github.com/ahauy/FlowSnap`
  - Nhãn trạng thái kiến trúc ("Swift 6 • Zero Private APIs • Apple HIG Compliant").

### Scenario 5: Responsive Mobile Viewport (Edge Case)

- **Given** người dùng truy cập trang web từ thiết bị di động có chiều rộng màn hình `< 640px`
- **When** trang web render trên màn hình nhỏ
- **Then** layout tự động thích ứng: các liên kết neo dài trên header được ẩn hoặc thu gọn
- **And** logo FlowSnap, badge phiên bản, nút GitHub và nút ThemeToggle vẫn hiển thị đầy đủ và không bị đè lên nhau
- **And** trang web tuyệt đối không xuất hiện thanh cuộn ngang (Horizontal scrollbar).

### Scenario 6: LocalStorage Security/Privacy Restriction (Edge Case)

- **Given** người dùng mở trình duyệt ở chế độ ẩn danh hoặc chặn truy cập `localStorage` (`SecurityError`)
- **When** script khởi tạo hoặc nút `ThemeToggle` cố gắng đọc/ghi `localStorage`
- **Then** mã script bắt ngoại lệ qua khối `try...catch` an toàn
- **And** giao diện chuyển đổi theme tại chỗ (in-memory DOM update) mà không gây vỡ giao diện hay throw lỗi unhandled exception ra Console.
