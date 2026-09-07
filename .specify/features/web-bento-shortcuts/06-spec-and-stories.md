# 06-Spec and Stories: US-WEB-027

- **Feature**: Bento Grid Features Showcase, Metrics Proof Ribbon & Interactive Shortcut Matrix
- **Slug**: `web-bento-shortcuts`
- **Date**: 2026-09-08

---

## 1. System Requirements (SRS)

### REQ-WBENTO-001: 6-Card Bento Grid Layout & Content

- **Description**: The `#features` section shall present a 6-card Bento Grid highlighting FlowSnap's core differentiators:
  1. Top-Edge Snap Layout Picker (Featured / Hero - 2 cols on desktop)
  2. Quake-Style Quick Scratchpad (Featured / Hero - 2 cols on desktop)
  3. Adaptive Collinear 2D Resize (Standard - 1 col)
  4. Current Space Preservation (Standard - 1 col)
  5. Intent-Based Workspaces & Presets (Standard - 1 col)
  6. Display-Aware Multi-Monitor Topology (Standard - 1 col)
- **Traceability**: Derived from US-WEB-027 AC 1 and Stage 2 DEC-03.

### REQ-WBENTO-002: Native SVG/CSS Micro-Illustrations

- **Description**: Each Bento card shall contain an inline SVG/CSS micro-diagram illustrating the feature's physical behavior without external image dependencies, responsive to Dark/Light mode tokens.
- **Traceability**: Derived from US-WEB-027 AC 1 and Stage 2 DEC-01.

### REQ-WBENTO-003: Metrics Proof Ribbon Display

- **Description**: A dedicated metrics ribbon shall render 5 verifiable engineering claims:
  1. `Swift 6 Strict Concurrency` (Actor Isolation, 0 data races)
  2. `0 Private APIs` (100% public AppKit & AXUIElement)
  3. `470+ Unit & Integration Tests` (100% math coverage)
  4. `< 1ms Snap Math` (Zero disk I/O calculation)
  5. `60 FPS Divider Resize` (Rate-limited fluid drag)
- **Traceability**: Derived from US-WEB-027 AC 2.

### REQ-WBENTO-004: Interactive Shortcut Matrix Category Filtering

- **Description**: The `#shortcuts` section shall render a catalog of at least 14 shortcuts grouped into 4 categories (`Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`) plus an `All` (`Tất cả`) tab. Selecting a tab shall immediately filter the displayed shortcuts without page reload.
- **Traceability**: Derived from US-WEB-027 AC 3 and Stage 2 DEC-02.

### REQ-WBENTO-005: Real-time Shortcut Search & Zero-State Handling

- **Description**: The shortcut matrix shall include a live search input allowing users to filter by shortcut key (e.g. `⌃⌥`, `Space`) or action name. If no shortcuts match the query, a clean empty state with a "Clear search" action shall appear.
- **Traceability**: Derived from Stage 2 DEC-02.

### REQ-WBENTO-006: Click-to-Copy Shortcut Interaction

- **Description**: Clicking any shortcut key pill or copy button shall copy the shortcut combination to the user's system clipboard and show a temporary visual confirmation (`Copied!`) for 1500ms.
- **Traceability**: Derived from Stage 2 DEC-02.

---

## 2. User Stories & Acceptance Scenarios

### US-WBENTO-001: Explore Core Capabilities via Bento Grid

- **Given** a visitor lands on the FlowSnap homepage and scrolls to `#features`,
- **When** the Bento Grid enters the viewport,
- **Then** they see 6 structured cards with 2 wide hero cards and 4 compact cards, each featuring a crisp micro-illustration, title, badge, and descriptive summary with 1px hairline borders.

### US-WBENTO-002: Review Verifiable Engineering Metrics Proof

- **Given** a power user reviews the credibility and architecture of FlowSnap,
- **When** they view the Metrics Proof ribbon,
- **Then** they see 5 distinct metric cards showcasing Swift 6 Concurrency, 0 Private APIs, 470+ Unit Tests, < 1ms Snap Math, and 60 FPS Divider Resize.

### US-WBENTO-003: Filter and Search Keyboard Shortcuts Matrix

- **Given** a user navigates to the `#shortcuts` section,
- **When** they click the `Màn hình` category pill or type `throw` or `⌃⌥⇧` in the search bar,
- **Then** the list instantly updates to show only multi-display throw shortcuts matching the criteria.

### US-WBENTO-004: One-Click Copy Shortcut Combination

- **Given** a user finds the shortcut `⌥Space` for Quake Scratchpad,
- **When** they click the shortcut pill or copy button,
- **Then** the text `⌥Space` is copied to their clipboard and the button temporarily reflects "Copied!" with a green indicator.
