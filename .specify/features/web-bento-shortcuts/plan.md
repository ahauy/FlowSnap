# Architecture & Implementation Plan: Bento Grid & Shortcut Matrix (US-WEB-027)

## 1. Architectural Strategy

- **Deep Module Separation (`codebase-design`)**:
  - `web/src/data/`: Pure data fixtures (`bento-data.ts`, `metrics-data.ts`, `shortcuts-data.ts`) containing static structured data, decoupled from rendering logic.
  - `web/src/components/MetricsProof.astro`: Renders the 5 verifiable engineering claims in a clean, high-density technical strip.
  - `web/src/components/BentoGrid.astro`: Renders the 6-card asymmetric Bento Grid with inline native SVG/CSS vector micro-illustrations, responsive breakpoints (desktop 3 cols, tablet 2 cols, mobile 1 col).
  - `web/src/components/ShortcutMatrix.astro`: Renders the interactive shortcut explorer with category filter pills (`Tất cả`, `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`), live search bar, macOS keycap styling, and 1-click clipboard copy feedback.
- **Strict Anti-AI-Slop Governance (`web/DESIGN.md`)**:
  - 1px hairline borders (`var(--color-border)`).
  - True system font stack (`-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Mono"`).
  - No generic multi-color gradients or unrequested floating blurred orbs.
  - Authentic macOS keycap styling with subtle inset shadow and tactile active states.
- **Zero-Dependency Lightweight Client Interactivity**:
  - Filter and search functionality implemented in vanilla TypeScript/JavaScript with sub-16ms execution.
  - Data-attribute driven filtering (`data-category`, `data-search-text`) ensures zero layout thrashing or DOM destruction.
  - Defensive `navigator.clipboard.writeText` implementation with graceful fallback.

---

## 2. File Modification & Creation Manifest

```
web/
├── src/
│   ├── data/
│   │   ├── bento-data.ts               # [NEW] 6 Core Feature Pillars data fixture
│   │   ├── metrics-data.ts             # [NEW] 5 Verifiable Engineering Proofs data fixture
│   │   └── shortcuts-data.ts           # [NEW] 15 Interactive Shortcuts catalog
│   ├── components/
│   │   ├── MetricsProof.astro          # [NEW] Verifiable metrics proof ribbon
│   │   ├── BentoGrid.astro             # [NEW] Asymmetric 6-card Bento Grid showcase
│   │   └── ShortcutMatrix.astro        # [NEW] Interactive keyboard shortcut explorer
│   └── pages/
│       └── index.astro                 # [MODIFY] Replace placeholder boxes with live components
└── tests/
    └── bento-shortcuts.test.mjs        # [NEW] Automated tests for data integrity & requirements
```

---

## 3. Implementation Phasing

1. **Phase 1: Data Fixtures (`web/src/data/`)**:
   - Create `bento-data.ts` with 6 detailed feature definitions and SVG configuration.
   - Create `metrics-data.ts` with 5 verifiable engineering claims.
   - Create `shortcuts-data.ts` with 15 categorized keyboard shortcuts.
2. **Phase 2: Metrics Proof Component (`MetricsProof.astro`)**:
   - Construct responsive proof ribbon with vector badge icons, metric values, and descriptions.
   - Integrate into `#features` section.
3. **Phase 3: Bento Grid Component (`BentoGrid.astro`)**:
   - Construct asymmetric 6-card grid with 2 hero cards (`col-span-2`) and 4 standard cards (`col-span-1`).
   - Implement native SVG/CSS micro-illustrations for all 6 pillars (Top-Edge, Collinear 2D, Current Space, Workspaces, Quake Scratchpad, Multi-Monitor).
   - Implement hover elevation and subtle borders conforming to `web/DESIGN.md`.
4. **Phase 4: Interactive Shortcut Matrix (`ShortcutMatrix.astro`)**:
   - Construct category filter tabs (`Tất cả`, `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`) with count badges.
   - Construct live search input bar with clear action and zero-match empty state.
   - Construct shortcut cards/table with authentic macOS keycaps (`SF Mono`, border, subtle shadow).
   - Wire client-side vanilla filter & search controller + 1-click clipboard copy with `Copied!` feedback.
5. **Phase 5: Page Integration & Verification (`index.astro` & `bento-shortcuts.test.mjs`)**:
   - Mount `<MetricsProof />`, `<BentoGrid />`, and `<ShortcutMatrix />` into `web/src/pages/index.astro`.
   - Write and run automated Node.js test suite `node tests/bento-shortcuts.test.mjs`.
   - Run `npm run build` in `web/` to verify zero Astro/TypeScript compilation errors.
