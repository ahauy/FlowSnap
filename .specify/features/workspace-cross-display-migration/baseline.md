# Domain Baseline: Atomic Workspace Cross-Display Migration (US-DISP-017)

- **Version**: 1.0.0
- **Status**: SIGNED-OFF v1.0 (Confirmation Gate 1 Approved)
- **Feature Slug**: `workspace-cross-display-migration`
- **Related Roadmap Item**: `US-DISP-017` (Epic 13 — Advanced Multi-Monitor Topology & Cross-Display Navigation)

---

## 1. Domain Summary

Cho phép người dùng chuyển tức thì toàn bộ các cửa sổ thuộc Không gian làm việc (Workspace) đang mở từ màn hình hiện tại sang màn hình kế tiếp hoặc màn hình chỉ định bằng tổ hợp phím toàn cục (mặc định `⌃⌥⇧⌘→` và `⌃⌥⇧⌘←`) hoặc tùy chọn trong thanh menu Status Bar. Mọi tỷ lệ tương đối giữa các cửa sổ (Split Seam & Normalized Ratios) được bảo toàn nguyên vẹn trên màn hình đích mà không làm rã nhóm Stage Manager.

1. **Xác định Workspace mục tiêu**: Lấy màn hình nguồn (`sourceDisplay`) theo cửa sổ đang có tiêu điểm (focused window) hoặc vị trí con trỏ chuột, xác định Workspace active đang nằm trên màn hình đó.
2. **Ánh xạ tỉ lệ hình học**: Chuyển đổi tọa độ tất cả cửa sổ sang `targetDisplay.visibleFrame` thông qua `RelativeFrameScaler`, bảo toàn tỉ lệ chia đôi, chia ba và gap.
3. **Thứ tự di chuyển thích ứng**:
   - **Khi Stage Manager BẬT**: Di chuyển Anchor window trước, sau đó di chuyển các cửa sổ phụ với độ trễ Stagger 40ms kết hợp `kAXRaiseAction` để giữ nguyên một Stage duy nhất trên màn hình đích.
   - **Khi Stage Manager TẮT**: Áp dụng 2-phase move ordering (thu nhỏ trước - mở rộng sau) để chống va chạm và clamping.
4. **Handoff tiêu điểm & dải phân cách**: Di chuyển con trỏ chuột (warp cursor) tới tâm cửa sổ chính trên màn hình đích, chuyển quyền quản lý dải phân cách `AdaptiveDividerCoordinator` sang màn hình đích, hủy dải phân cách ở màn hình nguồn.
5. **No-op an toàn**: Tự động no-op êm dịu khi chỉ có 1 màn hình (`displays.count <= 1`) hoặc không có Workspace nào đang active.

---

## 2. Business Rules Reference

- **BR-MIG-001**: Source & Target Display Resolution — xác định source theo focused window/cursor, target theo `DisplayNavigator`, no-op nếu chỉ có 1 display.
- **BR-MIG-002**: Active Workspace Identification — xác định active workspace trên source display; no-op êm dịu nếu không có.
- **BR-MIG-003**: Proportional Geometric Scaling — ánh xạ đa cửa sổ qua `RelativeFrameScaler`, bảo toàn hoàn hảo tỉ lệ chia tách.
- **BR-MIG-004**: 2-Phase Move Ordering & Stage Manager Cohesion — 2 pha khi Stage Manager tắt; anchor-first + 40ms stagger + `kAXRaiseAction` khi Stage Manager bật.
- **BR-MIG-005**: Post-Migration Handoff — warp cursor tới tâm primary window, tái lập `AdaptiveDividerCoordinator` tại target display, giữ vững keyboard focus.

---

## 3. Assumptions Register

- `ASM-MIG-001`: Workspace Resolution theo display của focused window hoặc mouse cursor.
- `ASM-MIG-002`: Move ordering 2 pha (Stage Manager OFF) vs Staggered IPC + kAXRaiseAction (Stage Manager ON).
- `ASM-MIG-003`: Warp chuột và chuyển dải phân cách sang màn hình đích.
- `ASM-MIG-004`: Ánh xạ tọa độ qua `RelativeFrameScaler`.
- `ASM-MIG-005`: Phím tắt mặc định `⌃⌥⇧⌘→` (Next) và `⌃⌥⇧⌘←` (Previous).

---

## 4. Scope (MoSCoW)

- **Must-Have (P0)**:
  - `WorkspaceMigrating` protocol & `WorkspaceMigrator` coordinator.
  - Phím tắt toàn cục `⌃⌥⇧⌘→` / `⌃⌥⇧⌘←` trong `GlobalHotkeyManager`.
  - Tích hợp `RelativeFrameScaler`, `DisplayNavigator`, `StageManagerDetector`.
  - Staggered IPC (40ms) + `kAXRaiseAction` khi Stage Manager ON; 2-phase move khi OFF.
  - Warp chuột tới tâm primary window và cập nhật `AdaptiveDividerCoordinator`.
  - Safe graceful no-op khi 1 display hoặc không có workspace active.
  - Bộ unit test kiểm thử toàn diện kịch bản di chuyển 2 cửa sổ, 3 cửa sổ, Stage Manager ON/OFF, single display no-op.
- **Should-Have (P1)**:
  - Menu item "Move Workspace to Next Display" / "Previous Display" trong Menu Bar.
  - Cấu hình phím tắt trong Preferences Shortcuts.
- **Won't-Have (v1.0 Out of Scope)**:
  - Animation kéo trượt cửa sổ bay giữa các màn hình.
