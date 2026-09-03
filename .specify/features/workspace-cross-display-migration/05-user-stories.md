# 05 — User Stories & Acceptance Scenarios: workspace-cross-display-migration (US-DISP-017)

## US-MIG-001: Atomic Workspace Cross-Display Migration

- **Derived from**: `docs/PRODUCT_BACKLOG_ROADMAP.md` — `US-DISP-017`
- **As a**: macOS Power User with multiple monitors
- **I want**: to atomically migrate an entire active multi-window Workspace to the next or previous display using global hotkeys (`⌃⌥⇧⌘→` / `⌃⌥⇧⌘←`) or Menu Bar
- **So that**: I can instantly shift my active task context across screens without manually moving each window or losing the split proportions and Stage Manager grouping.

---

### Scenario 1: Migrate 2-Window Workspace to Next Display (Happy Path - Stage Manager OFF)

- **Given**: Người dùng có 2 màn hình (Display A: Retina 2560x1440 và Display B: 1920x1080).
- **And**: Stage Manager đang TẮT.
- **And**: Có một Workspace gồm 2 cửa sổ (Editor 60% + Terminal 40%) đang active trên Display A.
- **And**: Cửa sổ Editor đang có tiêu điểm (focused window).
- **When**: Người dùng bấm phím tắt toàn cục `⌃⌥⇧⌘→` (Next Display).
- **Then**: `WorkspaceMigrator` nhận diện Display A là source display và Display B là target display.
- **And**: Tọa độ của cả 2 cửa sổ được chuyển đổi theo tỉ lệ từ `DisplayA.visibleFrame` sang `DisplayB.visibleFrame` qua `RelativeFrameScaler`.
- **And**: Thứ tự 2-pha được áp dụng (thu nhỏ trước - mở rộng sau) để đưa 2 cửa sổ sang Display B mà không bị va chạm kích thước.
- **And**: Con trỏ chuột tự động được warp đến tâm của cửa sổ Editor trên Display B.
- **And**: Dải phân cách `AdaptiveDividerCoordinator` được tái kích hoạt trên Display B và dải trên Display A bị hủy hoàn toàn.
- **And**: Tiêu điểm bàn phím vẫn thuộc về cửa sổ Editor.

---

### Scenario 2: Migrate Multi-Window Workspace with Stage Manager ON (Stage Cohesion)

- **Given**: Stage Manager đang BẬT trên hệ thống (`GloballyEnabled == true`).
- **And**: Có một Workspace 2 cửa sổ (App 1 + App 2) đang active trên Display A.
- **When**: Người dùng bấm phím tắt `⌃⌥⇧⌘→`.
- **Then**: FlowSnap di chuyển App 1 (Anchor App) sang Display B trước.
- **And**: Áp dụng Staggered IPC delay (40ms) trước khi di chuyển App 2.
- **And**: Gửi lệnh `kAXRaiseAction` lên App 2 mà không gọi `app.activate()`, gom cả App 1 và App 2 vào cùng một Sân khấu (Stage) duy nhất trên Display B.
- **And**: Cả 2 cửa sổ hiển thị đồng thời trên Stage của Display B, không cửa sổ nào bị đẩy vào dải Stage Manager thumbnail.

---

### Scenario 3: Single Monitor Environment (Safe Graceful No-op)

- **Given**: Hệ thống chỉ có 1 màn hình duy nhất (`displays.count == 1`).
- **When**: Người dùng bấm phím tắt `⌃⌥⇧⌘→` hoặc `⌃⌥⇧⌘←`.
- **Then**: Hệ thống trả về `.noOp(.singleDisplay)` êm dịu, không giật rung màn hình, không dịch chuyển bất kỳ cửa sổ nào.

---

### Scenario 4: No Active Workspace on Focused Display (Graceful No-op)

- **Given**: Người dùng có 2 màn hình, nhưng màn hình hiện tại chỉ có các cửa sổ tự do (không thuộc Workspace active nào).
- **When**: Người dùng bấm `⌃⌥⇧⌘→`.
- **Then**: Hệ thống trả về `.noOp(.noActiveWorkspace)` êm dịu.

---

### Scenario 5: Cyclic Wrap-Around Navigation

- **Given**: Người dùng có 3 màn hình được sắp xếp từ trái sang phải (Display 1, Display 2, Display 3).
- **And**: Workspace đang active trên Display 3.
- **When**: Người dùng bấm `⌃⌥⇧⌘→` (Next Display).
- **Then**: Hệ thống tính toán tuần hoàn và di chuyển Workspace từ Display 3 sang Display 1.
- **When**: Người dùng bấm `⌃⌥⇧⌘←` (Previous Display) khi đang ở Display 1.
- **Then**: Hệ thống tuần hoàn di chuyển Workspace từ Display 1 sang Display 3.
