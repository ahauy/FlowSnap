---
project: "<Project Name>"
tech-stack:
  language: "<e.g. TypeScript>"
  backend: "<e.g. NestJS + Prisma ORM>"
  frontend: "<e.g. Next.js 15 App Router + Zustand>"
  database: "<e.g. PostgreSQL 16>"
  infra: "<e.g. Docker Compose (local) / Koyeb + Vercel + Neon (prod)>"
  test: "<e.g. Vitest + Playwright>"
git-mode: "team" # team | local | stealth | hybrid
schema-version: "1.2"
---

# 🗺️ Product Backlog & Execution Roadmap

> **Sản phẩm:** `<Product Name>` — `<One-sentence description>`  
> **Cập nhật lần cuối:** `<YYYY-MM-DD>`  
> **Trạng thái tài liệu:** Living Document — Quản lý tiến độ và đồng bộ với `/command-continue-project`
>
> **Ký hiệu trạng thái:**
>
> - `[x]` **Hoàn thành (Done)** — Đã hoàn thiện code, test pass và tài liệu kỹ thuật/hướng dẫn đầy đủ.
> - `[/]` **Đang triển khai (In Progress)** — `/continue` sẽ ưu tiên tiếp tục xử lý cho xong.
> - `[ ]` **Chưa triển khai (To Do / Backlog)** — Đã có đặc tả, sẵn sàng bốc theo thứ tự từ trên xuống.
> - `[!]` **Bị chặn / Cần làm rõ (Blocked / Review Needed)** — Cần quyết định kiến trúc hoặc phụ thuộc module khác; `/continue` sẽ dừng lại cảnh báo và đề xuất phiên `grilling` để tháo gỡ điểm nghẽn.
> - `[~]` **Dự kiến dài hạn (Deferred / Future Phase)** — Tính năng đã ghi nhận nhưng chủ động hoãn lại sang phiên bản sau.

---

## 🚫 Explicitly Out of Scope — Won't-Have for MVP

> **CRITICAL:** Phần này là "scope fence" bắt buộc. Thiếu Won't-Have → AI BA sẽ hallucinate scope.
> Xóa gạch đầu dòng nào không áp dụng, thêm các điểm đặc thù của dự án bạn.

- **NO** mobile native app (iOS/Android) — Web-only for MVP.
- **NO** offline mode / local-first sync.
- **NO** enterprise SSO (SAML/LDAP/Active Directory).
- **NO** billing or payment integration.
- **NO** multi-tenancy with data isolation.
- **NO** real-time collaborative editing (e.g. Google Docs style).
- **NO** `<thêm điểm Won't-Have đặc thù>`

---

## 📊 Bảng Ma Trận Ưu Tiên MoSCoW & RICE Score

| Mã Epic     | Nghiệp vụ / Tính năng                               |  Phân loại MoSCoW   | RICE Score |    Mức ưu tiên    | Sprint khuyến nghị |
| :---------- | :-------------------------------------------------- | :-----------------: | :--------: | :---------------: | :----------------: |
| **EPIC-01** | `<Tên Epic 1 — e.g. Auth & User Profile>`           |    **Must Have**    |    9.0     | **P0 (Critical)** |      Sprint 1      |
| **EPIC-02** | `<Tên Epic 2 — e.g. Core Domain CRUD>`              |    **Must Have**    |    8.5     | **P0 (Core USP)** |      Sprint 1      |
| **EPIC-03** | `<Tên Epic 3 — e.g. Advanced Interaction / Engine>` |   **Should Have**   |    7.5     |   **P1 (High)**   |      Sprint 2      |
| **EPIC-04** | `<Tên Epic 4 — e.g. Analytics / Export>`            |   **Could Have**    |    6.0     |  **P2 (Medium)**  |      Sprint 2      |
| **EPIC-05** | `<Tên Epic 5 — e.g. Mobile PWA / Extensions>`       | **Won't Have (v1)** |    4.5     | **P3 (Phase 2)**  | Sprint 3 / Future  |

---

## 🗺️ Lộ Trình Phát Hành (Release Roadmap)

