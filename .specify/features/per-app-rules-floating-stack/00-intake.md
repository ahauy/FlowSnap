# Intake: Per-App Rules & Smart Floating Stack (US-WORK-014)

- **Date**: 2026-09-03
- **Requested by**: FlowSnap Product Roadmap / EPIC 12 (Per-App Window Policies & Smart Floating Stacking)
- **Classification**: Bounded Task
- **Classification signals**:
  - New/changed domain entities: 1 (`WindowPolicy` enum expansion with full Codable representations and associated values or helper structs)
  - Existing persistence schema change: Yes (persisting per-app policy rules dictionary and remembered window frame bounds in `PreferencesStore` or dedicated store)
  - Screens/flows touched: 1 (`ApplicationRulesView.swift` in Settings UI — upgrading from static mockup to fully functioning reactive list with application selector and policy picker)
  - User roles affected: 1 (macOS power user)
  - Cross-cutting impact: Medium (`PreferencesStore` / `WindowPolicy` domain -> `WindowPolicyManager` core -> `ApplicationRulesView` UI -> `EventBus` / `AccessibilityService` window repositioning)
  - Estimated code lines changed: ~350-500 lines
  - Reversible without user impact: Yes (default policy remains `.currentSpace`, disabling custom rules returns to standard behavior)
- **Protocol selected**: Bounded Task Pipeline (Stages 1 → 2 (interactive interview) → 4 (domain modeling) → 5 (risk scan) → 6 (user stories & spec) → 7 → 8). Stage 3 gap analysis skipped per Bounded Task protocol.
- **Override**: Matches roadmap Effort `M`, Context-budget `single-session`, Priority `Should-Have (P1)`.
- **Roadmap dependencies**: Depends-on `US-WORK-013` (delivered & verified). Blocks: `(none)`.

## Acceptance Criteria Anchors (from Roadmap)

1. Cung cấp các chính sách cửa sổ linh hoạt trong `WindowPolicy`:
   - `Current Space`: Luôn mở ở Space hiện tại.
   - `Floating`: Cửa sổ nổi tự do, không bị ép vào layout dạng lưới.
   - `Remember Position`: Luôn mở lại đúng vị trí frame đã đóng lần trước.
   - `Assigned Layout`: Tự động snap vào một zone định sẵn (ví dụ: VS Code luôn mở Left 60% hoặc Right Half).
2. Cơ chế `Smart Window Stack`: Khi mở một app dạng Floating (như Telegram/Slack), cửa sổ này hiển thị nổi phía trên mà không làm xáo trộn bố cục các cửa sổ đang chia đôi bên dưới.
3. Khi đóng app nổi, tiêu điểm (focus) tự động trả lại cho ứng dụng làm việc gần nhất bên dưới một cách tự nhiên.
4. Priority rule precedence: App-specific rule ghi đè Default rule.

## One-line Problem Statement

Allow users to configure customized window placement policies on a per-app basis (floating, remember last position, assigned layout, or current space) and maintain a non-intrusive floating window stacking hierarchy that preserves underlying tiled layouts and restores prior focus when dismissed.
