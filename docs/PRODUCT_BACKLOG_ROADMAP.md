---
project: "FlowSnap"
tech-stack:
  language: "Swift 6.0"
  frameworks: "SwiftUI + AppKit (macOS Native)"
  architecture: "Domain-Driven Design (DDD) & Deep Modules"
  concurrency: "Strict Concurrency (Actors, @MainActor, Sendable)"
  storage: "UserDefaults + Local JSON (Application Support)"
  build: "XcodeGen (project.yml) + Xcode 16.0+"
  test: "Swift Testing (@Test) + XCTest"
git-mode: "hybrid"
schema-version: "1.1"
---

# 🗺️ Product Backlog & Execution Roadmap — FlowSnap

> **Sản phẩm:** `FlowSnap` — Trình quản lý cửa sổ và không gian làm việc Native macOS (Your Mac. Your Layout. Your Flow.)
> **Cập nhật lần cuối:** 2026-08-27
>
> **Cách dùng file này:**
>
> - Checkbox `[x]` = Hoàn thành (Tested & Shipped)
> - Checkbox `[/]` = Đang làm dở (In Progress — `/continue` sẽ ưu tiên tiếp tục)
> - Checkbox `[ ]` = Chưa làm (To Do — `/continue` sẽ bốc theo thứ tự từ trên xuống)
> - **Không tự ý sửa `[x]`** — chỉ AI mới được đánh dấu sau khi test pass và docs xong.

---

## 🚫 Explicitly Out of Scope — Won't-Have for MVP

> **CRITICAL:** Phần này là "scope fence" bắt buộc nhằm bảo vệ hệ thống khỏi việc suy diễn tính năng ngoài lề.

- **NO** Cloud Sync / Tài khoản Web / Authentication trên đám mây (100% Local Desktop Utility).
- **NO** Can thiệp Private/Undocumented API của macOS (đặc biệt là hack chuyển Space bằng private CGS calls).
- **NO** Tự động khởi chạy ứng dụng phức tạp / Scripting Automation ("Start a Workflow" tự động mở app).
- **NO** Ứng dụng đa nền tảng (Windows/Linux/Web) — FlowSnap là macOS-only Native Utility.
- **NO** Hệ thống thanh toán / In-App Purchases / License Key phức tạp trong phạm vi MVP.
- **NO** Hỗ trợ kéo thả trên các cửa sổ dialog hệ thống hoặc sheet đặc biệt (chỉ xử lý cửa sổ ứng dụng tiêu chuẩn).

---

## 📊 Tổng Quan Tiến Độ

| Sprint   | Tên Sprint                                           | Trạng thái            | Số Story |
| :------- | :--------------------------------------------------- | :-------------------- | :------- |
| Sprint 0 | Setup & Architecture                                 | `[3/3]` Đã hoàn thành | 3        |
| Sprint 1 | Core Snap Engine & Global Hotkeys (MVP 1)            | `[0/5]` Chưa bắt đầu  | 5        |
| Sprint 2 | Interactive Drag Experience & Custom Layouts (MVP 2) | `[0/5]` Chưa bắt đầu  | 5        |
| Sprint 3 | Workspaces & Per-App Workflow Policies (MVP 3)       | `[0/4]` Chưa bắt đầu  | 4        |

---

## ⚙️ Sprint 0: Project Setup & Architecture (Không phải User Story)

> Sprint 0 là công việc setup nền tảng dự án một lần, không qua quy trình BA Feature.

- [x] **SETUP-001**: Khởi tạo project với XcodeGen (`project.yml`), target `FlowSnap`, `FlowSnapTests`, `FlowSnapLab`.
- [x] **SETUP-002**: Tích hợp Universal Agents Workflow, SwiftLint (`.swiftlint.yml`), bộ kỹ năng Swift 6 & Subagents chuyên biệt.
- [x] **SETUP-003**: Cấu hình Code-Review-Graph MCP Server và chỉ mục AST SQLite (`.code-review-graph/graph.db`).

---

## 🎯 Sprint 1: Core Snap Engine & Global Hotkeys (MVP 1)

> **Mục tiêu Sprint:** Hoàn thiện tiện ích snap cửa sổ cốt lõi qua phím tắt toàn cục, hỗ trợ đa màn hình, tính toán hình học chính xác và quản lý nhanh qua Menu Bar.

