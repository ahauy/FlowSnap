# Đặc Tả Kiến Trúc: Bộ Mở Rộng Ngôn Ngữ (Language Pack Specification)

> **Mục tiêu**: Định nghĩa bộ tiêu chuẩn thống nhất để mở rộng hoặc đóng gói bất kỳ ngôn ngữ lập trình nào (Java, C#, C++, Rust, Go, Python, Swift, PHP, Dart...) vào **Universal Agents Workflow** mà không gây xung đột quy trình, không làm phình dự án đích (zero-bloat) và tương thích 100% với mọi nền tảng AI.

---

## 1. Triết Lý Kiến Trúc: The Language Quad (Bộ Tứ Thành Phần)

Mọi gói ngôn ngữ (Language Pack) đặt tại `optional-stack-skills/languages/<lang>/` **bắt buộc** phải tuân thủ cấu trúc 4 thành phần sau:

```
optional-stack-skills/languages/<lang>/
├── skills/                      # 1. KỸ NĂNG CHUYÊN SÂU (Skills)
│   ├── <lang>-patterns/         # Kiến trúc deep modules, xử lý lỗi, idioms
│   ├── <lang>-testing/          # Chiến lược unit & integration testing
│   └── <framework>-patterns/    # Patterns cho framework phổ biến (nếu có)
├── rules/                       # 2. QUY TẮC CÚ PHÁP & AN TOÀN (Rules)
│   └── coding-style.md          # Naming, concurrency rules, cấm anti-patterns
├── agents/                      # 3. SUBAGENTS CHUYÊN BIỆT (Agents)
│   ├── <lang>-reviewer.md       # Phản biện bảo mật, memory & idioms ở Phase 6A
│   └── <lang>-build-resolver.md # Sửa lỗi biên dịch & dependency ở Phase 5
└── linters/                     # 4. RÀO CHẮN RANH GIỚI KIẾN TRÚC (Linters)
    └── <linter-config>          # File cấu hình chặn import chéo (depguard, archunit...)
```

---

## 2. Tiêu Chuẩn Cho Từng Thành Phần

### A. Subagents (`agents/`)

Mỗi subagent phải có frontmatter YAML chuẩn xác:

1. **Reviewer (`<lang>-reviewer.md`)**:
   - **Vai trò**: Đảm nhiệm Phase 6A (Dual-Pass Adversarial Review).
   - **Model**: `inherit` (mặc định bắt buộc). Chỉ override bằng model ID mà harness đang dùng thực sự cung cấp.
   - **Tools**: `Read, Grep, Glob, Bash` (Nghiêm cấm quyền Write/Edit để đảm bảo tính khách quan read-only).
   - **Nhiệm vụ bắt buộc**: Chạy lệnh diff (`git diff HEAD~1`), linter của ngôn ngữ, kiểm tra an toàn bộ nhớ (memory leaks, race conditions, dangling pointers, unhandled exceptions) và Anti-AI-Slop.

2. **Build Resolver (`<lang>-build-resolver.md`)**:
   - **Vai trò**: Đảm nhiệm Phase 5 (Fullstack Implementation & TDD).
   - **Model**: `inherit` (mặc định bắt buộc). Chỉ override bằng model ID mà harness đang dùng thực sự cung cấp.
   - **Tools**: `Read, Write, Edit, Bash, Grep, Glob`.
   - **Nhiệm vụ bắt buộc**: Chẩn đoán lỗi biên dịch bằng lệnh chính thống (ví dụ: `cargo check`, `go build`, `swift build`, `mvn compile`), thực hiện **chỉnh sửa tối thiểu (surgical edit)** để hết lỗi, tuyệt đối không refactor lan sang các file không liên quan.

### B. Kỹ Năng (`skills/`)

- Phải có file `SKILL.md` kèm frontmatter (`name`, `description`).
- Hướng dẫn cụ thể, thực tế, kèm mã nguồn mẫu minh họa các tình huống đúng/sai.
- Tuân thủ nguyên lý Deep Modules (Giao diện hẹp, che giấu độ phức tạp triển khai).

### C. Quy Tắc (`rules/`)

- Trình bày dạng Markdown cô đọng, quy định rõ các điều cấm (ví dụ: cấm force unwrap `!`, cấm `.unwrap()`, cấm `unsafe` thiếu giải trình).

### D. Rào Chắn Ranh Giới (`linters/`)

- Cấu hình công cụ phân tích tĩnh hoặc linter ranh giới (Depguard cho Go, Import-Linter cho Python, SwiftLint cho Swift, Dependency-Cruiser cho TypeScript).

---

## 3. Khai Báo Trong Registry (`catalog.json`)

Mọi thành phần của gói ngôn ngữ phải được đăng ký vào [`.agents/catalog.json`](file:///Users/vutuanhau/Documents/PROJECT/Universal-Agents-Workflow/.agents/catalog.json) theo schema:

```json
{
  "id": "<lang>-pack-or-item",
  "name": "Human-Readable Name",
  "category": "Language | Framework | Subagent | Boundary Enforcement",
  "short_description": "Tóm tắt 1-2 câu về giá trị thực tế của module.",
  "detection_markers": [
    "marker-file-1",
    "*.extension",
    "manifest.json:\"keyword\""
  ],
  "source_path": "optional-stack-skills/languages/<lang>/<path>",
  "target_type": "skill | rule | agent | config",
  "target_path": ".agents/skills/engineering/<name> | .agents/rules/<name> | .agents/agents | <root-file>",
  "recommendation": "recommended | optional"
}
```

---

## 4. Cơ Chế Điều Phối Động (Dynamic Dispatch Protocol)

Orchestrator hoạt động theo quy ước:

1. **Pha 5 (Build Resolution)**:
   - Khi có lỗi biên dịch: Orchestrator kiểm tra `.agents/agents/` xem có `<lang>-build-resolver.md` ứng với ngôn ngữ của tệp bị lỗi hay không.
   - Nếu **CÓ** $\rightarrow$ Gọi `<lang>-build-resolver`.
   - Nếu **KHÔNG** $\rightarrow$ Gọi `build-resolver` gốc làm polyglot fallback.
2. **Pha 6A (Adversarial Review)**:
   - Khi review mã nguồn: Orchestrator kiểm tra sự tồn tại của `<lang>-reviewer.md`.
   - Nếu **CÓ** $\rightarrow$ Gọi `<lang>-reviewer` thực hiện Pass A (Standards, Memory, Security) chuyên sâu theo ngôn ngữ.
   - Nếu **KHÔNG** $\rightarrow$ Gọi `code-reviewer` gốc thực hiện Pass A tổng quát.

---

## 5. Quy Trình 5 Bước Thêm Ngôn Ngữ Mới Vào Kho

Khi muốn bổ sung một ngôn ngữ mới vào Universal Agents Workflow:

1. **Bước 1**: Tạo thư mục `optional-stack-skills/languages/<lang>/`.
2. **Bước 2**: Tạo các kỹ năng trong `skills/`, quy tắc trong `rules/`, rào chắn trong `linters/`.
3. **Bước 3**: Tạo 2 subagent `<lang>-reviewer.md` và `<lang>-build-resolver.md` trong `agents/`.
4. **Bước 4**: Khai báo danh mục vào `optional-stack-skills/catalog.json` (và đồng bộ sang `.agents/catalog.json`).
5. **Bước 5**: Kiểm tra bằng lệnh quét `/skill-setup`, sau đó chạy
   `python3 .agents/scripts/validate-agents.py --root .` để xác minh cả hai lớp hợp đồng
   (model availability và tool-call hygiene). Xem
   `docs/architecture/MODEL_AND_TOOLCALL_CONTRACT.md`.

---

## 6. Quy Tắc Phân Bổ Model (Bắt Buộc)

`model: inherit` là giá trị mặc định và là giá trị duy nhất được khuyến nghị
cho mọi subagent trong kho này, kể cả agent do language pack cung cấp.

Lý do là cơ chế phân bổ model nằm ở tầng harness, không phải tầng nội dung:

1. Harness đọc frontmatter khi nạp agent. Nếu `model` là một ID mà harness
   không cung cấp, agent bị loại khỏi danh sách *trước khi* phiên chạy bắt đầu
   (báo lỗi dạng "Requested model X is not available").
2. Nếu `model` bị bỏ trống hoặc để `inherit`, harness dùng model của phiên
   hiện tại. Đây là hành vi đúng cho mọi harness được hỗ trợ.
3. Khi cùng một kho chạy trên nhiều harness khác nhau (Claude Code, Codex,
   Qwen Code, OpenCode, ...), một ID hardcode hợp lệ trên harness này gần như
   chắc chắn vô hiệu trên harness khác.

Vì vậy:

- Không hardcode model ID vào `<lang>-reviewer.md` / `<lang>-build-resolver.md`.
- Không đề xuất model ID cụ thể trong tài liệu hướng dẫn tạo agent.
- Nếu thật sự cần model khác cho một agent, hãy để `inherit` và cấu hình ở tầng
  harness (ví dụ `.agents/agents/openai.yaml`), nơi người dùng có thể sửa mà
  không đụng tới file agent.
