# Functional Specification: Bento Grid Features Showcase, Proof & Interactive Shortcut Matrix (US-WEB-027)

## 1. Functional Requirements (`REQ-WBENTO-###`)

- **`REQ-WBENTO-001` (Asymmetric Bento Grid Showcase Layout)**:
  - The `#features` section SHALL replace its placeholder box with an asymmetric 6-card Bento Grid representing the 6 core pillars of FlowSnap.
  - Desktop layout (>= 1024px) SHALL feature a 3-column grid structure:
    - **Hero Card 1 (Top-Edge Snap Layout Picker)**: Spans 2 columns (`col-span-2`).
    - **Standard Card 2 (Adaptive Collinear 2D Resize)**: Spans 1 column (`col-span-1`).
    - **Standard Card 3 (Current Space Preservation)**: Spans 1 column (`col-span-1`).
    - **Standard Card 4 (Intent-Based Workspaces & Presets)**: Spans 1 column (`col-span-1`).
    - **Hero Card 5 (Quake-Style Quick Scratchpad)**: Spans 2 columns (`col-span-2`).
    - **Standard Card 6 (Display-Aware Multi-Monitor Topology)**: Spans 1 column (`col-span-1`).
  - Tablet layout (641px - 1023px) SHALL collapse to a 2-column grid where hero cards and standard cards adapt cleanly.
  - Mobile layout (<= 640px) SHALL collapse to a single column (`grid-template-columns: 1fr`) with `grid-column: span 1` across all cards.
  - _Derived from_: `US-WEB-027 AC 1`, `DEC-03`, `REQ-WBENTO-001`.

- **`REQ-WBENTO-002` (Native Vector Micro-Illustrations for Bento Cards)**:
  - Each Bento card SHALL contain a responsive, inline vector SVG/CSS diagram illustrating the feature's physical behavior without external image dependencies:
    1. **Top-Edge Picker**: Miniature macOS window dragging up towards top edge, showing the slide-down multi-zone picker highlight.
    2. **Collinear 2D Resize**: Two adjacent window rectangles sharing a collinear border with a crosshair cursor handle and dynamic resizing directional indicators.
    3. **Current Space Preservation**: macOS desktop frame with Space indicator badge (`Space 1 (Active)`) and window pinned cleanly without space jumps.
    4. **Workspaces & Presets**: Tri-split layout arrangement (VS Code 60%, Chrome 25%, Terminal 15%) tagged with preset name `Coding Flow` and hotkey badge `⌃⌥⌘1`.
    5. **Quake Scratchpad**: Floating terminal window descending from the screen top with blurred backdrop, shortcut badge `⌥Space`, and escape badge `ESC / Click-out`.
    6. **Multi-Monitor Topology**: Dual-display schematic (Primary Retina + Secondary 4K) with curved trajectory arrow indicating `⌃⌥⇧→` cross-display throw.
  - All micro-illustrations SHALL use semantic CSS variables (`var(--color-border)`, `var(--color-surface)`, `var(--brand-apple-blue)`) adapting automatically to Dark and Light modes.
  - _Derived from_: `US-WEB-027 AC 1`, `DEC-01`, `BR-WBENTO-002`.

- **`REQ-WBENTO-003` (Metrics Proof Ribbon)**:
  - A dedicated technical proof strip SHALL be positioned immediately below the `#features` header or integrated into the section flow.
  - The ribbon SHALL present exactly 5 verifiable engineering metrics:
    1. **Swift 6 Strict Concurrency**: "100% Actor Isolation", zero data race warnings.
    2. **0 Private APIs**: "100% Public AppKit & AX", Gatekeeper safe.
    3. **470+ Unit & Integration Tests**: "100% Math Coverage", verified Swift Testing suite.
    4. **< 1ms Snap Math**: "Zero Disk I/O", instant memory coordinate calculation.
    5. **60 FPS Live Divider Resize**: "16.6ms Throttled", silky smooth multi-window drag.
  - Each metric card SHALL feature a crisp monochrome/accent vector icon, a bold metric value, and a descriptive technical label.
  - _Derived from_: `US-WEB-027 AC 2`, `REQ-WBENTO-003`.