- [ ] **US-SNAP-001**: Trợ năng & Nhận diện Cửa sổ Trọng tâm (Accessibility & Focused Window Discovery)
  - **Slug:** `accessibility-window-discovery`
  - **Effort:** S
  - **Context-budget:** single-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** _(none)_
  - **Blocks:** `US-SNAP-002`
  - **Mô tả:** Kiểm tra và hướng dẫn cấp quyền macOS Accessibility (AXUIElement), phát hiện và đọc thông tin hình học (frame, bounds, pid, title) của cửa sổ đang active.
  - **Acceptance Criteria (AC):**
    - [ ] Ứng dụng kiểm tra trạng thái quyền Accessibility; nếu chưa có quyền, hiển thị prompt hướng dẫn người dùng mở System Settings.
    - [ ] Khi đã cấp quyền, service lấy được `AXUIElement` của focused window đang active và đọc chính xác tọa độ frame (x, y, width, height).
    - [ ] Lọc bỏ các cửa sổ hệ thống hoặc dialog đặc biệt không hợp lệ theo `WindowKind` (.normal).
  - **Deliverables khi [x]:**
    - `.specify/features/accessibility-window-discovery/baseline.md` (SIGNED-OFF)
    - `docs/features/accessibility-window-discovery/README.md`
    - `docs/user-guides/accessibility-window-discovery.md`

- [ ] **US-SNAP-002**: Động cơ Tính toán Bố cục Snap Cơ bản (Core Layout & Snap Engine)
  - **Slug:** `core-layout-snap-engine`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-SNAP-001`
  - **Blocks:** `US-SNAP-003`
  - **Mô tả:** Tính toán hình học chính xác cho các phân vùng snap chuẩn (trái 50%, phải 50%, 4 góc 25%, maximize, restore về frame cũ) độc lập với tọa độ pixel.
  - **Acceptance Criteria (AC):**
    - [ ] `LayoutEngine` tính toán chuẩn xác frame cho 50% trái, 50% phải, và 4 góc (25% mỗi góc) dựa trên visible frame của màn hình.
    - [ ] Tính toán Maximize chiếm toàn bộ diện tích làm việc (trừ Menu bar & Dock) và hỗ trợ khôi phục (Restore) về vị trí gốc trước khi snap.
    - [ ] Unit test độ bao phủ 100% cho các tỷ lệ màn hình (16:9, 16:10, màn hình dọc Portrait) bằng Swift Testing (`@Test`).
  - **Deliverables khi [x]:**
    - `.specify/features/core-layout-snap-engine/baseline.md` (SIGNED-OFF)
    - `docs/features/core-layout-snap-engine/README.md`
    - `docs/user-guides/core-layout-snap-engine.md`

- [ ] **US-SNAP-003**: Nhận diện & Thao tác Cửa sổ trên Đa Màn hình (Display-Aware Multi-Monitor Manipulation)
  - **Slug:** `display-aware-manipulation`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-SNAP-002`
  - **Blocks:** `US-SNAP-004`
  - **Mô tả:** Xác định chính xác màn hình đang chứa con trỏ/cửa sổ mục tiêu trên thiết lập đa màn hình (kể cả khác độ phân giải/Retina scale) và thực thi di chuyển/resize cửa sổ mượt mà.
  - **Acceptance Criteria (AC):**
    - [ ] `DisplayManager` xác định đúng `NSScreen` chứa tâm của focused window hoặc vị trí con trỏ chuột hiện tại.
    - [ ] Chuyển đổi chính xác hệ tọa độ giữa AppKit (gốc dưới-trái) và Accessibility API (gốc trên-trái) qua các màn hình phụ.
    - [ ] Thực thi resize và move window qua Accessibility API mượt mà không làm rung lắc hoặc vỡ layout.
  - **Deliverables khi [x]:**
    - `.specify/features/display-aware-manipulation/baseline.md` (SIGNED-OFF)
    - `docs/features/display-aware-manipulation/README.md`
    - `docs/user-guides/display-aware-manipulation.md`

