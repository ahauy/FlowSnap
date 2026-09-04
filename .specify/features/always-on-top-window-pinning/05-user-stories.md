# 05 — User Stories & Acceptance Scenarios: always-on-top-window-pinning (US-SNAP-021)

## US-PIN-001: Universal Always-On-Top Window Pinning & LIFO Z-Stacking

- **Derived from**: `docs/PRODUCT_BACKLOG_ROADMAP.md` — `US-SNAP-021` (AC 1, AC 2, AC 3)
- **As a**: macOS Power User
- **I want**: To press a global shortcut (`⌃⌥P`) to pin any focused window always on top of all other windows
- **So that**: I can reference notes, calculators, reference documents, or video feeds while actively working in background apps without my reference window sinking underneath.

### Scenario 1: Pin Focused Window via Hotkey (Happy Path)

- **Given**: Người dùng đang có tiêu điểm tại cửa sổ ứng dụng "Notes" (ID: 101, PID: 500).
- **When**: Người dùng nhấn phím tắt toàn cục `⌃⌥P`.
- **Then**: "Notes" được thêm vào danh sách ghim của `WindowPinningCoordinator`.
- **And**: `kAXRaiseAction` được gửi đến cửa sổ "Notes".
- **And**: Một HUD Toast hiển thị phản hồi tức thì "Pinned Notes" trong 1.0 giây.
- **And**: Menu Bar Status Item hiển thị trạng thái có 1 cửa sổ đang ghim.

### Scenario 2: Toggle Unpin on Already Pinned Window

- **Given**: Cửa sổ "Notes" (ID: 101) đang ở trạng thái ghim.
- **When**: Người dùng nhấn phím tắt `⌃⌥P` một lần nữa trong khi "Notes" đang có tiêu điểm.
- **Then**: "Notes" được gỡ khỏi danh sách ghim.
- **And**: HUD Toast hiển thị "Unpinned Notes" trong 1.0 giây.
- **And**: Cửa sổ quay trở lại cơ chế Z-order thông thường của hệ điều hành.

### Scenario 3: Multi-Window Pinning with Dynamic LIFO Z-Stacking

- **Given**: Cửa sổ "Notes" (ID: 101) đã được ghim trước đó.
- **When**: Người dùng chuyển sang cửa sổ "Calculator" (ID: 102) và nhấn `⌃⌥P`.
- **Then**: Cả hai cửa sổ đều được ghim.
- **And**: "Calculator" (vừa ghim sau) nằm trên "Notes" (ghim trước).
- **And**: Toàn bộ nhóm ghim [Calculator, Notes] luôn nằm trên tất cả các cửa sổ thông thường khác.

---

## US-PIN-002: Active Re-assertion Coordination on Focus Change

- **Derived from**: `docs/PRODUCT_BACKLOG_ROADMAP.md` — `US-SNAP-021` (AC 2, AC 4, AC 5)
- **As a**: macOS Power User with pinned windows
- **I want**: Pinned windows to remain visible on top when I click and type in underlying background windows
- **So that**: My workflow is uninterrupted and I never lose sight of my pinned reference windows.

### Scenario 1: Clicking Background Window Re-asserts Pinned Windows

- **Given**: Cửa sổ "Notes" (ID: 101) đang được ghim.
- **When**: Người dùng click vào cửa sổ "Safari" (không nằm trong danh sách ghim) để gõ văn bản.
- **Then**: `WindowPinningCoordinator` nhận được thông báo thay đổi tiêu điểm từ `NSWorkspace` / `AXObserver`.
- **And**: FlowSnap gửi `kAXRaiseAction` tới "Notes" để giữ "Notes" nằm trên "Safari".
- **And**: Người dùng vẫn tiếp tục tương tác bình thường với "Safari" mà không bị cướp keyboard focus.

### Scenario 2: System Modal Dialog Exemption

- **Given**: Cửa sổ "Notes" đang được ghim.
- **When**: Hệ thống hiển thị hộp thoại xác thực Touch ID / Keychain từ `com.apple.SecurityAgent`.
- **Then**: `WindowPinningCoordinator` phát hiện active application là modal bảo mật hệ thống.
- **And**: Tạm ngưng re-assertion để đảm bảo hộp thoại Touch ID không bị che khuất.

---

## US-PIN-003: Stage Manager Launch Co-existence

- **Derived from**: `docs/PRODUCT_BACKLOG_ROADMAP.md` — `US-SNAP-021` (AC 6, AC 7)
- **As a**: macOS Power User using Stage Manager
- **I want**: Newly launched applications to seamlessly join my current active Stage
- **So that**: macOS does not push my current workspace windows into the sidebar thumbnail strip when I open an app from Dock or Spotlight.

### Scenario 1: Launch New App with Stage Manager Launch Co-existence ON

- **Given**: Stage Manager đang BẬT (`isStageManagerEnabled == true`) và cấu hình `stageManagerLaunchCoexistenceEnabled == true`.
- **And**: Người dùng đang làm việc với Stage chứa VS Code và Chrome.
- **When**: Người dùng mở ứng dụng "Terminal" từ Dock hoặc Spotlight.
- **Then**: `StageManagerLaunchCoordinator` ghi nhận `NSWorkspace.didLaunchApplicationNotification`.
- **And**: Snapshot danh sách cửa sổ của Stage hiện tại [VS Code, Chrome].
- **And**: Đón bắt sự kiện cửa sổ Terminal xuất hiện qua `ApplicationObserver`.
- **And**: Điều phối `kAXRaiseAction` cho VS Code và Chrome.
- **And**: Cả Terminal, VS Code, và Chrome cùng xuất hiện trên Stage hiện tại, không có cửa sổ nào bị đẩy vào cánh gà.

### Scenario 2: Launch New App with Feature Disabled in Settings

- **Given**: Tính năng `stageManagerLaunchCoexistenceEnabled == false`.
- **When**: Mở ứng dụng mới.
- **Then**: FlowSnap bỏ qua việc điều phối Stage, cho phép macOS vận hành theo hành vi mặc định.
