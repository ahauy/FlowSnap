# Elicitation Notes: US-SNAP-006

## Stage 1 — Business Value

- **Problem & Pain Point**: Việc di chuyển và bố trí cửa sổ chỉ bằng phím tắt gây rào cản cho người dùng thiên về thao tác chuột/trackpad. Thiếu tính năng kéo cửa sổ vào mép màn hình (Drag-to-Snap) và xem trước vùng snap trực quan (HUD Preview) làm giảm tính trực quan và giảm 50% tính tiện dụng của một window manager hiện đại trên macOS.
- **Target Personas**: Toàn bộ người dùng Mac (Nam, Trang, Hải), đặc biệt người dùng trackpad/chuột không muốn nhớ nhiều tổ hợp phím tắt.
- **Success Metrics**:
  - Độ trễ phát hiện mép < 16ms (đáp ứng 60fps khi kéo chuột).
  - Ngưỡng kích hoạt biên chuẩn xác (cách mép 4px, dwell time 100ms cho viền ngoài).
  - Không làm rò rỉ bộ nhớ hoặc tăng tải CPU (< 1% CPU khi drag).
  - Tự động ẩn HUD preview mượt mà khi kéo chuột ra khỏi vùng biên hoặc khi nhả chuột.

## Pillar Decisions (Confirmed by User)

### 1. Edge Detection Mechanism & Event Interception

- **Decision**: **Option A** — Sử dụng `NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp])` kết hợp kiểm tra vị trí con trỏ chuột (`NSEvent.mouseLocation`). Xử lý throttling ở tần số 60fps (~16ms).
- **Rationale**: An toàn, nhẹ, thuần Swift/AppKit, tận dụng quyền Accessibility đã có, tránh lỗi timeout và crash luồng của C callback `CGEventTap`.

### 2. Multi-Monitor Boundary Drag Behavior

- **Decision**: **Option A** — Phân biệt cạnh biên ngoài cùng (Outer boundary) và cạnh tiếp giáp giữa các màn hình (Internal adjacent boundary). Cạnh tiếp giáp có độ trễ kích hoạt dài hơn (250ms dwell) để người dùng dễ dàng kéo cửa sổ xuyên qua các màn hình mà không bị snap ngoài ý muốn; cạnh ngoài cùng kích hoạt nhanh (100ms).
- **Rationale**: Đảm bảo trải nghiệm tự nhiên, chống khựng cửa sổ khi di chuyển qua lại giữa nhiều màn hình.

### 3. HUD Snap Preview Styling & Animation

- **Decision**: **Option A** — Lớp phủ `SnapPreviewPanel` sử dụng hiệu ứng mờ kính Liquid Glass (`NSVisualEffectView` với material `.hudWindow`), bo góc 10px, viền viền sáng 1.5px màu `Color.accentColor`, cùng hiệu ứng fade-in / fade-out mượt mà 150ms.
- **Rationale**: Thẩm mỹ macOS native cao cấp, đồng bộ với phong cách thiết kế của macOS Sonoma / Sequoia, tuân thủ nghiêm ngặt Anti-AI-Slop.

## Assumptions Confirmed

- **ASM-SNAP-001**: Lắng nghe sự kiện kéo chuột toàn cục qua `NSEvent.addGlobalMonitorForEvents` chỉ hoạt động khi ứng dụng có quyền Trợ năng (Accessibility Trusted), tương thích hoàn hảo với `AccessibilityService`.
- **ASM-SNAP-002**: Vùng biên kích hoạt snap (Edge Trigger Zone) có độ dày 4px từ mép màn hình khả dụng (`visibleFrame` hoặc `frame`), phân định 8 vùng snap: Left, Right, Top (Maximize), Bottom, và 4 góc (Top-Left, Top-Right, Bottom-Left, Bottom-Right).
- **ASM-SNAP-003**: `SnapPreviewPanel` là `NSPanel` dạng non-activating (`.nonactivatingPanel`), level `.floating`, không nhận sự kiện chuột (`ignoresMouseEvents = true`), tuyệt đối không chiếm key focus của cửa sổ đang kéo.
- **ASM-SNAP-004**: Khi nhả chuột (`leftMouseUp`), nếu đang có vùng preview hiển thị, hệ thống tự động gọi `SnapEngine.shared.snap(window:target:)` để snap cửa sổ và ẩn preview ngay lập tức.

## Open Questions

- _None_ — Tất cả các quyết định nghiệp vụ và kiến trúc đã được làm rõ và xác nhận 100%.
