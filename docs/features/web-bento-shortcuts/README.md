# Feature: Bento Grid Features Showcase, Proof Ribbon & Shortcut Matrix (`web-bento-shortcuts`)

## Overview

- **User Story**: `US-WEB-027` (Bento Grid Features Showcase, Proof & Interactive Shortcut Matrix)
- **Epic**: `EPIC 16` — Official Product Landing Page, 3D Interactive Showcase & Web Distribution Portal (Sprint 8)
- **Platform**: Web (`web/`), static HTML generation via Astro v7
- **Design System**: Apple macOS Human Interface Guidelines (HIG) + Shadcn Minimalist Precision (`web/DESIGN.md`)

---

## Architectural Highlights

1. **6-Card Asymmetric Bento Grid (`BentoGrid.astro`)**:
   - Replaces the placeholder `#features` section with an asymmetric 3-column Bento Grid on desktop (>= 1024px).
   - Features 2 prominent hero cards (`col-span-2`):
     - **Top-Edge Snap Layout Picker**: Highlights Windows 11-style top drop-down menu on macOS.
     - **Quake-Style Quick Scratchpad**: Highlights global instant summon (`⌥Space`) and zero-shrink dismissal.
   - Features 4 standard cards (`col-span-1`):
     - **Adaptive Collinear 2D Resize**: Highlights multi-window 60 FPS divider drag and cross-junction handling.
     - **Current Space Preservation**: Highlights zero private API app launch anchoring in active Space.
     - **Intent-Based Workspaces & Presets**: Highlights one-click multi-window restore (Coding, Research).
     - **Display-Aware Multi-Monitor Topology**: Highlights cross-display window throw (`⌃⌥⇧→`) and coordinate inversion.
   - Automatically collapses to 2 columns on tablet and 1 column on mobile devices (< 680px).

2. **Native SVG / Vector Micro-Illustrations (`DEC-01`)**:
   - Each Bento card contains a custom inline SVG diagram rendering authentic mini macOS frames, window hierarchies, trajectory arrows, and layout partitions.
   - Zero external raster images: 0KB network payload, zero FOUC, instant rendering, crisp on Apple Retina displays, and automatically responsive to Dark/Light modes via semantic tokens.

3. **Verifiable Engineering Metrics Proof Ribbon (`MetricsProof.astro`)**:
   - Positions a dedicated technical proof strip displaying 5 verifiable claims:
     1. **Swift 6 Strict Concurrency**: 100% Actor isolation, zero data race warnings.
     2. **0 Private APIs**: 100% Public AppKit & Accessibility (`AXUIElement`), Gatekeeper safe.
     3. **470+ Automated Tests**: Swift Testing (`@Test`) suite covering 100% geometric math.
     4. **< 1ms Snap Math**: In-memory coordinate calculation with zero disk I/O.
     5. **60 FPS Divider Dragging**: 16.6ms throttled live multi-window resizing.
   - Styled with 1px hairline borders, subtle hover lift, and monochrome vector icons.

4. **Interactive Shortcut Matrix (`ShortcutMatrix.astro`)**:
   - Catalogs 15 signature FlowSnap keyboard shortcuts across 4 categories:
     - `Cửa sổ` (Window & Snap): 6 shortcuts.
     - `Màn hình` (Multi-Display): 3 shortcuts.
     - `Workspace` (Workspaces & Presets): 3 shortcuts.
     - `Tiện ích` (Utilities & Focus): 3 shortcuts.
   - Provides category filter tabs (`Tất cả`, `Cửa sổ`, `Màn hình`, `Workspace`, `Tiện ích`) with dynamic item counts.
   - Includes real-time keyword search across action titles, shortcut keys, and descriptions.
   - Renders authentic macOS keycap pills (`SF Mono`, bordered, embossed 3D pill look).
   - Features 1-click clipboard copy (`navigator.clipboard.writeText`) with temporary `Copied!` visual confirmation badge (1500ms).
   - Provides a zero-match empty state with a 1-click filter reset action.

5. **Anti-AI-Slop & Design Tokens Compliance**:
   - Strict adherence to `web/DESIGN.md`:
     - 1px hairline borders (`var(--color-border)`).
     - Clean Obsidian canvas (`#09090b` dark, `#ffffff` light).
     - Zero unrequested purple/pink neon gradients or blurry floating orbs.
     - Accessible ARIA roles (`role="tablist"`, `role="tab"`, `aria-selected`, `aria-live="polite"`).

---

## Deliverables & File Tree

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
│       └── index.astro                 # [MODIFY] Mounts BentoGrid, MetricsProof, and ShortcutMatrix
└── tests/
    └── bento-shortcuts.test.mjs        # [NEW] Automated tests for data integrity & interactions
```

---

## Verification & Testing

Run the automated test suite from the `web/` directory:

```bash
npm test
```

Verification covers:

- `TC-001`: 6 Bento cards rendered with correct hero/standard grid spans.
- `TC-002`: 6 Native vector SVG micro-illustrations rendered inside card stages.
- `TC-003`: 5 Verifiable technical proof metrics rendered in ribbon.
- `TC-004`: Shortcut Matrix category tabs and 15 shortcut cards with macOS keycaps.
- `TC-005`: Live search input and empty state elements.
- `TC-006`: 1-Click clipboard copy data attributes and copy buttons.
- `TC-007`: Anti-AI-slop and design token compliance (zero generic gradients, hairline borders).
- Regression suite `tests/desktop-simulator.test.mjs` passes 100%.