```text
[ Sprint 0 - Setup & Architecture ] ──► [ COMPLETED ✅ ]
  ├── SETUP-001: Khởi tạo repo, cấu hình `.agents/`, `.specify/`, Git mode
  ├── SETUP-002: Thiết lập Docker Compose / Dev environment
  └── SETUP-003: Cấu hình CI/CD pipeline

[ Sprint 1 - Core Foundation (MVP) ] ──► [ IN PROGRESS 🔄 ]
  ├── US-<MOD>-001: <Tiêu đề Story 1>
  ├── US-<MOD>-002: <Tiêu đề Story 2>
  └── US-<MOD>-003: <Tiêu đề Story 3>

[ Sprint 2 - Feature Expansion ] ──► [ TO DO 📋 ]
  ├── US-<MOD>-004: <Tiêu đề Story 4>
  └── US-<MOD>-005: <Tiêu đề Story 5>

[ Sprint 3 - Production Hardening & Go-Live ] ──► [ GO-LIVE 🚀 ]
  ├── US-DEPLOY-01: Security Hardening (Pre-Deploy)
  ├── US-DEPLOY-02: Cloud Database Setup & Migration
  ├── US-DEPLOY-03: Backend API Deployment & Health Check
  ├── US-DEPLOY-04: Frontend SPA Deployment & Routing Fallback
  └── US-DEPLOY-05: End-to-End Smoke Test Production URL
```

---

## ⚙️ Sprint 0: Project Setup & Architecture (Không phải User Story)

> Sprint 0 là công việc setup một lần, không cần BA pipeline.  
> Dùng Micro-Task Fast-Track: Reproduce → Fix → Verify → Commit.

- [x] **SETUP-001**: Khởi tạo repo, cấu hình `.agents/`, `.specify/`, Git mode
- [x] **SETUP-002**: Thiết lập Docker Compose / Dev environment
- [x] **SETUP-003**: Cấu hình CI/CD pipeline (GitHub Actions / Cloud)

---

## 🎯 Sprint 1: `<Tên Sprint — Mục Tiêu MVP>`

> **Mục tiêu Sprint:** `<Một câu mô tả kết quả kinh doanh khi Sprint hoàn thành.>`

- [ ] **US-`<MOD>`-001**: `<Tiêu đề User Story — Động từ + Danh từ>`
  - **Slug:** `<kebab-case-slug>`
  - **Effort:** S <!-- S | M | L | XL — dùng cho auto-routing của /continue -->
  - **Context-budget:** single-session <!-- single-session | multi-session -->
  - **Priority:** Must-Have (P0) <!-- Must-Have P0 | Should-Have P1 | Could-Have P2 | Won't-Have -->
  - **Depends-on:** _(none)_ <!-- US-XXX-NNN hoặc _(none)_ -->
  - **Blocks:** `US-<MOD>-002` <!-- Các US bị chặn nếu story này chưa [x] -->
  - **Mô tả:** `<1-2 câu mô tả value cho người dùng. Không mô tả kỹ thuật.>`
  - **Acceptance Criteria (AC):**
    - [ ] `<AC 1: Điều kiện kiểm thử được, có thể pass/fail rõ ràng>`
    - [ ] `<AC 2>`
    - [ ] `<AC 3>`
  - **Tasks (Phân rã kỹ thuật cho Subagents):**
    - [ ] **Backend:** `<Endpoint / DTO / Service logic / Database migration>`
    - [ ] **Frontend:** `<Component / Page / State store / UI Modal / Form validation>`
  - **Deliverables khi [x]:**
    - `.specify/features/<slug>/baseline.md` (SIGNED-OFF)
    - `docs/features/<slug>/README.md`
    - `docs/user-guides/<slug>.md` (với ảnh Playwright thật)

