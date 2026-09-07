# Domain Baseline: 3D Interactive macOS Desktop Simulator (US-WEB-026)

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0 (Confirmation Gate 1 Approved)
- **Feature Slug**: `web-desktop-sandbox`
- **Related Roadmap Item**: `US-WEB-026` (EPIC 16 — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal)

---

## 1. Domain Summary

Xây dựng module giả lập màn hình macOS 3D tương tác (Hero Interactive Sandbox) tích hợp trực tiếp trên trang chủ FlowSnap (`web/src/components/DesktopSimulator.astro`):

1. **Khung Màn Hình macOS Ảo (macOS Virtual Desktop)**:
   - Tỷ lệ chuẩn macOS 16:10, bo góc tròn 16px, viền hairline 1px siêu mảnh (`var(--border-color)`), đổ bóng chiều sâu cao cấp.
   - Thanh Menu Bar ảo ở đỉnh với logo Apple, tên FlowSnap, menu hệ thống và biểu tượng FlowSnap Status Item góc phải.
   - Dock ảo đáy màn hình hiệu ứng kính mờ (Liquid Glass) với các ứng dụng Finder, FlowSnap, VS Code, Terminal.
2. **Cửa Sổ Ảo Kéo Thả Tự Do (Interactive Mock Window — `BR-SANDBOX-001`, `002`)**:
   - Giao diện Mini Code Editor / Dev Workspace: thanh tiêu đề macOS với 3 nút traffic lights (Red/Yellow/Green), nút Green hỗ trợ click để Maximize/Restore.
   - Nội dung hiển thị code Swift ngắn gọn với syntax highlighting (`struct SnapEngine`, `@MainActor`).
   - Kéo thả tự do bằng chuột và cảm ứng đa điểm (`PointerEvents` với `setPointerCapture`) bảo đảm không bị trượt chuột khi rê nhanh.
3. **Bộ Chọn Bố Cục Cạnh Trên (Windows 11-Style Top-Edge Layout Picker — `BR-SANDBOX-002`)**:
   - Khi kéo thanh tiêu đề chạm dải mép trên (`Y <= 32px`), khay picker trượt xuống mượt mà từ cạnh trên.
   - Tái hiện đầy đủ cả 4 mẫu layout templates chuẩn FlowSnap:
     - 2 Cột (50/50)
     - 2 Cột bất đối xứng (70/30)
     - 3 Cột (25/50/25)
     - 4 Góc (25% mỗi góc)
4. **Lớp Phủ Kính Mờ Đón Trước (Translucent HUD Snap Preview — `BR-SANDBOX-003`)**:
   - Khi hover vào một ô trong Top-Edge Picker hoặc kéo sát mép trái/phải màn hình (< 24px), lớp phủ kính mờ hiện ra đón trước vị trí snap với animation spring.
   - Nhả chuột (`pointerup`) sẽ snap cửa sổ tức thì vào vùng tương ứng, cập nhật nhãn trạng thái và thu gọn picker.
5. **Hiệu Ứng 3D Perspective Tilt & Ngân Sách Năng Lượng (Zero-Idle CPU — `BR-SANDBOX-005`)**:
   - Áp dụng Hardware-Accelerated CSS 3D Transforms (`perspective`, `rotateX`, `rotateY`) phản hồi tinh tế theo con trỏ chuột khi không kéo cửa sổ.
   - Tự động ngắt toàn bộ animation loop và tracking bằng `IntersectionObserver` khi cuộn khỏi màn hình (đảm bảo 0.0% idle CPU).
6. **Điều Khiển Tiện Ích & Phục Hồi (Reset Sandbox & Mobile Controls — `BR-SANDBOX-006`, `007`)**:
   - Nút `Reset Sandbox` luôn sẵn sàng để đưa cửa sổ về vị trí tự do trung tâm (Width 52%, Height 56%).
   - Cung cấp dải nút bấm Quick Snap trên màn hình di động (< 768px).

---

## 2. Business Rules Reference

- **`BR-SANDBOX-001`**: Zero Mouse Slip via Pointer Capture (`setPointerCapture` / `releasePointerCapture`).
- **`BR-SANDBOX-002`**: Top-Edge Picker Activation Threshold (Y <= 32px, 4 layout templates).
- **`BR-SANDBOX-003`**: Real-time HUD Preview Responsiveness (Spring transition, translucent liquid glass).
- **`BR-SANDBOX-004`**: Snap Transition Physics (0.28s spring animation, instant unsnap on new drag).
- **`BR-SANDBOX-005`**: 0.0% Idle CPU Budget & IntersectionObserver (Disconnect listeners when out of viewport).
- **`BR-SANDBOX-006`**: One-Click Reset Guarantees (Instant restore to center 52%x56%).
- **`BR-SANDBOX-007`**: Touch & Mobile Quick Actions Fallback (Pill buttons on mobile viewports).

---

## 3. Assumptions Register

- **`ASM-WEB-004`**: Hardware-Accelerated CSS 3D Transforms with pointer tracking (zero extra bundle, 120 FPS, 0.0% idle CPU via IntersectionObserver).
- **`ASM-WEB-005`**: Full 4 layout templates in Top-Edge Snap Picker (50/50, 70/30, 3-column, 4-corner).
- **`ASM-WEB-006`**: Mini Code Editor mockup content inside Mock Window with traffic lights, Swift syntax highlighting, and snap status badge.

---

## 4. Scope Boundary (MoSCoW)

- **Must-Have**:
  - `web/src/components/DesktopSimulator.astro` hoàn chỉnh.
  - Tích hợp thay thế placeholder box `#showcase` trong `web/src/pages/index.astro`.
  - Cửa sổ ảo kéo thả mượt mà với Pointer Events và `setPointerCapture`.
  - Khay Top-Edge Snap Picker đầy đủ 4 mẫu template.
  - Lớp phủ HUD Snap Preview mờ kính với animation spring.
  - Nút Reset Sandbox và hỗ trợ mobile viewport.
  - Đảm bảo `npm run build` trong `web/` biên dịch sạch sẽ.
- **Should-Have**:
  - CSS 3D perspective tilt phản hồi theo chuột khi không kéo cửa sổ.
  - `IntersectionObserver` tự động ngắt tracking khi cuộn khỏi màn hình.
- **Won't-Have**:
  - ❌ Kéo thả đồng thời nhiều cửa sổ ảo (chỉ 1 cửa sổ hero).
  - ❌ Nạp WebGL Three.js bundle nặng nề (thay bằng CSS 3D hardware-accelerated).
  - ❌ Hiệu ứng âm thanh khi snap.
