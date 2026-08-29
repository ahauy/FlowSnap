# Risk Register & Scope Boundary: US-SNAP-007 Top-Edge Snap Layout Picker

## 1. Risk Register

| Risk ID          | Description                                                                        |   Impact   | Probability | Mitigation Strategy                                                                                                                                |
| :--------------- | :--------------------------------------------------------------------------------- | :--------: | :---------: | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-TOP-001** | Tranh chấp giữa Maximize Snap và Layout Picker ở cạnh trên                         |    Cao     | Trung bình  | Phân vùng rõ ràng: Top-Center Zone (30% - 70% width) mở Picker; Top-Left / Top-Right (0-30% và 70-100%) kích hoạt Maximize / Corner snap.          |
| **RISK-TOP-002** | Trễ hoặc giật khung hình (frame drop) khi render đồng thời Picker và Preview Panel | Trung bình |    Thấp     | Tận dụng Core Animation layer-backed views, tái sử dụng `SnapPreviewPanel` singleton, tránh tạo mới NSPanel trong vòng lặp drag.                   |
| **RISK-TOP-003** | Menu Bar của macOS nằm ở cạnh trên có thể che khuất hoặc va chạm với Picker Panel  | Trung bình |    Thấp     | Tính toán vị trí picker dựa trên `display.visibleFrame` (tự động thụt xuống dưới Menu Bar khi Menu Bar hiển thị).                                  |
| **RISK-TOP-004** | Đa màn hình: Chuột kéo qua mép trên của màn hình dưới lên màn hình trên            |    Cao     |    Thấp     | Kiểm tra `adjacentDisplays`: chỉ kích hoạt picker khi cạnh trên là mép ngoài cùng (outer boundary) hoặc người dùng dừng chuột (dwell) có chủ đích. |

## 2. Contradiction Scan

- **Contradiction**: Liệu kéo cửa sổ nhanh qua mép trên có vô tình mở picker làm gián đoạn trải nghiệm không?
  - **Resolution**: Áp dụng debounce/dwell (50ms) trong vùng Top-Center trước khi kích hoạt animation mở picker.
- **Contradiction**: Khi thả chuột trên khoảng trống giữa các slot trong picker thì xử lý thế nào?
  - **Resolution**: Nếu thả chuột trong picker nhưng không trúng slot nào, picker sẽ đóng lại và không thực hiện snap (giữ nguyên vị trí cửa sổ) để tránh hành vi bất ngờ.

## 3. MoSCoW Scope Boundary

### Must-Have

- Kéo cửa sổ vào vùng đỉnh trung tâm (Top-Center Zone) hiển thị khay `SnapLayoutPickerPanel`.
- 4 mẫu bố cục chuẩn: 50/50, 70/30, 3 cột 1/3, 4 góc 2x2.
- Highlight slot khi hover chuột và đồng bộ hiển thị preview mờ toàn màn hình (`SnapPreviewPanel`).
- Thả chuột (`leftMouseUp`) trong slot thực thi snap chính xác tới vị trí tương ứng.
- Tự động đóng picker khi chuột rời khỏi vùng khay.

### Should-Have

- Animation trượt mượt mà (slide-down / slide-up) khi xuất hiện / biến mất.
- Thích ứng hoàn hảo trên màn hình đa độ phân giải và Retina 1x/2x.

### Could-Have

- Phím tắt số (1, 2, 3, 4) để chọn nhanh mẫu bố cục khi picker đang mở.

### Won't-Have (Explicit Scope Exclusions)

- Không hỗ trợ tự tạo custom template động trong khay picker (để dành cho Sprint sau).
- Không can thiệp vào các ứng dụng không có quyền Accessibility.
