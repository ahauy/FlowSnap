# 📖 Hướng Dẫn Sử Dụng: Thoát Toàn Màn Hình Đa Nền Tảng (US-WORK-018)

# User Guide: Universal Fullscreen Escape for Electron/Native Apps

> **Đối tượng:** Người dùng FlowSnap trên macOS (macOS 14 Sonoma & macOS 15 Sequoia)  
> **Tính năng:** Universal Fullscreen Escape (US-WORK-018)  
> **Trạng thái:** Sẵn sàng & Tích hợp hoàn toàn trong FlowSnap

---

## 🎯 1. Tổng Quan (Overview)

Khi bạn sử dụng tính năng **Khôi phục Không gian làm việc (Workspace Restore)** hoặc dùng các phím tắt snap cửa sổ (ví dụ: `⌃⌥←`, `⌃⌥→`, `⌃⌥↑`), một số cửa sổ có thể đang nằm ở chế độ **Toàn màn hình macOS (Native Full Screen Space)**.

Trước đây, macOS tự động cô lập cửa sổ Full Screen trên một Space riêng biệt và bỏ qua mọi lệnh di chuyển vị trí. Đặc biệt, các ứng dụng nền tảng **Electron / Chromium** (như VS Code, Antigravity, Discord, Slack, Brave, Obsidian) không phản hồi các lệnh Accessibility thông thường, khiến cửa sổ bị "kẹt" lại trên Space Full Screen.

Với **Universal Fullscreen Escape (US-WORK-018)**:

- **Tự động trượt về Desktop:** FlowSnap tự động phát hiện cửa sổ đang ở chế độ Full Screen và kích hoạt chuỗi thoát 3 tầng linh hoạt để đưa cửa sổ trở về Desktop bình thường.
- **Tương thích 100% mọi loại ứng dụng:** Hỗ trợ mượt mà từ các ứng dụng chuẩn Apple Native (Safari, Xcode, Finder) cho đến các ứng dụng phức tạp nền Chromium/Electron (VS Code, Chrome, Antigravity).
- **Phản hồi tức thì với Adaptive Polling:** Không chờ đợi cứng nhắc; ngay khi hiệu ứng chuyển Space của macOS vừa kết thúc (thường chỉ 200–300ms), FlowSnap lập tức bố trí cửa sổ vào đúng vị trí của Workspace hoặc phím tắt snap.

---

## ⚡ 2. Cơ Chế Hoạt Động 3 Tầng Thông Minh (3-Tier Fallback)

FlowSnap áp dụng chiến lược thoát toàn màn hình 3 tầng lũy tiến:

```
[ Cửa sổ đang Full Screen ]
         │
         ├──► Tầng 0 (Fast Attribute): Ghi trực tiếp cờ AXFullscreen (≤5ms)
         │       └── Thất bại? (Thường gặp trên Electron)
         │
         ├──► Tầng 1 (AX Button Press): Kích hoạt nút Zoom/Fullscreen xanh lá của cửa sổ (≤20ms)
         │       └── Thất bại? (Ứng dụng tùy biến hoàn toàn thanh tiêu đề)
         │
         └──► Tầng 2 (Keystroke Synthesis): Kích hoạt ứng dụng và gửi phím tắt ⌃⌘F trực tiếp qua CGEvent
```

Sau khi phát tín hiệu thoát, hệ thống giám sát khung hình cửa sổ với chu kỳ **100ms** (tối đa 800ms) để thực hiện di chuyển ngay khi không gian làm việc sẵn sàng.

---

## 🚀 3. Cách Sử Dụng Trong Thực Tế

Bạn không cần thao tác thêm bất kỳ nút bấm phức tạp nào! Tính năng này hoạt động **hoàn toàn tự động** và trong suốt trong các trường hợp sau:

### Trường hợp 1: Khôi phục Workspace khi có app đang Full Screen

1. Bạn đang mở VS Code hoặc Antigravity ở chế độ Full Screen trên một màn hình riêng.
2. Bạn bấm khôi phục một Workspace đã lưu (ví dụ: "Code & Chat").
3. **FlowSnap tự động:**
   - Đưa VS Code thoát khỏi Full Screen trượt về Desktop chính.
   - Sắp xếp VS Code chiếm 70% màn hình bên trái.
   - Sắp xếp ứng dụng Chat chiếm 30% bên phải.
   - Toàn bộ diễn ra mượt mà không xảy ra xung đột.

### Trường hợp 2: Snap cửa sổ đang Full Screen bằng phím tắt

1. Cửa sổ đang chiếm trọn màn hình Full Screen.
2. Bạn nhấn phím tắt Snap Left `⌃⌥←` hoặc Snap Right `⌃⌥→`.
3. FlowSnap tự động thoát cửa sổ khỏi Full Screen và snap ngay vào một nửa màn hình mong muốn.

---

## 🛠️ 4. Xử Lý Sự Cố (Troubleshooting)

- **Cửa sổ không phản hồi phím tắt snap khi đang Full Screen?**
  - Hãy kiểm tra xem FlowSnap đã được cấp quyền **Accessibility (Trợ năng)** trong `System Settings > Privacy & Security > Accessibility` hay chưa.
- **Hiệu ứng chuyển màn hình có bị giật không?**
  - Không. FlowSnap đợi hiệu ứng trượt Space của macOS hoàn thành rồi mới gán kích thước mới, đảm bảo trải nghiệm thị giác luôn liền mạch.
