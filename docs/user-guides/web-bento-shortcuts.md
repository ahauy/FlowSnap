# Hướng Dẫn Sử Dụng: Bento Grid Features Showcase, Proof Ribbon & Shortcut Matrix (`web-bento-shortcuts`)

Cẩm nang này hướng dẫn chi tiết cách khám phá và tương tác với hai phân vùng cốt lõi trên trang web chính thức của FlowSnap: **Bento Grid 6 Tính Năng Trụ Cột** (`#features`), **Dải Bằng Chứng Kỹ Thuật (Metrics Proof)**, và **Bảng Tra Cứu Phím Tắt Tương Tác (Shortcut Matrix)** (`#shortcuts`).

---

## 1. Bento Grid: 6 Tính Năng Trụ Cột (`#features`)

Bento Grid được thiết kế theo tỷ lệ bất đối xứng đặc trưng của Apple HIG, giúp người dùng nắm bắt ngay những khác biệt đột phá của FlowSnap:

```
┌─────────────────────────────────────────────────────────────┬───────────────────────────────┐
│ 1. Top-Edge Snap Layout Picker (Hero Card - col-span-2)     │ 2. Collinear 2D Resize        │
│    - Kéo cửa sổ chạm mép trên mở khay 4 mẫu layout          │    - Kéo đường phân cách      │
│    - Visual: Sơ đồ cửa sổ kéo lên & picker trượt xuống      │    - Visual: Ngã ba chữ T     │
├───────────────────────────────┬─────────────────────────────┴───────────────────────────────┤
│ 3. Current Space Preservation │ 4. Intent-Based Workspaces & Presets                        │
│    - Mở app mới giữ nguyên    │    - Lưu & khôi phục theo tỷ lệ % không phụ thuộc màn hình  │
│    - Visual: Space 1 Anchored │    - Visual: Tri-split Coding Flow (⌃⌥⌘1)                   │
├───────────────────────────────┴─────────────────────────────┬───────────────────────────────┤
│ 5. Quake-Style Quick Scratchpad (Hero Card - col-span-2)    │ 6. Multi-Monitor Topology     │
│    - ⌥Space triệu hồi nhanh cửa sổ tiện ích (< 50ms)        │    - Ném cửa sổ xuyên màn hình│
│    - ESC tự ẩn, không co nhỏ app nền 1 pixel nào            │    - Visual: Sơ đồ Retina & 4K│
└─────────────────────────────────────────────────────────────┴───────────────────────────────┘
```

### Cách tương tác với Bento Grid:

- **Hover Card**: Rê chuột lên từng ô card để kích hoạt hiệu ứng nâng nhẹ (`translateY(-2px)`) và viền xanh Apple Blue sáng tinh tế.
- **Micro-Illustrations**: Mỗi card sở hữu hình minh họa vector SVG độc bản, tự động thích ứng chế độ Sáng (Light) và Tối (Dark).
- **Thẻ Highlights**: Góc dưới mỗi card tóm lược các điểm kỹ thuật nổi bật nhất (ví dụ: _100% Public APIs_, _Triệu hồi < 50ms_).

---

## 2. Dải Bằng Chứng Kỹ Thuật (Metrics Proof Ribbon)

Nằm ngay trên lưới Bento Grid là dải thông số kỹ thuật được kiểm chứng trực tiếp từ mã nguồn:

| Chỉ số      | Danh mục           | Ý nghĩa kỹ thuật                                                                                                                                |
| :---------- | :----------------- | :---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Swift 6** | Strict Concurrency | 100% Actor isolation, loại bỏ hoàn toàn Data Races khi quản lý cửa sổ ngầm.                                                                     |
| **0**       | Private APIs       | Sử dụng 100% Public Accessibility (`AXUIElement`) & AppKit; tương thích an toàn với macOS Gatekeeper và các bản cập nhật macOS trong tương lai. |
| **470+**    | Automated Tests    | Bộ test suite Swift Testing (`@Test`) bao phủ 100% toán học tọa độ và đảo trục.                                                                 |
| **< 1ms**   | Snap Math          | Tính toán hình học thuần túy trong bộ nhớ, không chạm ổ đĩa, không gây lag di chuyển.                                                           |
| **60 FPS**  | Divider Dragging   | Điều tiết nhịp khung hình 16.6ms (`LiveResizeThrottler`) giúp kéo vách ngăn mượt mà.                                                            |

---

## 3. Bảng Tra Cứu Phím Tắt Tương Tác (`#shortcuts`)

Bảng tra cứu cung cấp giải pháp tra cứu bàn phím nhanh chóng và tiện lợi cho người dùng:

### A. Lọc theo Danh mục (Category Tabs)

Nhấp vào các thẻ danh mục ở thanh điều khiển phía trên để lọc danh sách:

- **Tất cả (15)**: Hiển thị toàn bộ 15 phím tắt của FlowSnap.
- **Cửa sổ (6)**: Các thao tác snap nửa màn hình (50%), 4 góc (25%), phóng to, khôi phục và ghim Always-on-Top (`⌃⌥P`).
- **Màn hình (3)**: Ném cửa sổ sang màn hình bên cạnh (`⌃⌥⇧→`), màn hình trước (`⌃⌥⇧←`), hoặc di chuyển cả Workspace (`⌃⌥⇧⌘→`).
- **Workspace (3)**: Khôi phục preset Coding (`⌃⌥⌘1`), Research (`⌃⌥⌘2`), hoặc chụp ảnh lưu bố cục hiện tại (`⌃⌥⌘S`).
- **Tiện ích (3)**: Triệu hồi Quake Scratchpad (`⌥Space`), Thoát Fullscreen tức thì (`⌃⌘F`), Mở Settings (`⌃⌥,`).

### B. Tìm kiếm Thời gian Thực (Live Search)

- Gõ vào ô tìm kiếm bất kỳ từ khóa nào: ví dụ `⌥Space`, `ném`, `coding`, `snap`.
- Danh sách lọc ngay lập tức sau mỗi ký tự (< 1ms).
- Nếu không có kết quả, nhấn **Xóa bộ lọc & Hiển thị tất cả** để thiết lập lại tìm kiếm.

### C. Sao chép Phím tắt 1-Click (Click to Copy)

- Nhấp vào **cụm phím phím bấm (Keycaps)** hoặc nút **Sao chép**:
  - Chuỗi phím tắt chuẩn macOS (ví dụ: `⌥Space`) sẽ được sao chép ngay vào bộ nhớ đệm (Clipboard).
  - Nút sao chép chuyển sang trạng thái xanh lá **Copied!** với dấu tích xác nhận trong 1.5 giây.

---

## 4. Kiểm thử & Khả năng Tiếp cận (Accessibility)

- **Chuẩn phím macOS**: Toàn bộ keycaps hiển thị font `SF Mono` với hiệu ứng viền nổi giả lập bàn phím thật.
- **Bàn phím & Screen Reader**: Thanh tab hỗ trợ điều hướng `Tab` và `Enter`, tuân thủ tiêu chuẩn ARIA `role="tablist"` và `role="tab"`.
- **Độ tương phản cao**: Toàn bộ màu chữ và viền đạt chuẩn WCAG 2.2 AA (độ tương phản > 4.5:1 trên cả Dark và Light mode).
