# Changelog: `web-bento-shortcuts`

All notable changes to the `web-bento-shortcuts` feature will be documented in this file.

## [1.0.0] - 2026-09-08

### Added

- **6-Card Asymmetric Bento Grid (`BentoGrid.astro`)**: Replaced placeholder in `#features` with a 3-column asymmetric grid featuring 2 hero cards (`col-span-2`: Top-Edge Picker and Quake Scratchpad) and 4 standard cards (`col-span-1`: Collinear 2D Resize, Current Space Preservation, Workspaces & Presets, and Multi-Monitor Topology).
- **Native SVG / Vector Micro-Illustrations (`DEC-01`)**: Implemented 6 responsive, zero-network-payload inline vector diagrams with dark/light theme tokens.
- **Verifiable Metrics Proof Ribbon (`MetricsProof.astro`)**: Created a technical credibility banner highlighting Swift 6 Concurrency, 0 Private APIs, 470+ Tests, < 1ms Math, and 60 FPS Divider Dragging.
- **Interactive Shortcut Matrix (`ShortcutMatrix.astro`)**: Implemented 15 signature shortcuts categorized into 4 groups (`Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`) with count badges, live keyword search, zero-state fallback, and authentic macOS keycap styling.
- **1-Click Clipboard Copy (`REQ-WBENTO-006`)**: Added click-to-copy interaction on keycaps and copy buttons with 1500ms `Copied!` visual confirmation and defensive fallback.
- **Decoupled Data Fixtures (`web/src/data/`)**: Created `bento-data.ts`, `metrics-data.ts`, and `shortcuts-data.ts` for clean separation of concerns.
- **Automated Verification Test Suite (`web/tests/bento-shortcuts.test.mjs`)**: Added Node.js test suite covering TC-001 through TC-007, fully integrated with `npm test`.
