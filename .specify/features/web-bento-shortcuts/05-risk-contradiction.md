# 05-Risk & Contradiction Scanner: US-WEB-027

- **Feature**: Bento Grid Features Showcase, Metrics Proof Ribbon & Interactive Shortcut Matrix
- **Slug**: `web-bento-shortcuts`
- **Date**: 2026-09-08

---

## 1. Risk Register

| Risk ID     | Description                                                                                                               | Severity | Likelihood | Mitigation Strategy                                                                                                                                                  |
| :---------- | :------------------------------------------------------------------------------------------------------------------------ | :------: | :--------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **RISK-01** | `navigator.clipboard.writeText` fails in non-HTTPS or permission-restricted environments.                                 |  Medium  |    Low     | Wrap clipboard call in a defensive try/catch block with fallback or silent non-crashing behavior.                                                                    |
| **RISK-02** | Asymmetric Bento Grid (2-column spans) causes awkward stacking or horizontal overflow on narrow mobile screens (< 480px). |   High   |   Medium   | Use responsive CSS Grid with `@media (max-width: 1023px)` (2 cols) and `@media (max-width: 640px)` (single column `1fr`), resetting `grid-column: span 1` on mobile. |
| **RISK-03** | Real-time shortcut search causes layout shifts or list jumping when typing rapidly.                                       |   Low    |    Low     | Maintain a CSS-driven filtering strategy using `hidden` attribute or class toggles without rebuilding the DOM, and preserve minimum height.                          |
| **RISK-04** | Font rendering mismatch between macOS key symbols (`⌃`, `⌥`, `⇧`, `⌘`) across non-Apple OS browsers (Windows, Android).   |  Medium  |   Medium   | Use system fallback stack with explicit Unicode symbols and fallback to `SF Mono, Menlo, Consolas, monospace`.                                                       |

---

## 2. Contradiction & Deadlock Scan

- **Contradiction Scan**:
  - _Conflict_: AC states "sử dụng ảnh WebP tối ưu" in one bullet, but Stage 2 customer interview explicitly signed off on "Native SVG/CSS micro-illustrations" for zero network overhead, instant rendering, and Retina crispness.
  - _Resolution_: Resolution recorded in `01-elicitation.md` DEC-01: Native vector SVG/CSS micro-illustrations are used for all 6 cards. Vector SVGs offer 0KB network payload and infinite scalability without pixelation.
- **Scope Creep Guard**:
  - Web browser cannot and should not attempt to execute macOS native global hotkeys or remap system shortcuts. The matrix is strictly an exploratory and copyable cheatsheet.

---

## 3. MoSCoW Scope Lock

### Must-Have

- [x] 6-card Bento Grid representing the 6 core pillars: Top-Edge Picker, Collinear 2D Resize, Current Space Anchoring, Workspaces & Presets, Quake Scratchpad, Multi-Monitor Topology.
- [x] Asymmetric desktop layout (2 wide featured cards + 4 standard cards) collapsing to 1 column on mobile.
- [x] Native SVG/CSS micro-illustrations inside each card adapting to Dark/Light theme.
- [x] Metrics Proof ribbon displaying the 5 engineering proofs: Swift 6 Strict Concurrency, 0 Private APIs, 470+ Unit Tests, < 1ms Snap Math, 60 FPS Divider Resize.
- [x] Interactive Shortcut Matrix with category filter pills (`Tất cả`, `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`).
- [x] Click-to-copy key combination with visual feedback (`Copied!`).
- [x] Strict Anti-AI-Slop compliance: 1px hairline borders, system typography, authentic keycap styling.

### Should-Have

- [x] Real-time shortcut keyword search input filter.
- [x] Count badge per category filter pill showing number of shortcuts available.

### Won't-Have (Strictly Out of Scope)

- ❌ In-browser shortcut recorder or key binding customizer (belongs in native macOS app Settings).
- ❌ Heavy external iconography libraries or bloated font packs.
- ❌ Audio click effects or unrequested animations.
