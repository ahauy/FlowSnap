# 01 — Elicitation Record (Stage 2) — web-desktop-sandbox

> Interview conducted on 2026-09-07 via interactive elicitation interview gate for US-WEB-026.
> Confirmed decisions: `ASM-WEB-004`, `ASM-WEB-005`, `ASM-WEB-006`.

## Confirmed Decisions

### ASM-WEB-004 — 3D Perspective & Render Engine Architecture

- **Decision**: Sử dụng **Hardware-Accelerated CSS 3D Transforms** kết hợp pointer tracking mượt mà:
  1. **Perspective Container**: Container giả lập màn hình macOS sử dụng thuộc tính `perspective: 1200px` và `transform-style: preserve-3d`.
  2. **Pointer Tilt Tracking**: Khi người dùng di chuột trên khu vực Simulator, tính toán góc nghiêng tự nhiên `rotateX` (giới hạn từ -6° đến +6°) và `rotateY` (giới hạn từ -8° đến +8°) kèm hiệu ứng phản chiếu ánh sáng kính động (dynamic specular highlight reflection).
  3. **Zero Extra Bundle Overhead**: Không cần tải thêm thư viện WebGL cồng kềnh, đạt 120 FPS buttery-smooth trên màn hình ProMotion, 0ms FCP/LCP và tải trang tức thì.
  4. **Performance & Energy Budget (0.0% Idle CPU)**: Sử dụng `IntersectionObserver` để tự động ngắt toàn bộ event listener và transition khi component cuộn ra khỏi viewport của người dùng. Khi người dùng không tương tác hoặc rê chuột ra ngoài, màn hình mượt mà trôi về vị trí phẳng ban đầu (`rotateX(0deg) rotateY(0deg)`).
- **Rationale**: Đảm bảo tốc độ tải trang nhanh tuyệt đối cho một trang Landing Page phân phối chính thức, tương thích hoàn hảo với DOM Pointer Events kéo thả cửa sổ ảo mà không gặp sự cố z-index hay tọa độ pixel giữa Three.js canvas và DOM.

### ASM-WEB-005 — Top-Edge Snap Layout Picker Scope & Templates

- **Decision**: Tái hiện **đầy đủ cả 4 mẫu bố cục (Layout Templates)** chuẩn mực như ứng dụng native FlowSnap:
  1. **Template 1 (2 Cột 50/50)**: Phân vùng Trái 50% và Phải 50%.
  2. **Template 2 (2 Cột Bất đối xứng 70/30)**: Phân vùng Trái 70% và Phải 30%.
  3. **Template 3 (3 Cột Ngang 25/50/25)**: Phân vùng Cột Trái 25%, Cột Giữa 50%, Cột Phải 25%.
  4. **Template 4 (4 Góc Quarters 25%)**: Top-Left, Top-Right, Bottom-Left, Bottom-Right.
  5. **Interaction Flow**:
     - Khi người dùng kéo thanh tiêu đề cửa sổ ảo (Mock Window) chạm vùng kích hoạt ở đỉnh màn hình (ngưỡng Y <= 32px), khay Top-Edge Snap Picker trượt xuống từ cạnh trên với hiệu ứng spring mượt mà.
     - Khi con trỏ chuột hover vào từng ô cụ thể trong bất kỳ template nào, ô đó sẽ phát sáng highlight viền xanh `--accent-blue` đồng thời hiển thị ngay lớp phủ **HUD Snap Preview** bán trong suốt trên toàn màn hình tương ứng với ô đang chọn.
     - Khi nhả chuột (`pointerup`) bên trong ô đó, cửa sổ ảo lập tức snap và co giãn kích thước về đúng phân vùng tương ứng, khay picker tự động thu gọn biến mất.
- **Rationale**: Trải nghiệm trọn vẹn sức mạnh khác biệt (Differentiator) của FlowSnap trên web, chứng minh khả năng quản lý layout vượt trội so với các công cụ window manager khác trên macOS.

### ASM-WEB-006 — Mock Window Content & Interactive States

- **Decision**: Cửa sổ ảo hiển thị giao diện **Mini Code Editor / Developer Workspace** phong cách macOS chân thực:
  1. **Mac Window Chrome**:
     - Traffic lights chuẩn xác (Red, Yellow, Green) với nút Green hỗ trợ click để Maximize / Restore.
     - Thanh tiêu đề (Titlebar) có icon app, tên file `FlowSnapEngine.swift — Workspace Active`, và nhãn badge trạng thái snap hiện tại.
  2. **Editor Body**:
     - Hiển thị đoạn code Swift ngắn gọn, súc tích với cú pháp syntax highlighting tinh tế thể hiện triết lý của FlowSnap (`struct SnapEngine`, `@MainActor`, `let windowManager = WindowManager()`).
     - Thanh trạng thái dưới cùng (Status Bar): hiển thị kích thước hiện tại (Width x Height), trạng thái `Zone: Left 50%` hoặc `Zone: Free Float`, và nút thao tác nhanh `Reset Sandbox`.
  3. **Drag & Drop Engine**:
     - Hỗ trợ kéo thả tự do bằng chuột và cảm ứng (`PointerEvents` với `setPointerCapture`) không bị tuột chuột khi rê nhanh.
     - Kéo sát mép màn hình: Kéo sang mép trái/phải sẽ tự động kích hoạt HUD Snap Preview 50%; kéo lên mép trên kích hoạt Top-Edge Picker; kéo ra giữa trả về trạng thái thả tự do.
  4. **Action Controls**:
     - Nút **Reset Window / Reset Sandbox** hiển thị rõ ràng trên thanh điều khiển của Sandbox để người dùng có thể đưa cửa sổ về vị trí giữa màn hình bất cứ lúc nào.
