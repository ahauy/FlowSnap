# Risk Register & MoSCoW Scope: US-SNAP-006

## 1. Risk Register

| Risk ID           | Description                                                            |  Impact  | Probability | Mitigation Strategy                                                                                         |    Status     |
| :---------------- | :--------------------------------------------------------------------- | :------: | :---------: | :---------------------------------------------------------------------------------------------------------- | :-----------: |
| **RISK-SNAP-001** | Mouse drag event flood causing CPU spikes or UI stutter                |   High   |     Med     | Throttle drag event processing at 60fps (~16ms cadence) and avoid heavy calculations during active drag     | **Mitigated** |
| **RISK-SNAP-002** | Accidental snap trigger when dragging windows across adjacent monitors |   High   |    High     | Detect adjacent display boundaries and apply a 250ms dwell timeout instead of instant 100ms outer threshold | **Mitigated** |
| **RISK-SNAP-003** | Preview panel steals key window focus from the dragged window          | Critical |     Low     | Use `NSPanel` with `.nonactivatingPanel`, `ignoresMouseEvents = true`, and `level = .floating`              | **Mitigated** |
| **RISK-SNAP-004** | AppKit mouse coordinate flip mismatch with AX display frames           |   High   |     Med     | Leverage existing `CoordinateTransformer` pure math functions to convert coordinates accurately             | **Mitigated** |
| **RISK-SNAP-005** | Left mouse up missed if dropped outside monitor frame                  |   Med    |     Low     | Fallback mouse up check and automatic preview dismissal on focus change or escape key                       | **Mitigated** |

---

## 2. MoSCoW Scope Alignment

### Must-Have

- [x] Lắng nghe sự kiện kéo chuột toàn cục (`NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp])`).
- [x] Nhận diện 8 vùng biên màn hình (Left, Right, Top/Maximize, Bottom, 4 Corners) với ngưỡng 4px.
- [x] Hiển thị lớp phủ xem trước `SnapPreviewPanel` với phong cách Liquid Glass mờ kính cao cấp.
- [x] Snap cửa sổ tự động vào vùng mục tiêu khi nhả chuột (`leftMouseUp`).
- [x] Tự động ẩn xem trước khi kéo chuột ra khỏi vùng biên (> 20px).

### Should-Have

- [x] Phân biệt cạnh biên ngoài (100ms dwell) và cạnh tiếp giáp đa màn hình (250ms dwell).
- [x] Hiệu ứng animation chuyển đổi mượt mà (fade-in 150ms, fade-out 150ms).

### Could-Have

- [ ] Tùy biến độ nhạy cạnh biên (Edge threshold 2px–10px) trong Settings (dành cho US-SNAP-010).

### Won't-Have (in this Story)

- ❌ Top-edge Windows 11 Layout Picker (thuộc `US-SNAP-007`).
- ❌ Tùy biến tỷ lệ chia 60/40, 70/30 khi kéo chuột (thuộc `US-SNAP-008`).
- ❌ Thay đổi kích thước nhiều cửa sổ chung đường biên (thuộc `US-SNAP-009`).