- [ ] **US-SNAP-004**: Phím tắt Toàn cục & Hệ thống Điều phối Lệnh (Global Hotkeys & Command Dispatcher)
  - **Slug:** `global-hotkeys-dispatcher`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-SNAP-003`
  - **Blocks:** `US-SNAP-005`
  - **Mô tả:** Đăng ký các phím tắt hệ thống toàn cục (⌃⌥←, ⌃⌥→, ⌃⌥↑, ⌃⌥↓, ⌃⌥1..4) và điều phối lệnh snap tức thì với độ trễ cực thấp (< 50ms).
  - **Acceptance Criteria (AC):**
    - [ ] Lắng nghe phím tắt toàn cục qua Carbon API / CGEventTap ngay cả khi ứng dụng đang chạy nền.
    - [ ] Nhấn ⌃⌥← lập tức snap cửa sổ đang active sang nửa trái 50%; nhấn ⌃⌥→ snap sang nửa phải 50%.
    - [ ] Nhấn ⌃⌥↑ phóng to toàn màn hình (Maximize); nhấn ⌃⌥↓ khôi phục vị trí cũ (Restore).
    - [ ] Không block Main Thread khi xử lý lệnh snap.
  - **Deliverables khi [x]:**
    - `.specify/features/global-hotkeys-dispatcher/baseline.md` (SIGNED-OFF)
    - `docs/features/global-hotkeys-dispatcher/README.md`
    - `docs/user-guides/global-hotkeys-dispatcher.md`

- [ ] **US-SNAP-005**: Menu Bar Item & Bảng Điều khiển Nhanh (Menu Bar Status Item & Quick Snap Controls)
  - **Slug:** `menubar-quick-controls`
  - **Effort:** S
  - **Context-budget:** single-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-SNAP-004`
  - **Blocks:** `US-SNAP-006`
  - **Mô tả:** Cung cấp biểu tượng Menu Bar thường trú trên macOS cho phép xem trạng thái ứng dụng, bấm chuột để snap nhanh cửa sổ active và mở Settings.
  - **Acceptance Criteria (AC):**
    - [ ] Biểu tượng FlowSnap xuất hiện trên Menu Bar hệ thống (NSStatusItem) mà không hiển thị dock icon (LSUIElement).
    - [ ] Bấm vào icon mở menu/popover với các nút snap trực quan (Left 50%, Right 50%, Corners, Maximize, Restore) kèm gợi ý phím tắt.
    - [ ] Cung cấp nút truy cập Settings và Thoát ứng dụng (Quit).
  - **Deliverables khi [x]:**
    - `.specify/features/menubar-quick-controls/baseline.md` (SIGNED-OFF)
    - `docs/features/menubar-quick-controls/README.md`
    - `docs/user-guides/menubar-quick-controls.md`

---

## 🚀 Sprint 2: Interactive Drag Experience & Custom Layouts (MVP 2)

> **Mục tiêu Sprint:** Nâng cấp trải nghiệm tương tác trực quan với kéo thả snap (Drag-to-snap), HUD Preview, Snap Layout Picker cạnh trên phong cách Windows 11, thay đổi kích thước chia sẻ cạnh chung và cài đặt phím tắt tùy chỉnh.

- [ ] **US-SNAP-006**: Kéo Thả vào Cạnh Màn hình & Lớp Phủ Xem trước Snap (Drag-to-Snap & HUD Snap Preview)
  - **Slug:** `drag-to-snap-preview`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-SNAP-005`
  - **Blocks:** `US-SNAP-007`
  - **Mô tả:** Theo dõi hành vi kéo cửa sổ sát cạnh/góc màn hình và hiển thị overlay bán trong suốt (HUD Snap Preview) mô phỏng vị trí trước khi thả chuột.
  - **Acceptance Criteria (AC):**
    - [ ] Phát hiện khi con trỏ chuột kéo cửa sổ chạm mép màn hình (ngưỡng edge threshold kích hoạt hợp lý).
    - [ ] Hiển thị lớp phủ bán trong suốt (NSPanel non-activating) mô phỏng vùng snap tương ứng với hiệu ứng animation mượt mà.
    - [ ] Khi nhả chuột, cửa sổ snap chính xác vào vùng đã preview; nếu kéo ra xa mép, preview tự động biến mất.
  - **Deliverables khi [x]:**
    - `.specify/features/drag-to-snap-preview/baseline.md` (SIGNED-OFF)
    - `docs/features/drag-to-snap-preview/README.md`
    - `docs/user-guides/drag-to-snap-preview.md`

- [ ] **US-SNAP-007**: Snap Layout Picker Cạnh Trên Phong cách Windows 11 (Top-Edge Snap Layout Picker)
  - **Slug:** `top-edge-layout-picker`
  - **Effort:** L
  - **Context-budget:** multi-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-SNAP-006`
  - **Blocks:** `US-SNAP-008`
  - **Mô tả:** Khi kéo cửa sổ chạm mép trên cùng màn hình, hiển thị popup Layout Picker với nhiều ô chia (50/50, 70/30, 3 cột, 4 góc) cho phép thả trực tiếp vào ô mong muốn.
  - **Acceptance Criteria (AC):**
    - [ ] Giữ cửa sổ kéo lên sát cạnh trên xuất hiện menu popup Layout Picker với các mẫu bố cục phổ biến.
    - [ ] Highlight ô cụ thể khi con trỏ hover vào ô trong picker.
    - [ ] Thả chuột trong ô nào thì cửa sổ snap chính xác vào vị trí ô đó trên màn hình hiện tại.
    - [ ] Kéo chuột ra khỏi vùng picker mà không chọn thì picker biến mất và trả về trạng thái kéo tự do bình thường.
  - **Deliverables khi [x]:**
    - `.specify/features/top-edge-layout-picker/baseline.md` (SIGNED-OFF)
    - `docs/features/top-edge-layout-picker/README.md`
    - `docs/user-guides/top-edge-layout-picker.md`