- **Rationale**: Tạo cảm giác quen thuộc, thân thiện với lập trình viên và power users (khách hàng mục tiêu chính của FlowSnap), truyền tải thông điệp về tốc độ và chất lượng kỹ thuật của sản phẩm.

### ASM-WEB-007 — Multi-Window Concurrency & Dock App Launching (Grilling Confirmed)

- **Decision**: Hỗ trợ mở và tương tác đồng thời **nhiều cửa sổ độc lập** (VS Code, Terminal, Finder):
  1. **Window 1 (VS Code)**: Cửa sổ Mini Code Editor (`SnapEngine.swift`).
  2. **Window 2 (Terminal)**: Cửa sổ macOS Terminal màu đen tuyền với prompt `~ % flowsnap status`, hỗ trợ kéo thả và snap độc lập.
  3. **Dock Launch & Focus**:
     - Nhấp icon VS Code: Mở hoặc đưa cửa sổ VS Code lên lớp trên cùng (`z-index: 35`), đánh dấu làm `activeWindow`.
     - Nhấp icon Terminal: Mở hoặc đưa cửa sổ Terminal lên lớp trên cùng, đánh dấu làm `activeWindow`.
     - Nhấp icon Finder: Đóng/mở hoặc chuyển tiêu điểm.
  4. **Multi-Window Tiling Demonstration**:
     - Cho phép người dùng kéo cửa sổ VS Code sang Trái 50% (hoặc 70%), kéo cửa sổ Terminal sang Phải 50% (hoặc 30%) để trải nghiệm thực tế khả năng xếp cạnh nhau (Tiling Window Management) hoàn hảo của FlowSnap.
- **Rationale**: Khách truy cập web cần được tự tay trải nghiệm sức mạnh xếp 2 cửa sổ cạnh nhau (song song) thay vì chỉ một cửa sổ đơn lẻ.

### ASM-WEB-008 — FlowSnap Native Menu Bar Popover (Grilling Confirmed)

- **Decision**: Khi người dùng nhấp vào biểu tượng FlowSnap trên thanh Menu Bar ảo (hoặc icon FlowSnap trên Dock):
  1. Mở ra **FlowSnap Visual Snap Popover** chuẩn macOS ngay dưới icon:
     - Hiển thị tiêu đề `FlowSnap — Active Window: [Tên cửa sổ đang chọn]`.
     - **Visual Snap Grid**: Lưới các nút đồ họa trực quan (Trái 1/2, Phải 1/2, Trái 70%, Phải 30%, 3 Cột, 4 Góc, Maximize).
     - **Workflow Presets**: Phím tắt nhanh cho Coding (60/25/15), Research (50/25/25), Writing (70/30).
     - **Tương tác trực tiếp**: Nhấp vào bất kỳ ô nào trong Popover sẽ snap ngay lập tức cửa sổ đang focus (`activeWindow`) vào vị trí đó, kèm hiệu ứng haptic/phản hồi thị giác.
     - Nhấp ra ngoài popover để đóng lại tự nhiên như macOS.
- **Rationale**: Thể hiện trực tiếp tính năng cốt lõi của FlowSnap (`EPIC 05: Menu Bar Quick Controls` và `UI-MODERN`), giúp người dùng hiểu cách app hoạt động thật trên macOS chỉ trong 3 giây.

### ASM-WEB-009 — 70/30 Layout Ratio Precision & GPU Smooth Physics (Grilling Confirmed)

- **Decision**:
  1. **Tỷ lệ 70/30**: Sửa triệt để lỗi CSS `.snap-zone-btn` bị `flex: 1` cưỡng ép thành 50/50. Trong template 70/30, ô bên trái có tỷ lệ `width: 70%` (hoặc `flex: 7`), ô phải `width: 30%` (hoặc `flex: 3`). Trong template 3 cột, ô giữa có `width: 50%` và 2 bên `25%`.
  2. **Độ mượt mà (Physics Engine)**:
     - Loại bỏ CSS transitions trên cửa sổ trong lúc đang kéo (`is-dragging`).
     - Sử dụng `requestAnimationFrame` điều tiết sự kiện chuột để đạt 120 FPS.
     - Quản lý `activeWindowId` chuẩn xác, đưa cửa sổ đang kéo lên `z-index` cao nhất.
- **Rationale**: Đảm bảo trải nghiệm thị giác sắc sảo, chính xác đến từng pixel và cực kỳ mượt mà, không giật lag.

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Tỷ lệ khung màn hình ảo (Aspect Ratio)**: Tỷ lệ chuẩn macOS Liquid Retina 16:10, bo góc tròn 16px với viền hairline tinh xảo.
- **Menu Bar ảo**: Hiển thị thanh menu macOS với logo Apple, tên `FlowSnap`, các menu ảo `File`, `Edit`, `Layout`, `Window`, và biểu tượng Menu Bar icon FlowSnap góc phải.
- **Dock ảo**: Dock mô phỏng dạng kính mờ (Liquid Glass) nằm ở đáy màn hình với các icon ứng dụng đại diện (Finder, FlowSnap, VS Code, Terminal).
- **HUD Snap Preview**: Lớp phủ kính mờ bán trong suốt (Liquid Glass HUD) với viền bo tròn, hiệu ứng spring transition khi xuất hiện và biến mất.
- **Touch / Mobile Compatibility**: Trên màn hình di động nhỏ (< 768px), vô hiệu hóa hiệu ứng tilt 3D phức tạp, hiển thị sandbox ở chế độ touch-drag tối ưu hoặc cung cấp các nút bấm Snap trực tiếp để người dùng điện thoại vẫn trải nghiệm được tính năng.
