# 01-Elicitation: Bento Grid Features Showcase, Proof & Interactive Shortcut Matrix (US-WEB-027)

- **Feature**: Bento Grid Features Showcase, Metrics Proof Ribbon & Interactive Shortcut Matrix
- **Slug**: `web-bento-shortcuts`
- **Date**: 2026-09-08
- **Interviewer**: Business Analyst (BA) Pipeline / Antigravity
- **Interviewee**: Product Owner / User

---

## 1. Confirmed Domain Decisions (From Stage 2 Interview)

### DEC-01: Visual Representation for Bento Grid Cards

- **Decision**: Native SVG/CSS micro-illustrations.
- **Rationale**: Render lightweight, crisp vector diagrams of window layouts, split screens, and dual monitors directly using CSS & inline SVGs. Guarantees 0KB external network requests, zero FOUC, instant rendering, crispness on Retina displays, and automatic Dark/Light mode theme adaptation.

### DEC-02: Interactive Shortcut Matrix Controls

- **Decision**: Category filter pill tabs + Live search bar + Click-to-copy shortcut combination.
- **Rationale**: Provides comprehensive power-user utility. Filters by categories (`Tất cả`, `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`), enables instant real-time search by shortcut key (e.g. `⌃⌥`) or action description, and offers a 1-click copy button with visual feedback (`Copied!`).

### DEC-03: Bento Grid Desktop Layout Hierarchy

- **Decision**: Asymmetric Bento Grid (2 featured wide cards + 4 compact cards).
- **Rationale**: Creates visual weight and hierarchy for FlowSnap's signature differentiators (`Top-Edge Snap Layout Picker` and `Quake-Style Quick Scratchpad` span 2 columns), while the remaining 4 pillars (`Collinear 2D Resize`, `Current Space Anchoring`, `Workspaces & Presets`, `Multi-Monitor Topology`) span 1 column. Collapses to 2 columns on tablet and 1 column on mobile (< 768px).

---

## 2. Six Core Feature Pillars (Scope Inventory)

1. **Top-Edge Snap Layout Picker**:
   - Description: Drag any window to the top edge to trigger Windows 11-style multi-zone picker (50/50, 70/30, 3-column, 4-quarters).
   - Visual: Mini macOS window dragging upward towards top menu bar with picker overlay sliding down.
2. **Adaptive Collinear 2D Divider Resize**:
   - Description: Drag shared collinear boundaries or 2D cross-junctions to dynamically resize adjacent windows simultaneously at 60 FPS.
   - Visual: T-junction crosshair handle at intersection of two windows with arrows indicating multi-window resizing.
3. **Current Space Preservation**:
   - Description: Launching or restoring apps always honors the current active Space, eliminating macOS automatic space switching.
   - Visual: App window landing strictly within the active desktop space without jarring space jumps.
4. **Intent-Based Workspaces & Presets**:
   - Description: Snapshot multi-window arrangements and restore complete workflows (Coding, Research, Writing) with one shortcut.
   - Visual: Workspace preset card showing multi-app arrangement (VS Code, Chrome, Terminal) restoring in harmony.
5. **Quake-Style Scratchpad**:
   - Description: Instant global hotkey (`⌥Space`) summons floating utility windows and dismisses them with zero shrinkage of background apps.
   - Visual: Terminal overlay sliding in from top with blurred background and Esc/Click-out dismiss indicator.
6. **Display-Aware Multi-Monitor Topology**:
   - Description: Seamless cross-display window throwing (`⌃⌥⇧→`), relative frame scaling, and coordinate inversion math across Retina & 4K screens.
   - Visual: Dual-screen schematic with animated directional throw arrow across screen boundaries.

---

## 3. Metrics Proof Ribbon (Verifiable Engineering Highlights)

| Metric / Claim                    | Verifiable Proof                                                               | Target Audience Value                                           |
| :-------------------------------- | :----------------------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Swift 6 Strict Concurrency**    | 100% Actor isolation, zero data race warnings (`-strict-concurrency=complete`) | Absolute runtime stability & thread safety                      |
| **0 Private APIs**                | Exclusively uses public Accessibility (`AXUIElement`) & AppKit                 | Future-proof against macOS OS updates & Gatekeeper safe         |
| **470+ Unit & Integration Tests** | Swift Testing (`@Test`) suite covering 100% geometric math                     | Rock-solid reliability across all monitor configurations        |
| **< 1ms Snap Math**               | Pure functional geometric transformations with zero disk I/O                   | Instantaneous calculation and zero window move lag              |
| **60 FPS Live Divider Resize**    | Decoupled 16.6ms rate limiter (`LiveResizeThrottler`)                          | Silky smooth dragging without Accessibility event queue backlog |

---

## 4. Shortcut Catalog Taxonomy

### Category 1: Cửa sổ (Window & Snap)

- `⌃⌥←`: Snap Trái 50%
- `⌃⌥→`: Snap Phải 50%
- `⌃⌥↑`: Maximize (Toàn màn hình khả dụng)
- `⌃⌥↓`: Khôi phục vị trí ban đầu (Restore)
- `⌃⌥1 / 2 / 3 / 4`: Snap 4 góc (Góc trên-trái, trên-phải, dưới-trái, dưới-phải)
- `⌃⌥P`: Ghim cửa sổ luôn trên cùng (Always-on-Top Pin)

### Category 2: Màn hình (Multi-Display)

- `⌃⌥⇧→`: Ném cửa sổ sang màn hình bên phải (Next Display)
- `⌃⌥⇧←`: Ném cửa sổ sang màn hình bên trái (Previous Display)
- `⌃⌥⇧⌘→`: Di chuyển toàn bộ Workspace sang màn hình kế tiếp

### Category 3: Workspace (Workspaces & Presets)

- `⌃⌥⌘1`: Khôi phục Preset Coding (VS Code + Terminal + Browser)
- `⌃⌥⌘2`: Khôi phục Preset Research & Writing
- `⌃⌥⌘S`: Lưu trạng thái Workspace hiện tại (Quick Snapshot)

### Category 4: Tiện ích (Utilities & Focus)

- `⌥Space`: Bật/tắt Quake Quick Scratchpad
- `⌃⌘F`: Thoát Fullscreen tức thì (Universal Escape)
- `⌃⌥,`: Mở nhanh Cài đặt FlowSnap (Settings)

---

## 5. Explicit Assumptions (ASM-)

- `ASM-WBENTO-001`: Client-side JavaScript for search and category filtering will be strictly isolated in `web/src/scripts/shortcut-matrix.ts` (or inline script) with zero external dependencies to maintain zero-JS/low-JS performance.
- `ASM-WBENTO-002`: All shortcut keycaps will adhere to macOS keyboard convention order: Control (`⌃`), Option (`⌥`), Shift (`⇧`), Command (`⌘`), Key.
- `ASM-WBENTO-003`: Clipboard copy will use `navigator.clipboard.writeText` with graceful fallback for legacy contexts.