- [ ] **US-SNAP-008**: Tỷ lệ Bố cục Tùy chỉnh (60/40, 70/30) & Khoảng cách Cửa sổ (Custom Ratios & Window Gaps)
  - **Slug:** `custom-ratios-window-gaps`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-SNAP-007`
  - **Blocks:** `US-SNAP-009`
  - **Mô tả:** Hỗ trợ chia màn hình theo tỷ lệ bất đối xứng (60/40, 70/30, 80/20) và cho phép cấu hình khoảng hở viền thẩm mỹ (Window Gap: 0px, 4px, 8px, 16px).
  - **Acceptance Criteria (AC):**
    - [ ] `LayoutEngine` hỗ trợ tính toán tọa độ theo tỷ lệ tùy biến (60/40, 70/30, 80/20) thay vì chỉ cố định 50/50.
    - [ ] Cấu hình khoảng cách giữa các cửa sổ và mép màn hình (Window Gaps) hoạt động chuẩn xác, không làm lệch mép hiển thị.
    - [ ] Lưu cấu hình Gap và Default Ratio vào PreferencesStore.
  - **Deliverables khi [x]:**
    - `.specify/features/custom-ratios-window-gaps/baseline.md` (SIGNED-OFF)
    - `docs/features/custom-ratios-window-gaps/README.md`
    - `docs/user-guides/custom-ratios-window-gaps.md`

- [ ] **US-SNAP-009**: Kéo Đường Phân cách Chung Đa Cửa sổ (Adaptive Multi-Window Divider Resize)
  - **Slug:** `adaptive-divider-resize`
  - **Effort:** L
  - **Context-budget:** multi-session
  - **Priority:** Could-Have (P2)
  - **Depends-on:** `US-SNAP-008`
  - **Blocks:** `US-SNAP-010`
  - **Mô tả:** Cho phép kéo đường phân cách chung giữa các cửa sổ liền kề trong cùng layout để cùng lúc resize tất cả các cửa sổ có cạnh chung (collinear edge) mà không làm vỡ layout.
  - **Acceptance Criteria (AC):**
    - [ ] Nhận diện đường phân cách chung giữa 2 hoặc nhiều cửa sổ thuộc cùng layout đang active.
    - [ ] Đổi con trỏ chuột sang resize-cursor khi hover gần cạnh chung.
    - [ ] Kéo đường phân cách resize đồng thời các cửa sổ bám vào cạnh đó (ví dụ VS Code bên trái rộng ra thì cả Chrome và Terminal bên phải thu nhỏ lại đồng thời).
    - [ ] Tôn trọng kích thước tối thiểu (min-size) của từng ứng dụng, không cho phép kéo đè làm biến mất cửa sổ.
  - **Deliverables khi [x]:**
    - `.specify/features/adaptive-divider-resize/baseline.md` (SIGNED-OFF)
    - `docs/features/adaptive-divider-resize/README.md`
    - `docs/user-guides/adaptive-divider-resize.md`

- [ ] **US-SNAP-010**: Giao diện Cài đặt SwiftUI & Tùy biến Phím tắt (Settings UI & Shortcut Customization)
  - **Slug:** `settings-shortcut-customization`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-SNAP-009`
  - **Blocks:** `US-WORK-011`
  - **Mô tả:** Xây dựng cửa sổ Settings trực quan bằng SwiftUI cho phép cấu hình khởi động cùng hệ thống, điều chỉnh Window Gap, gán phím tắt tùy biến và xem quyền hạn.
  - **Acceptance Criteria (AC):**
    - [ ] Màn hình Settings gồm các tab: General (Launch at login, Gaps), Shortcuts (ghi phím tắt mới), About.
    - [ ] Cho phép người dùng click để gán lại phím tắt tùy thích cho từng hành động snap (bắt KeyCode & Modifier).
    - [ ] Dữ liệu cấu hình tự động đồng bộ xuống `UserDefaults` qua `PreferencesStore`.
  - **Deliverables khi [x]:**
    - `.specify/features/settings-shortcut-customization/baseline.md` (SIGNED-OFF)
    - `docs/features/settings-shortcut-customization/README.md`
    - `docs/user-guides/settings-shortcut-customization.md`

