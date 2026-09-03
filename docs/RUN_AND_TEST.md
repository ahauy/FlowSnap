# 🚀 FlowSnap — Hướng Dẫn Chạy & Kiểm Thử Ứng Dụng (Run & Test Guide)

Tài liệu này tổng hợp các lệnh kiểm thử nhanh cho lập trình viên và kiểm thử viên khi làm việc với FlowSnap.

---

## 1. Lệnh Khởi Chạy Nhanh Ứng Dụng (Quick Launch)

### Mở FlowSnap Lab (Giao diện Kiểm thử Tương tác)

```bash
open /Users/vutuanhau/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug/FlowSnapLab.app
```

### Mở FlowSnap Chính (Menu Bar Daemon)

```bash
open /Users/vutuanhau/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug/FlowSnap.app
```

---

## 2. Xử Lý Quyền Trợ Năng (Accessibility Reset)

Khi build lại mã nguồn hoặc gặp tình trạng gạt bật quyền trong System Settings nhưng ứng dụng vẫn báo **`Untrusted`**, chạy lệnh sau để xóa bộ nhớ đệm quyền của macOS:

```bash
tccutil reset Accessibility com.flowsnap.lab
```

Sau đó mở lại ứng dụng:

```bash
open /Users/vutuanhau/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug/FlowSnapLab.app
```

_(Bấm **"Open Settings"** trên giao diện app để gạt Bật lại quyền)._

---

## 3. Lệnh Build & Chạy Một Bước (One-Line Build & Launch)

Build phiên bản mới nhất của `FlowSnapLab` và tự động mở ứng dụng ngay lập tức:

```bash
xcodebuild -project FlowSnap.xcodeproj -scheme FlowSnapLab -destination 'platform=macOS' build && open /Users/vutuanhau/Library/Developer/Xcode/DerivedData/FlowSnap-*/Build/Products/Debug/FlowSnapLab.app
```

---

## 4. Quy Ước AI Agent (Agent Delivery Convention)

> ⭐️ **Quy tắc bắt buộc:** Mỗi khi AI hoàn thành một User Story / Tính năng mới (kết thúc Phase 6 và cập nhật tài liệu), AI **phải tự động thực thi lệnh mở ứng dụng** `FlowSnapLab.app` để người dùng có thể kiểm thử trực tiếp trên máy thật ngay lập tức.

cd ~/Documents/PROJECT/FlowSnap && \
xcodebuild build -project FlowSnap.xcodeproj -scheme FlowSnap -destination 'platform=macOS' 2>&1 | grep -E "(error:|BUILD)" && \
pkill -x FlowSnap 2>/dev/null; sleep 0.3; \
open ~/Library/Developer/Xcode/DerivedData/FlowSnap-hjptlbvoundbuuanhlzudkreqckc/Build/Products/Debug/FlowSnap.app
