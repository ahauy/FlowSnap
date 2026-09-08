# Specification & User Stories: FlowSnap SEO, OpenGraph, JSON-LD & GitHub Pages CI/CD (US-WEB-029)

> Feature Slug: `web-seo-cicd`  
> Domain Role: Business Analyst & System Architect

---

## 1. System Requirements Specification (SRS)

### REQ-SEO-001: OpenGraph & Twitter Cards Meta Specification

- **Derived from**: `BR-SEO-001`, `DEC-SEO-002`
- **Description**: `BaseLayout.astro` phải phát sinh đầy đủ các thẻ meta xã hội:
  - OpenGraph: `og:title`, `og:description`, `og:url` (canonical), `og:image` (absolute URL), `og:image:width` (1200), `og:image:height` (630), `og:image:alt`, `og:type` (`website`), `og:site_name` (`FlowSnap`), `og:locale` (`en_US`).
  - Twitter Card: `twitter:card` (`summary_large_image`), `twitter:title`, `twitter:description`, `twitter:image` (absolute URL), `twitter:site` (`@ahauy`), `twitter:creator` (`@ahauy`).
- **Acceptance Verification**: Trình kiểm tra thẻ mạng xã hội nạp được preview đầy đủ hình ảnh, tiêu đề, mô tả và không xuất hiện cảnh báo thiếu thẻ bắt buộc.

### REQ-SEO-002: Schema.org `SoftwareApplication` JSON-LD Structured Data

- **Derived from**: `BR-SEO-002`, `ASM-SEO-002`
- **Description**: Bổ sung thẻ `<script type="application/ld+json">` chứa đối tượng JSON-LD biểu diễn `SoftwareApplication` với các trường:
  - `@context`: `"https://schema.org"`
  - `@type`: `"SoftwareApplication"`
  - `name`: `"FlowSnap"`
  - `operatingSystem`: `"macOS 14.0+"`
  - `applicationCategory`: `"UtilitiesApplication"`
  - `description`: Mô tả chuẩn xác về tính năng quản lý cửa sổ snap của FlowSnap.
  - `url`: `"https://ahauy.github.io/FlowSnap"`
  - `downloadUrl`: Liên kết tới trang tải GitHub Releases.
  - `offers`: Đối tượng `Offer` có `price`: `"0"`, `priceCurrency`: `"USD"`.
  - `author`: Đối tượng `Person` hoặc `Organization` với tên `"ahauy"`.
- **Acceptance Verification**: JSON-LD hợp lệ khi kiểm thử cú pháp qua Google Rich Results Test / schema validator.

### REQ-SEO-003: High-Resolution Social Preview Card Asset

- **Derived from**: `BR-SEO-005`, `DEC-SEO-002`
- **Description**: Tạo tệp đồ họa tĩnh `web/public/og-preview.png` tỷ lệ 1200x630px, thiết kế theo ngôn ngữ Obsidian của FlowSnap, thể hiện logo, badge macOS Native, sơ đồ cửa sổ snap và số liệu kiểm chứng (470+ tests, < 1ms, 0 Private APIs).
- **Acceptance Verification**: Tệp tồn tại ở `web/public/og-preview.png`, kích thước chính xác 1200x630 pixel, dung lượng tối ưu (< 500KB).

### REQ-SEO-004: Robots Directive & XML Sitemap

- **Derived from**: `BR-SEO-006`, `ASM-SEO-003`
- **Description**: Tạo `web/public/robots.txt` cho phép mọi bot hợp lệ thu thập dữ liệu và trỏ tới sitemap:
  ```txt
  User-agent: *
  Allow: /
  Sitemap: https://ahauy.github.io/FlowSnap/sitemap.xml
  ```
  Tạo `web/public/sitemap.xml` khai báo URL canonical của FlowSnap kèm `priority: 1.0` và `changefreq: weekly`.
- **Acceptance Verification**: Cả 2 file có thể truy cập được từ root web và có nội dung chuẩn định dạng.

### REQ-SEO-005: Automated GitHub Pages CI/CD Pipeline

- **Derived from**: `BR-SEO-004`, `DEC-SEO-003`
- **Description**: Tạo tệp `.github/workflows/deploy-pages.yml` cấu hình GitHub Actions:
  - Trigger: `push` tới nhánh `main` với path filter `web/**` và `.github/workflows/deploy-pages.yml`, cùng trigger `workflow_dispatch`.
  - Quyền: `contents: read`, `pages: write`, `id-token: write`.
  - Concurrency: Group `"pages"` với `cancel-in-progress: false`.
  - Các bước thực thi:
    1. Checkout repository.
    2. Setup Node.js v22 với cache npm.
    3. `npm ci` (trong thư mục `web`).
    4. `npm test` (chạy toàn bộ test suites của web).
    5. `npm run build` (build tĩnh Astro).
    6. `actions/configure-pages@v5`.
    7. `actions/upload-pages-artifact@v3` (đường dẫn: `web/dist`).
    8. `actions/deploy-pages@v4`.