---

## 🏢 Sprint 3: Workspaces & Per-App Workflow Policies (MVP 3)

> **Mục tiêu Sprint:** Điểm khác biệt cốt lõi của FlowSnap — Biến desktop thành không gian làm việc lưu trữ được (Workspaces), giữ ứng dụng mới mở trong workflow hiện tại và áp dụng chính sách riêng cho từng ứng dụng.

- [ ] **US-WORK-011**: Lưu & Khôi phục Bố cục Workspace theo Ý định (Workspace Snapshot & Intent Restoration)
  - **Slug:** `workspace-snapshot-restoration`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-SNAP-010`
  - **Blocks:** `US-WORK-012`
  - **Mô tả:** Lưu trữ bố cục làm việc hiện tại thành một Workspace (lưu ý định bố trí ứng dụng - WindowPlacement, không lưu pixel cứng) và khôi phục lại khi cần.
  - **Acceptance Criteria (AC):**
    - [ ] Người dùng có thể nhấn "Lưu Workspace hiện tại", nhập tên (ví dụ "Coding", "Research") kèm icon.
    - [ ] Bố cục được lưu dưới dạng intent (App Bundle ID -> Zone ID/Ratio) vào file JSON tại `Application Support/FlowSnap/workspaces.json`.
    - [ ] Khi chọn "Restore Workspace", FlowSnap tự động tìm các cửa sổ của các app tương ứng và đưa về đúng vùng bố cục, thích ứng linh hoạt với màn hình hiện tại.
  - **Deliverables khi [x]:**
    - `.specify/features/workspace-snapshot-restoration/baseline.md` (SIGNED-OFF)
    - `docs/features/workspace-snapshot-restoration/README.md`
    - `docs/user-guides/workspace-snapshot-restoration.md`

- [ ] **US-WORK-012**: Nhóm Cửa sổ & Workspace Presets (Window Groups & Named Presets)
  - **Slug:** `window-groups-presets`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-WORK-011`
  - **Blocks:** `US-WORK-013`
  - **Mô tả:** Cung cấp sẵn các mẫu Workspace Presets thông dụng (Coding, Design, Research, Writing) và quản lý nhóm cửa sổ liên kết nhau.
  - **Acceptance Criteria (AC):**
    - [ ] Cung cấp sẵn các preset mặc định: Coding (Editor 60%, Browser 25%, Terminal 15%), Research (Browser 1 50%, Notes 25%, Browser 2 25%).
    - [ ] Cho phép gán phím tắt nhanh để restore một preset (ví dụ ⌃⌥C để khôi phục Coding Workspace).
    - [ ] Quản lý Window Group: gom các app trong workflow thành một nhóm để di chuyển hoặc thu nhỏ đồng thời.
  - **Deliverables khi [x]:**
    - `.specify/features/window-groups-presets/baseline.md` (SIGNED-OFF)
    - `docs/features/window-groups-presets/README.md`
    - `docs/user-guides/window-groups-presets.md`

