# Hướng Dẫn Sử Dụng: Kéo Ngã Tư & Ngã Ba 2D (Cross-Junction & T-Junction 2D Divider Resize)

Tính năng **Kéo Ngã Tư & Ngã Ba 2D** (Giải pháp 1) trên FlowSnap cho phép bạn điều chỉnh kích thước đồng thời của 3 hoặc 4 cửa sổ đang ghép cạnh nhau chỉ bằng một thao tác kéo chuột duy nhất, thay vì phải kéo thanh ngang rồi lại kéo thanh dọc riêng lẻ.

---

## 1. Khi nào tính năng này hoạt động?

Tính năng tự động kích hoạt khi màn hình của bạn có bố cục chia ô gồm từ 3 cửa sổ trở lên tạo thành điểm giao nhau:

- **Ngã ba chữ T (T-Junction - 3 cửa sổ)**: 1 cửa sổ lớn bên trái (hoặc phải) và 2 cửa sổ xếp chồng bên đối diện (ví dụ: VS Code bên trái, Terminal + Arc Browser bên phải).
- **Ngã tư chữ thập (Cross-Junction - 4 cửa sổ)**: 4 cửa sổ xếp dạng lưới 2x2.

> [!NOTE]
> Các cửa sổ phải là ứng dụng cho phép thay đổi kích thước (resizable). Những ứng dụng macOS có chiều rộng cố định (như System Settings) sẽ không tham gia vào thanh chia đôi để tránh xung đột hệ điều hành.

---

## 2. Các bước sử dụng

### Bước 1: Di chuyển chuột vào Điểm Giao Nhau (Junction Point)

- Đưa con trỏ chuột đến đúng vị trí giao nhau giữa thanh phân cách dọc và thanh phân cách ngang.
- **Dấu hiệu nhận biết**:
  - Con trỏ chuột chuyển ngay sang biểu tượng chữ thập ngắm tâm (`✛` `NSCursor.crosshair`).
  - Tại điểm giao sẽ xuất hiện **núm điều khiển phát sáng tinh tế** (vòng tròn accent mờ cùng chấm tròn trắng ở tâm).

### Bước 2: Kéo tự do theo bất kỳ hướng nào (2D Dragging)

- Nhấn giữ chuột trái và kéo theo bất kỳ hướng chéo nào bạn muốn (lên, xuống, trái, phải).
- **Hiệu ứng trực quan**:
  - Khi bạn kéo sang phải: Cửa sổ bên trái mở rộng, cả 2 cửa sổ bên phải cùng thu hẹp.
  - Khi bạn kéo lên trên: Cửa sổ góc dưới bên phải cao lên, cửa sổ góc trên bên phải thu hẹp lại.
  - Cả 3 (hoặc 4) cửa sổ thay đổi kích thước đồng thời và mượt mà ở tần số quét màn hình ProMotion 120Hz.

### Bước 3: Thả chuột để hoàn tất

- Thả chuột trái tại vị trí bạn ưng ý. Layout mới sẽ lập tức được lưu và cố định.

---

## 3. Các tính năng thông minh đi kèm

### Chống kẹt trục độc lập (Decoupled Per-Axis Clamping)

Nếu một ứng dụng đã thu nhỏ đến kích thước tối thiểu cho phép (ví dụ chiều rộng cửa sổ Terminal chạm mức tối thiểu):

- Chuyển động ngang sẽ tự động dừng lại để bảo vệ nội dung ứng dụng không bị biến dạng.
- **Trục dọc vẫn tiếp tục di chuyển tự do**: Bạn vẫn có thể tiếp tục kéo lên/xuống để đổi chiều cao giữa 2 ứng dụng bên phải mà không bị khựng chuột!

### Hủy nhanh bằng phím Escape (`⎋`)

Trong lúc đang nhấn giữ kéo ngã tư, nếu bạn đổi ý hoặc kéo nhầm:

- Nhấn phím `⎋` (Escape) trên bàn phím.
- Tất cả các cửa sổ sẽ lập tức hoàn tác về đúng vị trí và kích thước ban đầu.