- **Acceptance Verification**: Tệp YAML tuân thủ đúng cú pháp GitHub Actions và vượt qua kiểm tra định dạng cú pháp tự động.

### REQ-SEO-006: Subpath & Base URL Compatibility

- **Derived from**: `BR-SEO-003`, `DEC-SEO-001`
- **Description**: Cập nhật `web/astro.config.mjs` thiết lập `site: 'https://ahauy.github.io'` và `base: process.env.BASE_PATH ?? '/FlowSnap'`. Cập nhật các liên kết và tài nguyên nội bộ để hỗ trợ chạy đúng cả khi ở subpath `/FlowSnap` lẫn root `/`.
- **Acceptance Verification**: `npm run build` hoàn thành thành công và xuất thư mục `dist` với các tài nguyên được liên kết đúng.

---

## 2. User Stories (US)

### US-SEO-001: Google Search Rich Snippet & Crawler Discovery

- **As a**: Nhà phát triển dự án và khách tìm kiếm trên Google,
- **I want**: Trang web cung cấp đầy đủ dữ liệu cấu trúc Schema.org và sitemap chuẩn,
- **So that**: Google Search hiển thị Rich Snippet ứng dụng phần mềm trực quan với tên, hệ điều hành hỗ trợ (macOS 14.0+) và giá miễn phí.
- **Scenario 1 (Given-When-Then - Valid JSON-LD)**:
  - **Given**: Googlebot hoặc trình kiểm tra dữ liệu cấu trúc truy cập `https://ahauy.github.io/FlowSnap`.
  - **When**: Trình thu thập đọc khối `<script type="application/ld+json">`.
  - **Then**: Trả về dữ liệu hợp lệ chứa `@type: SoftwareApplication`, `operatingSystem: macOS 14.0+`, `price: 0`, và URL tải hợp lệ.
- **Scenario 2 (Given-When-Then - Robots & Sitemap)**:
  - **Given**: Web crawler yêu cầu `/robots.txt`.
  - **When**: Đọc nội dung tệp.
  - **Then**: Nhận chỉ thị `Allow: /` và liên kết chính xác tới `/sitemap.xml`.

### US-SEO-002: Social Sharing with High-Resolution Visual Card

- **As a**: Người dùng chia sẻ đường dẫn FlowSnap trên mạng xã hội (Twitter/X, Facebook, Slack, iMessage),
- **I want**: Thẻ xem trước hiển thị ảnh preview 1200x630 chất lượng cao cùng tiêu đề và mô tả chuyên nghiệp,
- **So that**: Bài đăng thu hút sự chú ý và phản ánh đúng giá trị ứng dụng cao cấp.
- **Scenario 1 (Given-When-Then - OpenGraph Absolute Addressing)**:
  - **Given**: Người dùng paste link `https://ahauy.github.io/FlowSnap` vào Twitter hoặc Slack.
  - **When**: Nền tảng phân tích các thẻ meta trong `<head>`.
  - **Then**: Đọc được `og:image` có URL tuyệt đối trỏ tới `og-preview.png`, `twitter:card` là `summary_large_image`, và kích thước `1200x630`.

### US-SEO-003: Automated Test-Gated GitHub Pages Deployment

- **As a**: Kỹ sư bảo trì dự án FlowSnap,
- **I want**: Mỗi khi merge code vào nhánh `main`, hệ thống tự động kiểm thử và xuất bản lên GitHub Pages,
- **So that**: Tôi không phải build và deploy thủ công, đồng thời ngăn chặn deploy bản build lỗi.
- **Scenario 1 (Given-When-Then - Passing Test Pipeline)**:
  - **Given**: Commit mới được push lên nhánh `main` chạm vào thư mục `web/**`.
  - **When**: GitHub Actions chạy workflow `.github/workflows/deploy-pages.yml`.
  - **Then**: Chạy `npm test` thành công, sau đó tiến hành build và deploy lên GitHub Pages mà không gặp lỗi.
- **Scenario 2 (Given-When-Then - Test Failure Gate)**:
  - **Given**: Một đoạn code web bị lỗi khiến `npm test` thất bại.
  - **When**: GitHub Actions thực thi step `npm test`.
  - **Then**: Workflow dừng ngay lập tức và không thực thi deploy.
