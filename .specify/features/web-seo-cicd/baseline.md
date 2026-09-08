# Domain Baseline: SEO, OpenGraph, JSON-LD Schema & GitHub Pages CI/CD (US-WEB-029)

- **Feature**: `web-seo-cicd` (US-WEB-029)
- **Version**: `SIGNED-OFF v1.0`
- **Author**: Senior Business Analyst & PO
- **Approved by**: User (PO Confirmation Gate 1 Signed-Off)
- **Date**: 2026-09-08

---

## 1. Executive Summary & Problem Scope

FlowSnap cần một giải pháp SEO và tự động hóa xuất bản toàn diện cho trang landing page tĩnh trên Web (`web/`):

1. **Search Discovery & Rich Results**: Dữ liệu có cấu trúc `SoftwareApplication` JSON-LD giúp Google Search nhận diện chính xác ứng dụng tiện ích macOS 14.0+, hiển thị Rich Snippets (giá 0$, bản quyền mã nguồn mở, danh mục Utilities).
2. **Social Card Sharing (OpenGraph & Twitter)**: Thẻ xem trước mạng xã hội với URL ảnh tuyệt đối trỏ tới `web/public/og-preview.png` (1200x630 pixel) chất lượng cao, định dạng `summary_large_image`, thể hiện rõ ràng định vị thương hiệu và giá trị cốt lõi.
3. **Automated Zero-Friction CI/CD**: Workflow GitHub Actions `.github/workflows/deploy-pages.yml` tự động chạy test suite của web, build tĩnh với cấu hình subpath `base: '/FlowSnap'`, và deploy lên GitHub Pages mỗi khi có commit mới trên nhánh `main` chạm vào `web/**`.
4. **Crawling Integrity**: Tệp `robots.txt` và `sitemap.xml` hợp lệ để các công cụ tìm kiếm thu thập thông tin trơn tru.

---

## 2. Settled Decisions & Traceability

- **DEC-SEO-001**: Cấu hình `astro.config.mjs` với `site: 'https://ahauy.github.io'` và `base: process.env.BASE_PATH ?? '/FlowSnap'`, hỗ trợ biến môi trường `BASE_PATH` khi chuyển sang custom domain.
- **DEC-SEO-002**: Tạo ảnh tĩnh độ phân giải cao `web/public/og-preview.png` (1200x630px) theo chuẩn Apple HIG & Obsidian dark canvas, viền hairline 1px.
- **DEC-SEO-003**: Workflow GitHub Actions triển khai theo cơ chế test-gated: `npm test` -> `npm run build` -> `actions/deploy-pages@v4`, kích hoạt khi có push vào `main` cho các file thuộc `web/**` hoặc file workflow, kèm `workflow_dispatch`.

---

## 3. Business Rules Index (`BR-SEO-###`)

- **BR-SEO-001**: Toàn bộ thuộc tính `og:image`, `twitter:image` và canonical URL phải là URL tuyệt đối (`https://ahauy.github.io/FlowSnap/...`).
- **BR-SEO-002**: JSON-LD Schema tuân thủ cấu trúc Schema.org `SoftwareApplication` với `operatingSystem: "macOS 14.0+"`, `applicationCategory: "UtilitiesApplication"`, `offers.price: "0"`.
- **BR-SEO-003**: Cấu hình `base` và `site` trong `astro.config.mjs` đảm bảo không xảy ra lỗi 404 cho tài nguyên tĩnh trên GitHub Pages subpath.
- **BR-SEO-004**: CI/CD bắt buộc chạy `npm test` thành công trước khi tiến hành build và upload artifact lên GitHub Pages.
- **BR-SEO-005**: Ảnh xem trước mạng xã hội bám sát ngôn ngữ thiết kế Obsidian, không dùng gradient neon AI-slop.
- **BR-SEO-006**: Tệp `robots.txt` cho phép toàn bộ crawler và trỏ tới `sitemap.xml`.

---

## 4. Acceptance Criteria & Handover to Speckit

| Roadmap AC Item                                                                                                                                 | Domain Specification Mapping       | Verification Method                              |
| :---------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------- | :----------------------------------------------- |
| Thẻ OpenGraph / Twitter Cards chuẩn mực với ảnh preview chất lượng cao                                                                          | `REQ-SEO-001`, `REQ-SEO-003`       | Automated meta tag & asset dimension test        |
| Dữ liệu có cấu trúc `SoftwareApplication` JSON-LD Schema chuẩn Google Search                                                                    | `REQ-SEO-002`                      | Automated JSON-LD parse & schema validation test |
| Thiết lập GitHub Actions workflow `.github/workflows/deploy-pages.yml` để build và deploy tĩnh lên GitHub Pages mỗi khi commit lên nhánh `main` | `REQ-SEO-005`, `REQ-SEO-006`       | YAML syntax check & CI step simulation test      |
| Điểm số Google Lighthouse đạt tối thiểu `95+` trên cả 4 hạng mục: Performance, Accessibility, Best Practices, SEO                               | `REQ-SEO-001`, `REQ-SEO-004`, NFRs | HTML semantic audit & asset optimization test    |