- [ ] **US-`<MOD>`-002**: `<Tiêu đề User Story>`
  - **Slug:** `<kebab-case-slug>`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-<MOD>-001`
  - **Blocks:** `US-<MOD>-003`
  - **Mô tả:** `<...>`
  - **Acceptance Criteria (AC):**
    - [ ] `<AC 1>`
    - [ ] `<AC 2>`
  - **Tasks (Phân rã kỹ thuật cho Subagents):**
    - [ ] **Backend:** `<...>`
    - [ ] **Frontend:** `<...>`
  - **Deliverables khi [x]:**
    - `.specify/features/<slug>/baseline.md` (SIGNED-OFF)
    - `docs/features/<slug>/README.md`

- [ ] **US-`<MOD>`-003**: `<Tiêu đề User Story>`
  - **Slug:** `<kebab-case-slug>`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-<MOD>-002`
  - **Blocks:** _(none)_
  - **Mô tả:** `<...>`
  - **Acceptance Criteria (AC):**
    - [ ] `<AC 1>`
    - [ ] `<AC 2>`
  - **Tasks (Phân rã kỹ thuật cho Subagents):**
    - [ ] **Backend:** `<...>`
    - [ ] **Frontend:** `<...>`
  - **Deliverables khi [x]:**
    - `.specify/features/<slug>/baseline.md` (SIGNED-OFF)
    - `docs/features/<slug>/README.md`

---

## 🚀 Sprint 2: `<Tên Sprint 2>`

> **Mục tiêu Sprint:** `<...>`

- [ ] **US-`<MOD>`-004**: `<Tiêu đề User Story>`
  - **Slug:** `<kebab-case-slug>`
  - **Effort:** L
  - **Context-budget:** multi-session <!-- L/XL nên là multi-session — /continue sẽ gọi wayfinder trước -->
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-<MOD>-001`
  - **Blocks:** _(none)_
  - **Mô tả:** `<...>`
  - **Acceptance Criteria (AC):**
    - [ ] `<AC 1>`
  - **Tasks (Phân rã kỹ thuật cho Subagents):**
    - [ ] **Backend:** `<...>`
    - [ ] **Frontend:** `<...>`
  - **Deliverables khi [x]:**
    - `.specify/features/<slug>/baseline.md` (SIGNED-OFF)
    - `docs/features/<slug>/README.md`

---

## 🔮 Backlog Dự Kiến — Future Horizons (V2.0+)

> Các ý tưởng chưa được ưu tiên. Không có Slug, không có AC — chỉ là placeholder.  
> Khi quyết định làm, chuyển vào Sprint tương ứng và điền đầy đủ thông tin.

- [~] **US-FUTURE-001**: `<Tên tính năng tương lai 1>`
- [~] **US-FUTURE-002**: `<Tên tính năng tương lai 2>`

---

## 🏁 Quy Chuẩn Định Nghĩa Hoàn Thành (Definition of Done - DoD)

Một User Story / Task chỉ được chuyển trạng thái từ `[/]` sang `[x]` khi đáp ứng đủ các tiêu chí:

1. **Nghiệp vụ (Business Acceptance):** Đạt 100% các điều kiện trong Acceptance Criteria (AC).
2. **Kiểm thử tự động (Automated Tests):**
   - Backend: Có Unit/Integration Test cho Controller, Service, DB queries.
   - Frontend: Component render chuẩn, tương tác state mượt mà, không console error.
3. **Chất lượng mã nguồn (Code Quality Gate):**
   - Tuân thủ quy chuẩn kiến trúc (`File < 800 dòng, Function < 50 dòng, Immutable data patterns`).
   - Đã kiểm tra qua các stack skills phù hợp trong `.agents/skills/engineering/`.
4. **Không có lỗi nghiêm trọng (Bug Severity Gate):** Zero Critical / Blocker bugs.
5. **Tài liệu hóa:** Cập nhật `docs/features/<slug>/README.md` và user guide kèm ảnh chụp thực tế.

---

## 🚀 Kế Hoạch Phát Hành Production (Go-Live Plan)

### 1. Pre-Deploy Checklist (Bắt buộc trước khi Go-Live)

#### 🔴 Critical — Blockers tuyệt đối

- [ ] **SEC-01**: Loại bỏ toàn bộ credentials / secrets hardcoded; chuyển sang biến môi trường (`.env`).
- [ ] **SEC-02**: Sinh JWT Secret mạnh: `openssl rand -hex 64` (không dùng secret mặc định).
- [ ] **SEC-03**: Cấu hình CORS whitelist chỉ cho phép domain Frontend thực tế (không dùng `*` trên production).

#### 🟡 Important — Hoàn thành trước ngày mở cho người dùng

- [ ] **DB-01**: Khởi tạo Cloud Database (PostgreSQL Serverless) và chạy migration an toàn (`prisma migrate deploy`).
- [ ] **API-01**: Deploy Backend service container / serverless; kiểm tra health check endpoint trả về HTTP 200.
- [ ] **WEB-01**: Deploy Frontend SPA / Next.js; kiểm tra cấu hình SPA routing fallback (refresh trang con không bị 404).
- [ ] **TEST-01**: Chạy Playwright smoke test toàn bộ happy path trên URL production thực tế.

#### 🟢 Nice-to-have — Sau khi Go-Live

- [ ] **OBS-01**: Tích hợp Error Monitoring (Sentry / Log drain) để bắt runtime exceptions.
- [ ] **OBS-02**: Cấu hình Uptime Monitoring cảnh báo khi server gặp sự cố.

### 2. Biến Môi Trường Production Mẫu (.env Template)

```bash
# ── Backend Service ──────────────────────────────────────────
NODE_ENV=production
PORT=3000
DATABASE_URL="postgresql://<user>:<password>@<host>/<database>?sslmode=require"
JWT_SECRET="<openssl rand -hex 64>"
JWT_EXPIRES_IN="15m"
JWT_REFRESH_SECRET="<openssl rand -hex 64>"
JWT_REFRESH_EXPIRES_IN="7d"
CORS_ORIGINS="https://<your-frontend-domain>"