- **`REQ-WBENTO-004` (Interactive Shortcut Matrix & Category Filtering)**:
  - The `#shortcuts` section SHALL replace its placeholder box with an interactive shortcut directory displaying at least 14 shortcuts across 4 categories:
    - **Cửa sổ (Window & Snap)**: 6 shortcuts (`⌃⌥←`, `⌃⌥→`, `⌃⌥↑`, `⌃⌥↓`, `⌃⌥1..4`, `⌃⌥P`).
    - **Màn hình (Multi-Display)**: 3 shortcuts (`⌃⌥⇧→`, `⌃⌥⇧←`, `⌃⌥⇧⌘→`).
    - **Workspace (Workspaces & Presets)**: 3 shortcuts (`⌃⌥⌘1`, `⌃⌥⌘2`, `⌃⌥⌘S`).
    - **Tiện ích (Utilities & Focus)**: 3 shortcuts (`⌥Space`, `⌃⌘F`, `⌃⌥,`).
  - A tab bar with category filter pills SHALL be displayed: `Tất cả` (All), `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`.
  - Clicking any category pill SHALL immediately filter the list without page reload. The active tab SHALL feature an active indicator style.
  - Each category pill SHALL include an badge counter showing the number of available shortcuts in that category.
  - _Derived from_: `US-WEB-027 AC 3`, `DEC-02`, `REQ-WBENTO-004`.

- **`REQ-WBENTO-005` (Live Keyword & Shortcut Search)**:
  - The shortcut matrix SHALL provide an instant text input search bar with placeholder "Tìm kiếm theo phím tắt hoặc tác vụ... (vd: ⌥Space, ném màn hình, snap)".
  - Typing in the search input SHALL filter shortcuts in real time across action name, shortcut keys, and description.
  - If no shortcuts match the active search and category filter, an empty state SHALL be rendered with text "Không tìm thấy phím tắt phù hợp" and a "Xóa tìm kiếm" button to reset the query.
  - _Derived from_: `DEC-02`, `REQ-WBENTO-005`.

- **`REQ-WBENTO-006` (1-Click Clipboard Copy with Feedback)**:
  - Each shortcut row/card SHALL feature a copy button and click-to-copy capability on the keycap pill container.
  - Clicking copy SHALL call `navigator.clipboard.writeText(...)` to copy the canonical shortcut string (e.g. `⌥Space`).
  - The copy button SHALL transition to a success state displaying "Copied!" (or a green checkmark) for 1500ms before returning to neutral.
  - The operation SHALL be wrapped in a defensive try/catch to prevent JavaScript errors in restricted browser contexts.
  - _Derived from_: `DEC-02`, `REQ-WBENTO-006`, `BR-WBENTO-004`.

---

## 2. Non-Functional Requirements (`NFR-WBENTO-###`)

- **`NFR-WBENTO-001` (Anti-AI-Slop & Design System Compliance)**:
  - All cards, borders, and controls SHALL strictly use tokens from `web/DESIGN.md`: 1px hairline border (`var(--color-border)`), Obsidian surface (`#121215` / `#fafafa`), and Apple blue highlights (`#0071e3` / `#0a84ff`).
  - Zero unrequested rainbow gradients or floating blurry neon blobs.
- **`NFR-WBENTO-002` (Performance & Bundle Budget)**:
  - Zero external CDN dependencies, zero webfont network requests.
  - Inline SVG micro-illustrations ensure 0KB image payload and zero layout shift (CLS 0.0).
  - Client-side script size budget < 5KB minified.
- **`NFR-WBENTO-003` (Accessibility & A11y)**:
  - Filter category tabs implement ARIA `role="tablist"` and `role="tab"` with `aria-selected` attributes.
  - Search input implements `aria-label="Tìm kiếm phím tắt"`.
  - Copy action results announced via `aria-live="polite"`.
  - Contrast ratios meet WCAG 2.2 AA standards (minimum 4.5:1 text contrast).
