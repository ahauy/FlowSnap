# Domain Baseline: Astro Baseline, Shadcn-Inspired Design Tokens & Base Layout (US-WEB-025)

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0 (Confirmation Gate 1 Approved)
- **Feature Slug**: `web-baseline-layout`
- **Related Roadmap Item**: `US-WEB-025` (EPIC 16 — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal)

---

## 1. Domain Summary

Xây dựng nền tảng khung kiến trúc web cho FlowSnap Landing Page trên nền tảng Astro Framework tĩnh (`web/`), tích hợp hệ thống design tokens cảm hứng từ Shadcn và Apple Human Interface Guidelines:

1. **Kiến trúc Tĩnh Siêu tốc & Zero-JS Baseline**:
   - Sử dụng Astro (v7.x, static output mode).
   - Tối ưu tải trang < 1s, Cumulative Layout Shift (CLS) = 0.
   - Sử dụng Native System Fonts (`SF Pro Display`, `SF Pro Text`, `SF Mono`), loại bỏ hoàn toàn hiện tượng chớp font (Zero FOIT/FOUT).
2. **Hệ Thống Chuyển Đổi Giao Diện Không Chớp Giật (Zero FOUC Theme Management — `BR-WEB-001`)**:
   - Hỗ trợ 2 chế độ Dark Mode (Obsidian `#09090b`) và Light Mode (`#ffffff`).
   - Khởi tạo theme đồng bộ qua inline blocking script trong `<head>`: tự động nhận diện `prefers-color-scheme` và ưu tiên `localStorage.getItem('flowsnap-theme')`.
   - Component `ThemeToggle.astro` chuyển đổi tức thì với đường cong chuyển động spring `cubic-bezier(0.16, 1, 0.3, 1)`.
3. **Thanh Điều Hướng Cố Định (Sticky Header — `BR-WEB-002`)**:
   - Cố định ở đỉnh màn hình (`position: sticky; top: 0; z-index: 50`), hiệu ứng kính mờ macOS Liquid Glass (`backdrop-filter: blur(20px)`), viền dưới hairline 1px siêu mảnh (`var(--border-color)`).
   - Bao gồm: Logo FlowSnap, badge phiên bản (`v1.3.1`), các neo cuộn trang mượt mà (`#features`, `#showcase`, `#shortcuts`, `#download`), nút GitHub repo với badge Stars, và nút chuyển đổi giao diện `ThemeToggle`.
   - Thiết lập `scroll-margin-top: 80px` trên toàn bộ các section đích để không bị che khuất nội dung khi nhảy neo.
4. **Chân Trang Chuẩn Mực Mã Nguồn Mở (Footer — `BR-WEB-004`)**:
   - Khẳng định bản quyền mã nguồn mở theo giấy phép MIT License.
   - Liên kết trực tiếp tới hồ sơ tác giả `@ahauy` (`https://github.com/ahauy`).
   - Liên kết tới Documentation, User Guides và GitHub Releases.
   - Nhãn tuyên ngôn chất lượng: "Swift 6 • Zero Private APIs • Apple HIG Compliant".
5. **Thích Ứng Màn Hình Đa Dạng (Responsive Layout — `BR-WEB-003`)**:
   - Co giãn mượt mà từ Mobile (< 640px) tới Ultra-wide (> 1200px), không bao giờ xuất hiện thanh cuộn ngang ngoài ý muốn.
   - Khung nội dung tối đa `1200px` căn giữa chuẩn mực.

---

## 2. Business Rules Reference

- **`BR-WEB-001`**: Zero-FOUC Theme Persistence — Blocking script tại `<head>` gán `data-theme` lên `<html>`, lưu trạng thái vào `localStorage` với fallback an toàn khi ở chế độ ẩn danh.
- **`BR-WEB-002`**: Sticky Navigation & Anchor Accessibility — Header dính ở đỉnh với backdrop blur 20px, viền hairline 1px, hỗ trợ cuộn mượt và bù trừ khoảng cách 80px.
- **`BR-WEB-003`**: Responsive Breakpoints & Viewport Constraints — Co giãn từ 320px đến 3840px không tràn ngang, co gọn nhãn menu trên mobile.
- **`BR-WEB-004`**: Open-Source Attribution & Transparency — Footer đầy đủ MIT License, link tác giả `@ahauy`, links mã nguồn và guides.

---

## 3. Assumptions Register

- **`ASM-WEB-001`**: Theme Switching & Zero FOUC / FOIT Lifecycle (2-state Dark/Light, default Obsidian Dark `#09090b`, localStorage persistence).
- **`ASM-WEB-002`**: Sticky Header Layout & Navigation Anchors (`#features`, `#showcase`, `#shortcuts`, `#download`, version badge `v1.3.1`, GitHub button, ThemeToggle).
- **`ASM-WEB-003`**: SEO, OpenGraph & Canonical Domain Baseline (English primary, canonical `https://ahauy.github.io/FlowSnap`, social cards).

---

## 4. Scope (MoSCoW)

- **Must-Have**:
  - `web/src/layouts/BaseLayout.astro` hoàn chỉnh với meta SEO, OpenGraph, anti-FOUC inline script, kết nối `design-tokens.css`.
  - `web/src/components/Header.astro` bám dính (sticky), mờ kính, viền hairline, logo, version badge, 4 neo cuộn, GitHub button, ThemeToggle.
  - `web/src/components/ThemeToggle.astro` chuyển đổi Dark/Light mode, lưu localStorage, icon SVG mượt mà.
  - `web/src/components/Footer.astro` với MIT License, link tác giả `@ahauy`, links guides/github.
  - Cập nhật `web/src/pages/index.astro` áp dụng `BaseLayout`, `Header`, `Footer` và placeholder container cho các section tiếp theo.
  - Đảm bảo lệnh `npm run build` trong `web/` biên dịch 100% không lỗi.
- **Should-Have**:
  - CSS rule `scroll-margin-top: 80px` cho các anchor sections.
  - Icon SVG sắc nét cho Sun / Moon với chuyển động vi mô tinh tế.
- **Won't-Have**:
  - ❌ Không dựng nội dung chi tiết của 3D sandbox (thuộc về `US-WEB-026`).
  - ❌ Không dựng chi tiết Bento Grid (thuộc về `US-WEB-027`).
  - ❌ Không dựng download hub và 1-click terminal copy (thuộc về `US-WEB-028`).
  - ❌ Không cài thêm các thư viện giao diện cồng kềnh (Tailwind/Bootstrap).
  - ❌ Không dùng gradient AI slop hay bóng neon mờ ảo.
