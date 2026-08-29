# Domain Baseline: US-SNAP-007 Top-Edge Snap Layout Picker

> **Status:** SIGNED-OFF v1.0  
> **Version:** 1.0.0  
> **Feature Slug:** `top-edge-layout-picker`  
> **Author:** Business Analyst & macOS System Architect  
> **Target Epic:** `EPIC 07: Windows 11-Style Top-Edge Snap Layout Picker`

---

## 1. Executive Summary & Business Goal

Cung cấp tính năng khay chọn bố cục trực quan phong cách Windows 11 khi kéo cửa sổ lên dải đỉnh trung tâm (Top-Center Zone) của màn hình. Giúp người dùng chọn ngay các phân vùng phức tạp (70/30, 3 cột 1/3, 4 góc 2x2, 50/50) chỉ bằng một cử chỉ kéo thả chuột duy nhất mà không cần nhớ tổ hợp phím tắt.

---

## 2. Core Capabilities & Acceptance Criteria

1. **Top-Center Activation Zone**: Khi kéo cửa sổ vào khu vực 40% giữa cạnh trên màn hình (tọa độ y cách đỉnh <= 24px), khay `SnapLayoutPickerPanel` trượt xuống nhẹ nhàng dưới thanh Menu Bar.
2. **4 Standard Layout Templates**:
   - **2 Columns 50/50**: Left Half, Right Half.
   - **2 Columns Asymmetric 70/30**: Left 70% (`leftTwoThirds`), Right 30% (`rightOneThird`).
   - **3 Columns 1/3 Equal**: Left 1/3 (`leftThird`), Center 1/3 (`centerThird`), Right 1/3 (`rightThird`).
   - **4 Quarters 2x2**: Top-Left, Top-Right, Bottom-Left, Bottom-Right.
3. **Dual Interactive Hover Feedback**:
   - Highlight trực tiếp ô slot trong khay picker khi di chuột vào.
   - Đồng thời hiển thị khung preview mờ toàn màn hình (`SnapPreviewPanel`) tương ứng với phân vùng của ô đó.
4. **Mouse Release & Snap Execution**:
   - Nhả chuột (`leftMouseUp`) trong ô slot: Snap cửa sổ chính xác vào vị trí mục tiêu, ẩn picker, và flash hiệu ứng thành công.
   - Di chuột ra ngoài vùng picker: Picker tự động thu gọn và đóng lại, trả quyền điều khiển về hệ thống kéo-thả cạnh tiêu chuẩn.
5. **Multi-Display Alignment**: Picker luôn xuất hiện ở cạnh trên của đúng màn hình đang thao tác kéo chuột.

---

## 3. Business Rules Index (BR-PICKER-###)

- **BR-PICKER-001**: Vùng kích hoạt là Top-Center (30%-70% chiều ngang màn hình, y <= 24px từ đỉnh visibleFrame).
- **BR-PICKER-002**: Panel hiển thị là `NSPanel` non-activating, không cướp focus của ứng dụng đang kéo.
- **BR-PICKER-003**: Cung cấp đủ 4 preset bố cục: 50/50, 70/30, 3 cột 1/3, 4 góc 2x2.
- **BR-PICKER-004**: Phản hồi kép khi hover (highlight ô slot + full-screen preview HUD).
- **BR-PICKER-005**: Thả chuột trong slot dispatch lệnh snap và flash viền thành công.
- **BR-PICKER-006**: Tự động đóng picker mượt mà khi con trỏ ra khỏi phạm vi khay.
- **BR-PICKER-007**: Luôn định vị picker trên đúng Display đang thao tác.
- **BR-PICKER-008**: Chỉ kích hoạt khi có quyền Accessibility.

---

## 4. Handover Brief for System Architecture (Speckit)

- **UI Components**:
  - `SnapLayoutPickerView.swift` (SwiftUI component vẽ 4 card layout với các slot tương tác, hiệu ứng hover, Glassmorphic background).
  - `SnapLayoutPickerPanel.swift` (AppKit NSPanel custom, non-activating, level `.floating + 1`).
  - `SnapLayoutPickerManaging.swift` (Protocol quản lý hiển thị, định vị và ẩn khay picker).
  - `SnapLayoutPickerManager.swift` (Implementation quản lý lifecycle của NSPanel và SwiftUI HostingView).
- **Core / Domain Extensions**:
  - Mở rộng `SnapTarget` với: `.leftTwoThirds`, `.rightOneThird`, `.leftThird`, `.centerThird`, `.rightThird`.
  - Cập nhật `LayoutEngine.calculateFrame(for:in:)` tính toán chính xác pixel cho các target mới.
  - Cập nhật `DragToSnapCoordinator` tích hợp `SnapLayoutPickerManaging` và xử lý chuyển đổi trạng thái giữa edge snap và layout picker.
- **Testing Requirements**:
  - Unit tests cho `LayoutEngine` với các phân vùng mới (70/30, 3-column).
  - Unit tests cho `SnapLayoutPickerManager` (hiển thị, hit-testing slot, dispatch snap target).
  - Unit tests cho `DragToSnapCoordinator` khi kéo vào vùng top-center vs vùng cạnh thông thường.
