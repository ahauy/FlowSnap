# Intake: Cross-Display Throw & Target-Aware Snap (US-DISP-015)

- **Date**: 2026-09-03
- **Requested by**: FlowSnap Product Roadmap / EPIC 13 (Advanced Multi-Monitor Topology & Cross-Display Navigation)
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 1 (`WindowCommand` extension: `.moveToNextDisplay`, `.moveToPreviousDisplay` or updating `.moveToDisplay`)
  - Existing persistence schema change: None (reuses existing `ShortcutAction.nextDisplay` and `.previousDisplay` in `PreferencesStore`)
  - Screens/flows touched: Global Hotkeys handler + Display Manager spatial calculation + Cursor positioning
  - User roles affected: 1 (macOS multi-monitor power user)
  - Cross-cutting impact: Medium (`GlobalHotkeyManager` -> `CommandDispatcher` -> `DisplayManager` -> `AccessibilityService` / `CGWarpMouseCursorPosition`)
  - Estimated code lines changed: ~250-400 lines
  - Reversible without user impact: Yes (default hotkeys `⌃⌥⇧→` / `⌃⌥⇧←`, configurable or dismissible)
- **Protocol selected**: Bounded Task Pipeline (Stages 1 → 2 (interactive interview) → 4 (domain modeling) → 5 (risk scan) → 6 (user stories & spec) → 7 → 8). Stage 3 gap analysis skipped per Bounded Task protocol.
- **Override**: Matches roadmap Effort `M`, Context-budget `single-session`, Priority `Must-Have (P0)`.
- **Roadmap dependencies**: Depends-on `US-SNAP-003` (Display-Aware Multi-Monitor ✅), `US-SNAP-004` (Carbon Global Hotkeys ✅). Blocks: `US-DISP-016`.

## Acceptance Criteria Anchors (from Roadmap)

1. **Global Hotkeys**:
   - Lắng nghe tổ hợp phím toàn cục `Move to Next Display` (`⌃⌥⇧→`) và `Move to Previous Display` (`⌃⌥⇧←`).
   - Có thể cấu hình lại phím tắt trong Settings UI (`ShortcutAction.nextDisplay`, `ShortcutAction.previousDisplay`).
2. **Relative Ratio Preserved**:
   - Khi ném cửa sổ: Giữ nguyên tỉ lệ hình học tương đối (Relative Ratio Preserved) — ví dụ cửa sổ đang chiếm nửa trái (50% left) ở màn hình laptop sẽ tự động trở thành 50% nửa trái tại màn hình ngoài 4K/FHD đích.
   - Nếu cửa sổ có vị trí tự do (ví dụ: nằm ở 20% X, 30% Y với kích thước 40% W, 50% H so với `visibleFrame`), tỉ lệ tương đối này được nhân với `visibleFrame` của màn hình đích.
3. **Cursor Focus Relocation**:
   - Tự động chuyển tiêu điểm chuột (mouse cursor focus) sang trung tâm của cửa sổ tại màn hình đích (`CGWarpMouseCursorPosition`) để người dùng tiếp tục thao tác phím/chuột không bị gián đoạn.
4. **Single-Display Graceful Handling**:
   - Xử lý an toàn khi chỉ có 1 màn hình duy nhất (No-op không lỗi, không giật màn hình).

## One-line Problem Statement

Provide keyboard-driven instant cross-display window navigation (`⌃⌥⇧→` / `⌃⌥⇧←`) that transports the active window to the next or previous display while preserving its proportional geometry relative to the target screen's visible bounds and warping cursor focus to maintain uninterrupted flow.
