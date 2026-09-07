# 06 — System Requirements & User Stories: 3D Interactive macOS Desktop Simulator (US-WEB-026)

## 1. System Requirements (`REQ-SANDBOX-###`)

- **REQ-SANDBOX-001 (macOS Desktop Container)**:
  - Hệ thống phải hiển thị một khung giả lập màn hình macOS tỷ lệ 16:10 với thanh Menu Bar (logo Apple, tên FlowSnap, menu ảo và FlowSnap status item), Dock mờ kính đáy màn hình, và hình nền tối giản phù hợp cả Dark và Light mode.
  - _Derived from_: `US-WEB-026` AC 1, `ASM-WEB-006`.

- **REQ-SANDBOX-002 (Draggable Mock Window with Code Content)**:
  - Hệ thống phải hiển thị một cửa sổ ảo mô phỏng Mini Code Editor với thanh tiêu đề có traffic lights chuẩn macOS (Red, Yellow, Green), tên file `FlowSnapEngine.swift`, badge trạng thái snap, và phần nội dung code Swift có syntax highlighting.
  - Cửa sổ phải kéo thả được tự do bằng Pointer Events với `setPointerCapture`.
  - _Derived from_: `US-WEB-026` AC 2, `ASM-WEB-006`, `BR-SANDBOX-001`.

- **REQ-SANDBOX-003 (Top-Edge Snap Layout Picker)**:
  - Khi kéo cửa sổ ảo chạm dải mép trên của màn hình ảo (`cursorY <= 32px`), khay Top-Edge Picker phải trượt xuống mượt mà và hiển thị đầy đủ 4 mẫu bố cục: 2 cột (50/50), 2 cột bất đối xứng (70/30), 3 cột (25/50/25), và 4 góc (25% mỗi góc).
  - _Derived from_: `US-WEB-026` AC 3, `ASM-WEB-005`, `BR-SANDBOX-002`.

- **REQ-SANDBOX-004 (Real-time Translucent HUD Snap Preview)**:
  - Khi hover vào một ô trong Top-Edge Picker hoặc kéo sát mép màn hình trái/phải, hệ thống phải hiển thị lớp phủ HUD Preview mờ kính tại vị trí tương ứng trước khi người dùng nhả chuột.
  - _Derived from_: `US-WEB-026` AC 4, `ASM-WEB-005`, `BR-SANDBOX-003`.

- **REQ-SANDBOX-005 (Snap Execution & Window Resizing)**:
  - Khi nhả chuột trong ô layout hoặc vùng snap, cửa sổ ảo phải snap tức thì vào vùng đã chọn với animation spring mượt mà, đồng thời cập nhật badge trạng thái.
  - Nhấp kéo lại cửa sổ đã snap phải tự động trả về kích thước tự do.
  - _Derived from_: `US-WEB-026` AC 3, `BR-SANDBOX-004`.

- **REQ-SANDBOX-006 (Hardware-Accelerated 3D Perspective Tilt & Zero-Idle Pause)**:
  - Khung container phải hỗ trợ hiệu ứng nghiêng 3D (perspective tilt) phản hồi mượt mà theo vị trí con trỏ chuột khi không kéo cửa sổ.
  - Phải sử dụng `IntersectionObserver` để tự động ngắt tính toán khi khung container nằm ngoài viewport (đảm bảo 0.0% idle CPU).
  - _Derived from_: `US-WEB-026` AC 5, `ASM-WEB-004`, `BR-SANDBOX-005`.

- **REQ-SANDBOX-007 (Reset Sandbox & Mobile Support)**:
  - Cung cấp nút `Reset Sandbox` đưa cửa sổ về vị trí giữa mặc định.
  - Cung cấp cụm nút Quick Snap hỗ trợ người dùng trên thiết bị di động / màn hình nhỏ.
  - _Derived from_: `US-WEB-026` AC 6, `BR-SANDBOX-006`, `BR-SANDBOX-007`.

---

## 2. User Stories & Acceptance Scenarios

### US-SANDBOX-001: Kéo thả cửa sổ ảo và kích hoạt Top-Edge Layout Picker

- **Given**: Khách truy cập đang ở trang chủ FlowSnap và cuộn tới phần `#showcase`.
- **When**: Người dùng nhấn giữ chuột vào thanh tiêu đề của cửa sổ ảo và kéo lên đỉnh màn hình (`Y <= 32px`).
- **Then**:
  - Khay Top-Edge Snap Picker trượt xuống mượt mà với 4 mẫu template.
  - Con trỏ chuột không bị trượt mất nhờ `setPointerCapture`.

### US-SANDBOX-002: Xem trước HUD Snap Preview và Snap vào vùng chọn

- **Given**: Cửa sổ ảo đang ở trạng thái kéo và khay Top-Edge Picker đang mở.
- **When**: Người dùng rê chuột vào ô "Left 50%" trong template 2 cột.
- **Then**:
  - Ô "Left 50%" phát sáng highlight viền xanh `--accent-blue`.
  - Lớp phủ HUD Preview mờ kính hiện ra phủ đúng 50% nửa trái màn hình ảo.
- **When**: Người dùng nhả chuột (`pointerup`).
- **Then**:
  - Cửa sổ ảo lập tức snap và co giãn về đúng nửa trái màn hình với animation spring.
  - Khay Top-Edge Picker tự động thu gọn biến mất.
  - Badge trạng thái trên thanh tiêu đề đổi thành `Zone: Left 50%`.

### US-SANDBOX-003: Hiệu ứng 3D Perspective Tilt và tự động dừng khi khuất màn hình

- **Given**: Người dùng di chuyển chuột trên vùng Desktop Simulator mà không nhấn giữ kéo cửa sổ.
- **When**: Con trỏ chuột di chuyển từ trái sang phải, từ trên xuống dưới.
- **Then**:
  - Khung màn hình nghiêng nhẹ theo không gian 3D (`rotateX`, `rotateY`) tạo chiều sâu thị giác cao cấp.
- **When**: Người dùng cuộn trang xuống các phần tiếp theo khiến Simulator nằm ngoài màn hình.
- **Then**:
  - `IntersectionObserver` phát hiện và ngắt tính toán tilt, đảm bảo CPU sử dụng ở mức 0.0%.

### US-SANDBOX-004: Khôi phục trạng thái với nút Reset Sandbox

- **Given**: Cửa sổ ảo đang ở trạng thái đã snap chiếm một phân vùng bất kỳ.
- **When**: Người dùng nhấn nút `Reset Sandbox`.
- **Then**:
  - Cửa sổ ảo trôi mượt mà về vị trí tự do trung tâm (Width 52%, Height 56%).
  - Lớp HUD Preview ẩn hoàn toàn và badge hiển thị `Zone: Free Float`.