- [ ] **US-WORK-013**: Phát hiện Mở Ứng dụng & Giữ ở Workspace Hiện tại (App Launch Observer & Current Space Policy)
  - **Slug:** `app-launch-current-space-policy`
  - **Effort:** L
  - **Context-budget:** multi-session
  - **Priority:** Must-Have (P0)
  - **Depends-on:** `US-WORK-012`
  - **Blocks:** `US-WORK-014`
  - **Mô tả:** Lắng nghe sự kiện mở ứng dụng qua NSWorkspace/EventBus và áp dụng chính sách để cửa sổ mới mở xuất hiện ngay trong không gian làm việc hiện tại, không làm văng người dùng sang Space khác.
  - **Acceptance Criteria (AC):**
    - [ ] `WorkspaceObserver` lắng nghe `NSWorkspace.didLaunchApplicationNotification` và bắt sự kiện cửa sổ đầu tiên được tạo qua AXUIElement observer.
    - [ ] Áp dụng Window Policy `Current Space + Current Display` qua Public APIs, giữ cửa sổ xuất hiện tại ngữ cảnh người dùng đang tập trung.
    - [ ] Không sử dụng bất kỳ private/undocumented API nào của macOS; duy trì độ ổn định trên macOS 14 & 15.
  - **Deliverables khi [x]:**
    - `.specify/features/app-launch-current-space-policy/baseline.md` (SIGNED-OFF)
    - `docs/features/app-launch-current-space-policy/README.md`
    - `docs/user-guides/app-launch-current-space-policy.md`

- [ ] **US-WORK-014**: Quy tắc Riêng cho Từng Ứng dụng & Cửa sổ Nổi Thông minh (Per-App Rules & Smart Floating Stack)
  - **Slug:** `per-app-rules-floating-stack`
  - **Effort:** M
  - **Context-budget:** single-session
  - **Priority:** Should-Have (P1)
  - **Depends-on:** `US-WORK-013`
  - **Blocks:** _(none)_
  - **Mô tả:** Cho phép người dùng thiết lập quy tắc chuyên biệt cho từng app (ví dụ Telegram luôn Floating, Spotify luôn nhớ vị trí, VS Code luôn snap 60% bên trái) và cơ chế Smart Window Stack khi có app tạm mở đè lên.
  - **Acceptance Criteria (AC):**
    - [ ] UI trong Settings cho phép thêm quy tắc theo Bundle Identifier (Floating, Remember Position, Assigned Layout).
    - [ ] Cửa sổ dạng Floating (như chat Telegram/Slack) nổi trên workflow hiện tại mà không phá vỡ bố cục các app bên dưới.
    - [ ] Đóng app nổi thì layout các app đang làm việc bên dưới vẫn giữ nguyên trạng thái cũ.
  - **Deliverables khi [x]:**
    - `.specify/features/per-app-rules-floating-stack/baseline.md` (SIGNED-OFF)
    - `docs/features/per-app-rules-floating-stack/README.md`
    - `docs/user-guides/per-app-rules-floating-stack.md`

---

## 🔮 Backlog Dự Kiến — Future Horizons (V2.0+)

> Các ý tưởng dài hạn chưa cam kết trong phạm vi MVP. Không có Slug hoặc AC chi tiết — sẽ được phân tích khi bước vào phiên bản 2.0.

- [ ] **US-FUTURE-001**: Visual Interactive Layout Editor (Trình vẽ bố cục kéo thả trực quan trên Canvas).
- [ ] **US-FUTURE-002**: Start-a-Workflow Automation (Tự động mở danh sách app và bố trí vị trí đồng thời).
- [ ] **US-FUTURE-003**: Cross-Machine Config Export & Import (Chia sẻ preset layout qua AirDrop/File JSON).

---

## 📝 Ghi Chú Quan Trọng Cho AI

> AI đọc phần này để hiểu ngữ cảnh và quy tắc vận hành file. Không xóa.

### Quy tắc quét của `/command-continue-project`:

1. **Step 1**: Đọc `tech-stack` từ YAML frontmatter → nạp vào system prompt của mọi subagent thực thi.
2. **Step 2**: Tìm story `[/]` trước (ưu tiên tuyệt đối việc dở dang), sau đó tìm story `[ ]` đầu tiên theo thứ tự từ trên xuống dưới.
3. **Step 3**: Kiểm tra `Depends-on` — nếu dependency chưa `[x]`, **từ chối làm story này**, báo blocked và đề xuất hoàn thành dependency trước.
4. **Step 4**: Đọc `Effort` + `Context-budget`:
   - `Effort: S` + `single-session` → **Fast-Track BA** (2–3 câu hỏi, bỏ qua gap-analysis).
   - `Effort: M` + `single-session` → **Bounded Task BA** (stages 1→2→4→5→6→7→8).
   - `Effort: L|XL` + `multi-session` → **Full Feature BA** (đầy đủ 8 stages) + kích hoạt `wayfinder` lập bản đồ quyết định trước.
5. **Step 5**: Chỉ đánh `[x]` sau khi `e2e-runner` pass, `tech-doc-architect` cập nhật tài liệu, và `user-guide-creator` hoàn thành cẩm nang người dùng.