# ── Frontend Service ─────────────────────────────────────────
VITE_API_URL="https://<your-backend-domain>"
```

### 3. Sprint Go-Live Tracking

- [ ] **US-DEPLOY-01**: Security Hardening & Secret Audit (Pre-Deploy SEC-01 → SEC-03)
- [ ] **US-DEPLOY-02**: Cloud Database Provisioning & Safe Migration
- [ ] **US-DEPLOY-03**: Backend API Deployment & Health Check Verification
- [ ] **US-DEPLOY-04**: Frontend Deployment & SPA Routing Fallback Verification
- [ ] **US-DEPLOY-05**: Production End-to-End Smoke Test

---

## 📝 Ghi Chú Quan Trọng Cho AI

> AI đọc phần này để hiểu ngữ cảnh và quy tắc của file. Không xóa.

### Quy tắc quét của `/command-continue-project`:

1. **Step 1**: Đọc `tech-stack` từ YAML frontmatter → paste vào system prompt của mọi subagent.
2. **Step 2**: Tìm story `[/]` trước (ưu tiên tuyệt đối), sau đó `[ ]` đầu tiên từ trên xuống.
3. **Step 3 (Blocked Gate)**:
   - Nếu story tiếp theo mang nhãn `[!]`: **DỪNG LẠI**, cảnh báo người dùng về vướng mắc/quyết định kiến trúc; chủ động đề xuất kích hoạt phiên `grilling` để làm rõ và gỡ block trước khi tiếp tục.
   - Bỏ qua các mục mang nhãn `[~]` (Deferred).
4. **Step 4 (Dependency Gate)**: Kiểm tra `Depends-on` — nếu dependency chưa `[x]`, **từ chối làm story này**, báo blocked và đề xuất làm dependency trước.
5. **Step 5 (Effort & Budget Routing)**:
   - `Effort: S` + `single-session` → **Fast-Track BA** (2–3 câu, skip gap-analysis).
   - `Effort: M` + `single-session` → **Bounded Task BA** (stages 1→2→4→5→6→7→8).
   - `Effort: L|XL` + `multi-session` → **Full Feature BA** (all 8 stages) + invoke `wayfinder` trước.
6. **Step 6 (Task Allocation)**: Trong Phase 5 Implementation, phân rã công việc trực tiếp từ mục `Tasks: Backend / Frontend` cho `backend-developer` và `frontend-developer`.
7. **Step 7 (Go-Live Sprints)**: Với các story `US-DEPLOY-###`, thực thi theo quy trình Pre-Deploy Verification và Smoke Test thay vì BA feature pipeline thông thường.
8. **Step 8**: Chỉ đánh `[x]` sau khi `e2e-runner` pass, `tech-doc-architect` xong, và `user-guide-creator` đã lưu ảnh Playwright thật.
