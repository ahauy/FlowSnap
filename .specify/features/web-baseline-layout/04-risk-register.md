# 04 — Risk Register & Scope Lock — web-baseline-layout

> Feature: `US-WEB-025` (Astro Baseline, Shadcn Design Tokens & Base Responsive Layout)  
> Stage: Stage 5 (Risk & Contradiction Scanner)

## 1. Risk Register

| Risk ID          | Description                                                                                        | Severity | Probability | Mitigation Strategy                                                                                                                                                                     |
| :--------------- | :------------------------------------------------------------------------------------------------- | :------- | :---------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-WEB-001** | Flash of Unstyled Content (FOUC) khi tải trang nếu script đọc theme chạy bất đồng bộ               | High     | High        | Nhúng trực tiếp đoạn mã script inline đồng bộ ở đỉnh của thẻ `<head>` trong `BaseLayout.astro`. Thiết lập mặc định thuộc tính `data-theme="dark"` tĩnh trên `<html>` trước khi hydrate. |
| **RISK-WEB-002** | Hiện tượng chuyển động màu nền (transition flicker) giật lag ngay khi trang vừa tải xong           | Medium   | Medium      | Chỉ kích hoạt thuộc tính `transition` trên CSS sau khi trang đã render xong (hoặc chỉ áp dụng transition trên hành vi click người dùng, không áp dụng transition trên initial mount).   |
| **RISK-WEB-003** | Tràn nội dung hoặc vỡ dòng thanh điều hướng trên màn hình di động hẹp (< 380px)                    | Medium   | High        | Thiết lập `@media (max-width: 640px)` ẩn các liên kết chữ chi tiết, ưu tiên giữ logo, badge phiên bản nhỏ, nút GitHub và nút ThemeToggle.                                               |
| **RISK-WEB-004** | Nhảy neo trang (`#features`, `#showcase`) bị che lấp một phần bởi Sticky Header có chiều cao ~64px | High     | High        | Thiết lập quy tắc CSS toàn cục: `section[id] { scroll-margin-top: 80px; }` để nội dung cuộn dừng chính xác bên dưới thanh Header.                                                       |

---

## 2. Consolidated Assumptions (ASM-)

- **`ASM-WEB-001`**: Cơ chế chuyển đổi giao diện 2 trạng thái (Dark / Light) lưu tại `localStorage` với khóa `'flowsnap-theme'`, mặc định Dark Obsidian (`#09090b`), loại bỏ triệt để FOUC bằng inline blocking script trong `<head>`.
- **`ASM-WEB-002`**: Thanh điều hướng dính (Sticky Header) với logo FlowSnap, badge `v1.3.1`, 4 neo cuộn `#features`, `#showcase`, `#shortcuts`, `#download`, nút GitHub Stars, và nút ThemeToggle.
- **`ASM-WEB-003`**: Bộ thẻ chuẩn SEO và OpenGraph cho đối tượng quốc tế bằng Tiếng Anh (`en`), canonical URL trỏ về `https://ahauy.github.io/FlowSnap`.

---

## 3. MoSCoW Scope Lock

### Must-Have (Bắt buộc phải có)

- Khởi tạo khung `BaseLayout.astro` với thẻ SEO, favicon, meta OpenGraph/Twitter Cards và tích hợp `web/src/styles/design-tokens.css`.
- Cơ chế chống chớp sáng/tối (Zero FOUC) bằng inline blocking script.
- Component `Header.astro` cố định (sticky), nền mờ kính lỏng macOS (`backdrop-filter: blur(20px)`), viền hairline 1px.
- Component `Footer.astro` với thông tin bản quyền MIT, tác giả `@ahauy`, liên kết tài liệu.
- Component `ThemeToggle.astro` chuyển đổi Dark/Light mode tức thì.
- Trang `index.astro` tích hợp `BaseLayout`, `Header`, và `Footer`, chạy build `astro build` không lỗi.

### Should-Have (Nên có)

- Biểu tượng SVG vector sắc nét cho Sun / Moon với hiệu ứng xoay nhẹ khi click.
- Thẻ neo có thuộc tính `scroll-margin-top` chống che khuất nội dung.

### Could-Have (Có thể cân nhắc sau)

- Dynamic GitHub Stars fetcher qua GitHub Public API (giữ static link/badge ở baseline để tránh rate limit API).

### Won't-Have (Tuyệt đối không làm trong phạm vi US-WEB-025)

- Không triển khai các section nội dung chi tiết của Bento Grid hay 3D Simulator (thuộc về US-WEB-026 và US-WEB-027).
- Không thêm các thư viện CSS nặng (Tailwind, Bootstrap) làm phình to bundle.
- Không sử dụng các gradient AI slop lòe loẹt hoặc neon blobs.
