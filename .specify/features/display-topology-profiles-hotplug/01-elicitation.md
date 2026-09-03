# 01 — Elicitation Record (Stage 2) — display-topology-profiles-hotplug

> Interview conducted on 2026-09-03 via interactive interview gate for US-DISP-016.
> Confirmed decisions: `ASM-DISP-004`, `ASM-DISP-005`, `ASM-DISP-006`.

## Confirmed Decisions

### ASM-DISP-004 — Hot-Unplug Safe Proportional Clamping & Auto-Snapshot

- **Decision**: Khi người dùng ngắt kết nối màn hình rời (cáp bị rút hoặc tắt màn hình ngoài):
  - **Tự động Snapshot**: FlowSnap lập tức chụp lại vị trí hình học của tất cả các cửa sổ đang nằm trên màn hình rời đó trước khi hệ thống macOS dồn cửa sổ, lưu snapshot gắn liền với `TopologyFingerprint` của cấu hình vừa ngắt kết nối.
  - **Proportional Clamping**: Các cửa sổ trên màn hình ngoài được dồn về màn hình chính (Primary Laptop Screen).
  - Sử dụng `FrameClampingHelper` để co giãn kích thước cửa sổ tương ứng với `primaryDisplay.visibleFrame`:
    - Nếu cửa sổ có kích thước lớn hơn màn hình laptop, tự động thu nhỏ theo tỷ lệ chiều rộng/cao của màn hình chính.
    - Đảm bảo thanh tiêu đề (title bar, tối thiểu 36px từ đỉnh) luôn nằm hoàn toàn bên trong vùng an toàn (`visibleFrame`), không bị chui vào dưới Menu Bar hay Dock.
    - Giữ nguyên thứ tự hiển thị z-order tương đối giữa các ứng dụng.
- **Rationale**: Ngăn chặn tình trạng cửa sổ bị "kẹt" ngoài vùng hiển thị hoặc mất tích sau khi rút cáp, đồng thời bảo toàn dữ liệu bố cục để sẵn sàng khôi phục ngay khi cắm lại cáp.

### ASM-DISP-005 — Hot-Plug Reconnect Zero-Prompt Auto-Restore with Coalescing Debounce

- **Decision**: Khi cắm lại màn hình rời hoặc kết nối lại DisplayPort / HDMI / Type-C:
  - **Coalescing Debounce (600ms)**: Lắng nghe thông báo hệ thống `NSApplication.didChangeScreenParametersNotification`. Vì macOS thường bắn 2-4 thông báo liên tiếp trong quá trình handshaking tín hiệu, FlowSnap áp dụng bộ đệm trễ debounce 600ms. Chỉ khi không còn sự kiện mới trong 600ms, hệ thống mới bắt đầu xử lý.
  - **Zero-Prompt Auto-Restore**:
    - Tính toán `TopologyFingerprint` của cấu hình màn hình mới.
    - Nếu tìm thấy Profile đã lưu tương ứng với fingerprint này: Hệ thống tự động di chuyển các cửa sổ đang mở về đúng màn hình ngoài và phục hồi đúng vị trí hình học đã lưu mà không yêu cầu người dùng phải bấm thêm bất kỳ nút nào.
    - Nếu một ứng dụng trong profile không còn chạy, FlowSnap bỏ qua ứng dụng đó mà không gây lỗi; các ứng dụng đang chạy vẫn được khôi phục chính xác.
- **Rationale**: Tối ưu hóa trải nghiệm không ma sát (frictionless). Người dùng chỉ cần cắm dock hoặc cắm màn hình rời vào bàn làm việc, toàn bộ không gian làm việc đa màn hình tự động trở về trạng thái hoàn hảo trong vòng chưa tới 1 giây.

### ASM-DISP-006 — Deterministic Topology Fingerprint Algorithm (100% Zero Private API)

- **Decision**: Cấu trúc định danh hồ sơ không gian màn hình (`TopologyFingerprint`):
  - Thu thập danh sách màn hình từ `NSScreen.screens` sắp xếp theo tọa độ X tăng dần (`origin.x`), tie-break bằng `origin.y`.
  - Với mỗi màn hình, trích xuất:
    - `CGDirectDisplayID` -> Chuyển thành UUID qua `CGDisplayCreateUUIDFromDisplayID` (hoặc fallback hash từ vendorID/modelID).
    - Tên hiển thị người dùng: `screen.localizedName` (ví dụ: "Built-in Retina Display", "KG270 M5").
    - Kích thước hiển thị: `screen.frame.size` (width, height) và `screen.visibleFrame.size`.
  - Kết hợp các thuộc tính thành chuỗi đặc trưng chuẩn hóa:
    - Định dạng: `count:<N>|disp0:<UUID>:<W>x<H>|disp1:<UUID>:<W>x<H>...`
    - Băm SHA-256 tạo ra chuỗi hash 64 ký tự đại diện cho `TopologyFingerprint`.
  - Lưu trữ hồ sơ `DisplayTopologyProfile` vào `UserDefaults` / JSON local storage trong thư mục Application Support của FlowSnap.
- **Rationale**: Đảm bảo dấu vân tay luôn đồng nhất qua các lần khởi động lại máy hoặc cắm rút cáp, phân biệt được rõ ràng giữa màn hình tại công ty và màn hình tại nhà, đồng thời tuân thủ 100% Public APIs an toàn cho macOS.

---

## Anchored (not re-asked) — Settled by Roadmap AC & Architecture Baseline

- **Architecture Boundary**: Tuân thủ Deep Modules, Domain-Driven Design (DDD), Swift 6 strict concurrency (`Sendable`, `@MainActor`).
- **Dependencies**: Tích hợp với `DisplayManager`, `RelativeFrameScaler`, `FrameClampingHelper`, `WorkspaceManager`, `AccessibilityService`.
- **Telemetry & Logging**: Log chi tiết sự kiện thay đổi màn hình với log level `.info` (Topology change detected, fingerprint hash, number of windows rebalanced).
