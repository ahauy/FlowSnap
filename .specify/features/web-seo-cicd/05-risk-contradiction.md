# Risk & Contradiction Scan: FlowSnap SEO & GitHub Pages CI/CD (US-WEB-029)

> Feature Slug: `web-seo-cicd`  
> Domain Role: Business Analyst & Security/DevOps Architect

---

## 1. Contradiction & Edge-Case Scan

| Conflict / Edge Case                             | Risk Level | Root Cause                                                                                                              | Mitigation Strategy                                                                                                                                                                                     |
| :----------------------------------------------- | :--------- | :---------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Subpath Asset 404 on GitHub Pages**            | High       | Astro assets and links defaulting to root `/` instead of `/FlowSnap/` on project site.                                  | Khai báo `base: process.env.BASE_PATH ?? '/FlowSnap'` trong `astro.config.mjs` và sử dụng `import.meta.env.BASE_URL` để tiền tố hóa tất cả URL nội bộ, đồng thời hỗ trợ override khi cần custom domain. |
| **Social Bot Relative Image Rejection**          | High       | Trình thu thập của Twitter/Facebook/LinkedIn không tải được ảnh preview nếu dùng đường dẫn tương đối `/og-preview.png`. | Buộc giá trị `og:image` và `twitter:image` phải luôn là URL tuyệt đối (`https://ahauy.github.io/FlowSnap/og-preview.png`).                                                                              |
| **Deploying Broken Builds / Regressions**        | Medium     | Code commit bị lỗi nhưng CI/CD vẫn build và deploy đè lên production.                                                   | Bắt buộc thiết lập step `npm test` trong GitHub Actions; nếu bất kỳ unit test hoặc contract test nào fail, workflow lập tức dừng trước khi bước vào `astro build` và deploy.                            |
| **Telemetry / Third-Party Tracker Infiltration** | High       | Việc tích hợp SEO thường bị lạm dụng để chèn Google Analytics hoặc telemetry tag, vi phạm cam kết bảo mật.              | Tuân thủ tuyệt đối Tuyên ngôn Quyền riêng tư (US-WEB-028): 100% Zero Telemetry, không sử dụng Google Tag Manager hay bất kỳ tracker nào. Chỉ dùng thẻ SEO tĩnh và JSON-LD.                              |

---

## 2. Consolidated Assumptions Register (`ASM-`)

- `ASM-SEO-001`: Repo `ahauy/FlowSnap` sử dụng GitHub Pages triển khai từ artifact nguồn GitHub Actions.
- `ASM-SEO-002`: Schema JSON-LD thuộc loại `SoftwareApplication`, hệ điều hành `macOS 14.0+`.
- `ASM-SEO-003`: `robots.txt` cho phép toàn bộ crawler và trỏ trực tiếp tới `sitemap.xml`.
- `ASM-SEO-004`: `og-preview.png` là ảnh tĩnh độ phân giải 1200x630px được đặt trong `web/public/`.

---

## 3. MoSCoW Scope Boundary

### Must-Have (P0)

- Thẻ OpenGraph và Twitter Cards đầy đủ, đạt chuẩn hiển thị preview lớn (`summary_large_image`).
- Dữ liệu có cấu trúc `SoftwareApplication` JSON-LD Schema chuẩn Google Search Console.
- Tệp đồ họa mạng xã hội tĩnh `web/public/og-preview.png` kích thước chuẩn 1200x630 pixel, phong cách Obsidian tối giản.
- Tệp `robots.txt` và `sitemap.xml` hợp lệ trong `web/public/`.
- GitHub Actions workflow `.github/workflows/deploy-pages.yml` tự động test, build và deploy tĩnh lên GitHub Pages khi commit `main`.

### Should-Have (P1)

- Bộ test tự động `web/tests/seo-cicd.test.mjs` kiểm thử cú pháp tags, JSON-LD, sự hiện diện của tệp asset và cấu hình workflow.
- Hỗ trợ biến môi trường `BASE_PATH` để linh hoạt chuyển đổi giữa GitHub Pages subpath (`/FlowSnap`) và custom root domain (`/`).

### Could-Have (P2)

- Tự động sinh `sitemap.xml` theo thời gian build nếu bổ sung thêm các trang con.

### Won't-Have (Out-of-Scope)

- Server-side rendering (SSR) hoặc Node server runtime (trang web duy trì 100% Static HTML/CSS/JS).
- Bất kỳ mã theo dõi hoặc script phân tích hành vi của bên thứ ba (Google Analytics, Mixpanel, Hotjar) nhằm đảm bảo lời hứa "Zero Telemetry".
