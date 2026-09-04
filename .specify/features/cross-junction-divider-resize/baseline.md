# Domain Baseline: Multi-Window T-Junction & Crosshair Divider Resize

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0
- **Feature Slug**: `cross-junction-divider-resize`
- **Related Roadmap Item**: `US-SNAP-023` (EPIC 2 Extension — 4-Way Multi-Window Crosshair Drag)

---

## 1. Domain Summary

Nâng cấp bộ điều phối dải phân cách thích ứng ([`AdaptiveDividerCoordinator`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/AdaptiveDividerCoordinator.swift)) và bộ dò cạnh ([`CollinearEdgeDetector`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/CollinearEdgeDetector.swift)) để hỗ trợ **thao tác kéo 2 chiều 4 hướng (4-Way 2D Crosshair Drag)** tại các điểm giao nhau (ngã ba T-Junction hoặc ngã tư Cross Junction) giữa 3 hoặc 4 cửa sổ:

1. **Junction Detection (`CrossJunction`)**: Tự động nhận diện điểm giao cắt giữa dải phân cách dọc và dải phân cách ngang của các cửa sổ ghép đôi.
2. **Visual Crosshair Affordance**: Khi rê chuột trong bán kính $\pm 14\,\text{pt}$ của điểm giao nhau, hiển thị con trỏ chữ thập (`NSCursor.crosshair`) và vẽ một điểm neo sáng (illuminated accent handle pill) tại giao điểm.
3. **Decoupled 2D Simultaneous Resizing**: Khi người dùng nhấn kéo điểm neo, cả chiều rộng (X) và chiều cao (Y) của 3 hoặc 4 cửa sổ tham gia đều được tính toán và co dãn đồng thời mượt mà ở 60–120 FPS.
4. **Independent-Axis Clamping**: Khi bất kỳ cửa sổ nào chạm giới hạn kích thước tối thiểu (`minSize`) theo trục X, trục X sẽ dừng lại (clamp) trong khi trục Y vẫn tiếp tục di chuyển tự do (và ngược lại), loại bỏ hoàn toàn hiện tượng kẹt chuột.
5. **Escape Key Cancellation**: Bấm `⎋ Escape` trong lúc đang kéo sẽ phục hồi tức thì toàn bộ khung ban đầu của các cửa sổ và đóng overlay.

---

## 2. Business Rules Reference

- **BR-CJR-001**: Junction Detection — Nhận diện điểm giao cắt giữa các dải phân cách dọc và ngang.
- **BR-CJR-002**: Proximity Priority — Ưu tiên thao tác 4 chiều khi chuột nằm trong bán kính $\le 14\,\text{pt}$ của giao điểm.
- **BR-CJR-003**: Visual Affordance — Hiển thị `NSCursor.crosshair` và accent handle pill tại giao điểm.
- **BR-CJR-004**: Decoupled 2D Resizing — Co dãn đồng thời 2 chiều với cơ chế clamping độc lập từng trục.
- **BR-CJR-005**: Atomic Cancellation — Nhấn `⎋ Escape` hủy thao tác và khôi phục frame gốc.
- **BR-CJR-006**: Non-Resizable Window Safety — Loại trừ cửa sổ cố định khỏi việc co dãn giao điểm.

---

## 3. Assumptions Register

- `ASM-CJR-001`: Visual junction handle pill and crosshair cursor affordance.
- `ASM-CJR-002`: Independent per-axis minSize clamping.
- `ASM-CJR-003`: 14pt proximity priority for 2D junction drag over 1D edge drag.

---

## 4. Scope (MoSCoW)

- **Must-Have**:
  - Entity `CrossJunction` trong Domain model.
  - Mở rộng `CollinearEdgeDetector` để nhận diện `detectJunctions` và tính toán `compute2DResizedFrames`.
  - Mở rộng `AdaptiveDividerOverlayPanel` để vẽ điểm neo chữ thập / handle pill tại giao điểm.
  - Tích hợp vào `AdaptiveDividerCoordinator` (xử lý hover, cursor `.crosshair`, mouseDown, mouseDragged, mouseUp, Escape cancel).
  - Test suite đầy đủ kiểm thử 3-window T-junction và 4-window cross-junction.
- **Won't-Have**:
  - Co dãn với cửa sổ trôi nổi tự do không nằm trong lưới snapping.
