# Elicitation Interview Record: FlowSnap SEO, OpenGraph, JSON-LD & GitHub Pages CI/CD (US-WEB-029)

> Feature Slug: `web-seo-cicd`  
> Date: 2026-09-08  
> Interview Role: Business Analyst (BA)  
> Participant: Project Owner (User)

---

## 1. Interview Transcript & Confirmed Decisions

### Q1: Domain & Base Path Configuration for GitHub Pages

- **Question**: Bạn muốn cấu hình URL xuất bản trên GitHub Pages theo phương án nào?
- **Confirmed Decision**: Sử dụng `https://ahauy.github.io/FlowSnap/` làm canonical base URL, cấu hình `site: 'https://ahauy.github.io'` và `base: process.env.BASE_PATH ?? '/FlowSnap'` trong `astro.config.mjs`. Đảm bảo mọi đường dẫn nội bộ (assets, links, meta canonical) đều tương thích với subpath GitHub Pages mà không bị vỡ 404.
- **Reference Tag**: `DEC-SEO-001`

### Q2: Social Preview Card Asset (`og-preview.png`)

- **Question**: Bạn muốn thiết lập ảnh OpenGraph & Twitter Card (og-preview.png) như thế nào?
- **Confirmed Decision**: Tạo tệp đồ họa xã hội tĩnh độ phân giải cao 1200x630 (`web/public/og-preview.png`) đồng nhất với bảng màu Obsidian (`#09090b`), viền hairline 1px (`#ffffff14`), logo FlowSnap, biểu tượng cửa sổ đa bố cục snap, và tagline sản phẩm chính xác. Tệp này được phục vụ tĩnh, không phụ thuộc runtime, tối ưu hóa cho các crawler (Twitter, Facebook, Discord, Slack, iMessage).
- **Reference Tag**: `DEC-SEO-002`

### Q3: GitHub Actions CI/CD Trigger Scope & Pipeline

- **Question**: Phạm vi kích hoạt quy trình tự động hóa GitHub Actions (`.github/workflows/deploy-pages.yml`) nên được giới hạn ra sao?
- **Confirmed Decision**: Thiết lập workflow kích hoạt khi có lệnh `push` lên nhánh `main` với bộ lọc đường dẫn (`paths: ['web/**', '.github/workflows/deploy-pages.yml']`) kết hợp kích hoạt thủ công `workflow_dispatch`. Luồng pipeline thực thi: Thiết lập Node 22 -> `npm ci` (trong thư mục `web`) -> chạy toàn bộ test suite (`npm test`) -> build bản tĩnh (`npm run build`) -> upload artifact và deploy lên GitHub Pages qua `actions/deploy-pages@v4`.
- **Reference Tag**: `DEC-SEO-003`

---

## 2. Explicit Assumptions Register (ASM)

| Assumption ID | Description                                                                                                                                                                       | Impact Area         | Status    |
| :------------ | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------ | :-------- |
| `ASM-SEO-001` | GitHub repository `ahauy/FlowSnap` đã bật hoặc sẽ bật GitHub Pages với Source là "GitHub Actions".                                                                                | CI/CD Deployment    | Confirmed |
| `ASM-SEO-002` | Structured data sử dụng Schema.org `SoftwareApplication` với `operatingSystem: "macOS 14.0+"` và `applicationCategory: "UtilitiesApplication"`.                                   | Google Rich Snippet | Confirmed |
| `ASM-SEO-003` | File `robots.txt` cho phép toàn bộ crawler hợp lệ (`User-agent: *`, `Allow: /`) và trỏ tới `Sitemap: https://ahauy.github.io/FlowSnap/sitemap.xml`.                               | Search Crawling     | Confirmed |
| `ASM-SEO-004` | Social image URL trong thẻ OpenGraph/Twitter Card sử dụng absolute URL (`https://ahauy.github.io/FlowSnap/og-preview.png`) để đảm bảo các crawler bên ngoài nạp được ảnh preview. | Social Sharing      | Confirmed |
