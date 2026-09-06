# 01 — Elicitation Record (Stage 2) — web-baseline-layout

> Interview conducted on 2026-09-06 via interactive interview gate for US-WEB-025.
> Confirmed decisions: `ASM-WEB-001`, `ASM-WEB-002`, `ASM-WEB-003`.

## Confirmed Decisions

### ASM-WEB-001 — Theme Switching & Zero FOUC / FOIT Lifecycle

- **Decision**: Triển khai cơ chế chuyển đổi giao diện 2 trạng thái (Dark / Light) mượt mà, đảm bảo loại bỏ hoàn toàn hiện tượng chớp giật giao diện (Flash of Unstyled Content - FOUC):
  1. **Theme State**: 2 trạng thái `dark` và `light`.
  2. **Default Preference**: Mặc định là Obsidian Dark (`#09090b`) chuẩn phong cách developer macOS của FlowSnap. Nếu người dùng đã chọn theme trước đó, ưu tiên đọc từ `localStorage.getItem('flowsnap-theme')`. Nếu chưa có, tham chiếu `window.matchMedia('(prefers-color-scheme: dark)')`.
  3. **Zero FOUC Inline Script**: Một đoạn script nhỏ và đồng bộ được nhúng trực tiếp ngay đầu `<head>` của `BaseLayout.astro` để gán `document.documentElement.setAttribute('data-theme', theme)` và cập nhật class trước khi bất kỳ phần tử DOM nào được render.
  4. **Smooth Tactile Transition**: Nút toggle theme (`ThemeToggle.astro`) hiển thị biểu tượng Mặt trời / Mặt trăng với hiệu ứng chuyển đổi mượt mà (`cubic-bezier(0.16, 1, 0.3, 1)`), không gây layout shift.
- **Rationale**: Bảo toàn tính thẩm mỹ cao cấp của hệ thống thiết kế, loại bỏ trải nghiệm khó chịu khi màn hình bị chớp trắng/đen khi người dùng tải trang hoặc điều hướng.

### ASM-WEB-002 — Sticky Header Layout & Navigation Anchors

- **Decision**: Xây dựng thanh điều hướng Header cố định (Sticky Header) với đầy đủ các neo liên kết phục vụ toàn bộ cấu trúc trang Landing Page của Sprint 8:
  1. **Brand Identity**: Logo FlowSnap + Nhãn phiên bản phát hành hiện tại (`v1.3.1`) định dạng Pill bo tròn tinh tế.
  2. **Section Nav Anchors**: Bao gồm 4 mục neo cuộn mượt (smooth-scroll) tương ứng với các User Stories tiếp theo:
     - `#features` (Bento Grid Features Showcase — US-WEB-027)
     - `#showcase` (macOS Desktop Interactive Simulator — US-WEB-026)
     - `#shortcuts` (Interactive Shortcuts Matrix — US-WEB-027)
     - `#download` (Distribution Hub & Terminal Install — US-WEB-028)
  3. **Action Items**:
     - Nút GitHub Repo (`https://github.com/ahauy/FlowSnap`) kèm huy hiệu Stars widget.
     - Nút chuyển đổi giao diện (`ThemeToggle`).
  4. **Materiality & Positioning**: `position: sticky; top: 0; z-index: 50;`, hiệu ứng kính mờ macOS Liquid Glass (`backdrop-filter: blur(20px)`), viền dưới hairline 1px siêu mảnh (`var(--border-color)`).
- **Rationale**: Giúp khách truy cập dễ dàng điều hướng đến các phần trọng tâm của sản phẩm ngay trên một trang duy nhất mà không bị che khuất nội dung.

### ASM-WEB-003 — SEO, OpenGraph & Canonical Domain Baseline

- **Decision**: Thiết lập bộ thẻ siêu dữ liệu (Meta Tags) chuẩn SEO và OpenGraph cho đối tượng người dùng macOS và lập trình viên toàn cầu:
  1. **Primary Language**: Tiếng Anh (`en`) làm ngôn ngữ chính thức cho phiên bản web quốc tế.
  2. **Canonical Domain**: `https://ahauy.github.io/FlowSnap` (chuẩn GitHub Pages deployment của dự án).
  3. **Default Title**: `FlowSnap — macOS Window Manager with Intent & Snap Precision`.
  4. **Default Description**: `Native macOS window manager with Windows 11-style snap picker, multi-display intent restoration, Quake scratchpad, and zero private APIs.`
  5. **Social Metadata**: Thẻ `og:type="website"`, `og:title`, `og:description`, `og:url`, `og:image`, `twitter:card="summary_large_image"`, `twitter:title`, `twitter:description`.
- **Rationale**: Tối ưu hóa điểm số SEO Google Lighthouse (mục tiêu 95+), sẵn sàng cho quy trình CI/CD GitHub Pages ở US-WEB-029.

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Astro Static Architecture**: Sử dụng Astro v7 với chế độ build tĩnh (`output: 'static'`), baseline Zero-JS cho layout tĩnh.
- **Design Tokens & System Fonts**: Tuân thủ nghiêm ngặt bảng token trong `web/DESIGN.md` và `web/src/styles/design-tokens.css`, sử dụng system font stack (`SF Pro Display`, `SF Pro Text`, `SF Mono`).
- **Footer Structure**: Footer chuyên nghiệp chuẩn mực mã nguồn mở:
  - Thông tin bản quyền MIT License.
  - Liên kết tác giả `@ahauy` (`https://github.com/ahauy`).
  - Liên kết nhanh tới GitHub Releases, User Guides, và Issue Tracker.
- **Anti-AI-Slop Governance**: Tuyệt đối không sử dụng gradient lòe loẹt, floating neon orbs, hay hiệu ứng mờ kính quá đà gây giảm FPS.
