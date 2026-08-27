---
project: "<Project Name>"
tech-stack:
  language: "<e.g. TypeScript>"
  backend: "<e.g. NestJS + Prisma ORM>"
  frontend: "<e.g. Next.js 15 App Router + Zustand>"
  database: "<e.g. PostgreSQL 16>"
  infra: "<e.g. Docker Compose (local) / Railway (prod)>"
  test: "<e.g. Vitest + Playwright>"
git-mode: "team" # team | local | stealth
schema-version: "1.1"
---

# 🗺️ Product Backlog & Execution Roadmap

> **Sản phẩm:** `<Product Name>` — `<One-sentence description>`
> **Cập nhật lần cuối:** `<YYYY-MM-DD>`
>
> **Cách dùng file này:**
>
> - Checkbox `[x]` = Hoàn thành (Tested & Shipped)
> - Checkbox `[/]` = Đang làm dở (In Progress — `/continue` sẽ ưu tiên tiếp tục)
> - Checkbox `[ ]` = Chưa làm (To Do — `/continue` sẽ bốc theo thứ tự từ trên xuống)
> - **Không tự ý sửa `[x]`** — chỉ AI mới được đánh dấu sau khi test pass và docs xong.

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

## 📊 Tổng Quan Tiến Độ

| Sprint   | Tên Sprint            | Trạng thái           | Số Story |
| :------- | :-------------------- | :------------------- | :------- |
| Sprint 0 | Setup & Architecture  | `[0/0]` Chưa bắt đầu | 0        |
| Sprint 1 | Core Foundation (MVP) | `[0/3]` Chưa bắt đầu | 3        |
| Sprint 2 | `<Tên Sprint 2>`      | `[0/3]` Chưa bắt đầu | 3        |

---

## ⚙️ Sprint 0: Project Setup & Architecture (Không phải User Story)

> Sprint 0 là công việc setup một lần, không cần BA pipeline.
> Dùng Micro-Task Fast-Track: Reproduce → Fix → Verify → Commit.

- [x] **SETUP-001**: Khởi tạo repo, cấu hình `.agents/`, `.specify/`, Git mode
- [x] **SETUP-002**: Thiết lập Docker Compose / Dev environment
- [x] **SETUP-003**: Cấu hình CI/CD pipeline (GitHub Actions / Railway)

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
  - **Deliverables khi [x]:**
    - `.specify/features/<slug>/baseline.md` (SIGNED-OFF)
    - `docs/features/<slug>/README.md`

---

## 🔮 Backlog Dự Kiến — Future Horizons (V2.0+)

> Các ý tưởng chưa được ưu tiên. Không có Slug, không có AC — chỉ là placeholder.
> Khi quyết định làm, chuyển vào Sprint tương ứng và điền đầy đủ thông tin.

- [ ] **US-FUTURE-NNN**: `<Tên tính năng tương lai 1>`
- [ ] **US-FUTURE-NNN**: `<Tên tính năng tương lai 2>`

---

## 📝 Ghi Chú Quan Trọng Cho AI

> AI đọc phần này để hiểu ngữ cảnh và quy tắc của file. Không xóa.

### Quy tắc quét của `/command-continue-project`:

1. **Step 1**: Đọc `tech-stack` từ YAML frontmatter → paste vào system prompt của mọi subagent.
2. **Step 2**: Tìm story `[/]` trước (ưu tiên tuyệt đối), sau đó `[ ]` đầu tiên từ trên xuống.
3. **Step 3**: Kiểm tra `Depends-on` — nếu dependency chưa `[x]`, **từ chối làm story này**, báo blocked và đề xuất làm dependency trước.
4. **Step 4**: Đọc `Effort` + `Context-budget`:
   - `Effort: S` + `single-session` → **Fast-Track BA** (2–3 câu, skip gap-analysis).
   - `Effort: M` + `single-session` → **Bounded Task BA** (stages 1→2→4→5→6→7→8).
   - `Effort: L|XL` + `multi-session` → **Full Feature BA** (all 8 stages) + invoke `wayfinder` trước.
5. **Step 5**: Chỉ đánh `[x]` sau khi `e2e-runner` pass, `tech-doc-architect` xong, và `user-guide-creator` đã lưu ảnh Playwright thật.
