# 05 — Risk Register, Contradictions & Scope Boundary (US-WEB-026)

## 1. Risk Register

| Risk ID              | Description                                                                                | Severity | Likelihood | Mitigation Strategy                                                                                                                                                                                   |
| :------------------- | :----------------------------------------------------------------------------------------- | :------: | :--------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-SANDBOX-001** | Kéo thả trên màn hình cảm ứng di động bị xung đột với cuộn trang (page scroll).            |   High   |   Medium   | Sử dụng `touch-action: none` trên thanh tiêu đề kéo (titlebar); trên mobile (< 768px) cung cấp thêm cụm nút Quick Snap Actions tiện dụng.                                                             |
| **RISK-SANDBOX-002** | Rê chuột nhanh gây drop FPS hoặc ngốn CPU khi tính toán 3D tilt và tọa độ drag.            |  Medium  |    Low     | Đóng gói render vào `requestAnimationFrame`, dùng CSS 3D Transforms `transform: rotateX(...) rotateY(...)` tận dụng GPU compositor, ngắt hoàn toàn qua `IntersectionObserver` khi cuộn khỏi màn hình. |
| **RISK-SANDBOX-003** | Khung macOS ảo bị lệch màu hoặc vỡ tương phản khi người dùng chuyển đổi Dark / Light mode. |  Medium  |    Low     | Kế thừa 100% biến semantic CSS từ `design-tokens.css` (`--surface-elevated`, `--border-color`, `--text-primary`, `--glass-bg`). Màn hình ảo và thanh Menu Bar tự động thích ứng với theme hiện tại.   |
| **RISK-SANDBOX-004** | Trượt chuột ra khỏi khung màn hình ảo khi người dùng kéo vung tay quá nhanh.               |  Medium  |   Medium   | Sử dụng `setPointerCapture(e.pointerId)` ngay khi `pointerdown` để khóa luồng sự kiện vào thanh titlebar cho đến khi `pointerup`.                                                                     |

## 2. Contradiction & Edge-Case Scan

- **Contradiction 1: 3D Perspective Tilt vs Dragging Precision**:
  - _Vấn đề_: Khi container đang nghiêng 3D (`rotateX`, `rotateY`), tọa độ chuột `clientX/clientY` có thể bị sai lệch nhẹ so với mặt phẳng 2D của cửa sổ ảo nếu tính toán trực tiếp.
  - _Giải pháp_: Trong lúc người dùng đang giữ chuột kéo cửa sổ (`isDragging = true`), tạm thời đưa góc nghiêng về `rotateX(0deg) rotateY(0deg)` hoặc áp dụng delta chuyển động tương đối `(dx, dy)` thay vì tọa độ tuyệt đối.
- **Contradiction 2: Top-Edge Trigger vs Menu Bar Overlap**:
  - _Vấn đề_: Cạnh trên của màn hình ảo có thanh Menu Bar. Nếu người dùng kéo chạm Menu Bar thì khay picker có đè lên Menu Bar không?
  - _Giải pháp_: Khay Top-Edge Snap Picker trượt xuống ngay bên dưới Menu Bar ảo (khoảng cách Y = 28px), hiển thị lớp phủ nổi bật với bóng đổ mềm và nền kính mờ macOS Liquid Glass.

## 3. Scope Boundary (MoSCoW)

### Must-Have

- [x] Khung màn hình macOS ảo tỷ lệ 16:10 với Menu Bar ảo, Dock kính mờ và wallpaper thẩm mỹ.
- [x] Cửa sổ ảo (Mock Window) hiển thị giao diện Mini Code Editor / Dev Workspace với traffic lights (đỏ/vàng/xanh).
- [x] Cơ chế kéo thả mượt mà với Pointer Events API và `setPointerCapture`.
- [x] Khay Top-Edge Snap Layout Picker hiển thị đầy đủ 4 mẫu bố cục (50/50, 70/30, 3 cột, 4 góc).
- [x] Lớp phủ HUD Snap Preview bán trong suốt đón trước vị trí snap khi hover ô layout hoặc chạm mép trái/phải.
- [x] Nút Reset Sandbox đưa cửa sổ về vị trí giữa màn hình bất cứ lúc nào.

### Should-Have

- [x] Hiệu ứng 3D perspective tilt mượt mà theo con trỏ chuột khi không kéo cửa sổ.
- [x] Cơ chế tạm dừng tự động (0.0% Idle CPU) với `IntersectionObserver` khi cuộn khỏi màn hình.
- [x] Nút bấm Quick Snap Actions dự phòng cho người dùng trên thiết bị di động.

### Won't-Have (v1.0 of Web Showcase)

- ❌ Kéo thả đồng thời nhiều cửa sổ (chỉ tập trung vào 1 cửa sổ mock window chính để tối ưu hiệu năng).
- ❌ Cài đặt nặng Three.js WebGL bundle (thống nhất sử dụng CSS 3D hardware-accelerated theo quyết định ASM-WEB-004).
- ❌ Tải file âm thanh hệ thống (sound effects) khi snap (tránh gây phiền toái cho khách truy cập web).
