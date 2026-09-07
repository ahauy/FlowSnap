# Domain Baseline: Bento Grid Features Showcase, Proof & Interactive Shortcut Matrix (US-WEB-027)

- **Feature**: Bento Grid Features Showcase, Metrics Proof Ribbon & Interactive Shortcut Matrix
- **Slug**: `web-bento-shortcuts`
- **Sprint**: Sprint 8 (Phase 3 Web Distribution & Showcase)
- **Status**: SIGNED-OFF v1.0
- **Version**: 1.0.0
- **Sign-off Date**: 2026-09-08
- **Author**: Business Analyst Pipeline (Approved by User)

---

## 1. Executive Summary

Feature `US-WEB-027` brings FlowSnap's value proposition to life on the web distribution portal by delivering three distinct, high-impact presentation layers:

1. **6-Card Asymmetric Bento Grid**: Highlights FlowSnap's 6 signature innovations (Top-Edge Picker, Collinear 2D Resize, Current Space Anchoring, Workspaces & Presets, Quake Scratchpad, Multi-Monitor Topology) using crisp, responsive native SVG micro-illustrations.
2. **Metrics Proof Ribbon**: Transparently presents 5 verifiable engineering claims (Swift 6 Strict Concurrency, 0 Private APIs, 470+ Unit Tests, < 1ms Snap Math, 60 FPS Divider Resize) to build immediate technical trust.
3. **Interactive Shortcut Matrix**: An intuitive keyboard navigation explorer offering category filtering (`Tất cả`, `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`), live search, authentic macOS SF Mono keycaps, and a 1-click clipboard copy mechanism.

---

## 2. Business Rules & Interaction Policies

- `BR-WBENTO-001` (Zero AI-Slop & Design Consistency): All cards, ribbons, and keycaps must strictly adhere to `web/DESIGN.md` tokens (1px hairline border `#ffffff14` / `#e4e4e7`, Obsidian dark canvas `#09090b`, authentic Apple system font stack). No generic neon or multi-color gradients.
- `BR-WBENTO-002` (Native Vector Visuals): Bento card previews must use lightweight native inline SVGs or CSS layouts rather than heavy raster imagery, ensuring 0KB external network requests and instant Retina sharpness.
- `BR-WBENTO-003` (Non-Destructive Filtering): Category tab and search filtering in the Shortcut Matrix must operate via CSS visibility/attribute toggles without destroying or recreating DOM nodes, maintaining sub-16ms response and zero cumulative layout shift (CLS).
- `BR-WBENTO-004` (Defensive Clipboard Integration): Clicking a shortcut combination or its copy button attempts clipboard write via `navigator.clipboard.writeText` and provides clear visual feedback (`Copied!` indicator for 1500ms) with a graceful fallback.

---

## 3. Scope & Traceability

- **Requirements**: `REQ-WBENTO-001` to `REQ-WBENTO-006`
- **User Stories**: `US-WBENTO-001` to `US-WBENTO-004`
- **Assumptions**: `ASM-WBENTO-001` to `ASM-WBENTO-003`
- **Risks**: `RISK-01` to `RISK-04` (all mitigated)
- **Won't-Have**: In-browser shortcut recorder, heavy third-party icon fonts, audio effects.
