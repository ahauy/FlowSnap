# Test Plan: Bento Grid Features Showcase, Proof & Shortcut Matrix (US-WEB-027)

**Feature slug**: `web-bento-shortcuts`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI (Antigravity) — Stage TDD (Pre-implementation)  
**Traces to**: `.specify/features/web-bento-shortcuts/06-spec-and-stories.md`

---

## Component & Unit Test Cases

### Suite 1: Bento Grid 6-Card Showcase (`BentoGrid.astro`)

#### TC-001: 6 Bento Cards & Asymmetric Grid Structure

```gherkin
Given the BentoGrid component is mounted in #features
When  the HTML page renders
Then  there are exactly 6 feature cards rendered
  And Top-Edge Picker and Quake Scratchpad cards have class 'bento-hero' (col-span-2)
  And Collinear 2D Resize, Current Space, Workspaces & Presets, and Multi-Monitor have class 'bento-standard' (col-span-1)
  And each card contains a badge, title, description, and feature tag list
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Must-Have (P1)
- **Traces to**: `US-WBENTO-001`, `REQ-WBENTO-001`

#### TC-002: Native SVG/CSS Micro-Illustrations

```gherkin
Given the 6 Bento cards are rendered
When  inspecting the card illustration containers
Then  each of the 6 cards contains a dedicated inline SVG/vector diagram:
  1. Top-Edge Picker illustration (window moving to top edge + picker overlay)
  2. Collinear 2D Resize illustration (adjacent windows + crosshair handle)
  3. Current Space illustration (desktop space frame + Space 1 badge)
  4. Workspaces & Presets illustration (tri-split layout + ⌃⌥⌘1 badge)
  5. Quake Scratchpad illustration (top drop-down terminal + ⌥Space badge)
  6. Multi-Monitor illustration (dual-screen schematic + ⌃⌥⇧→ throw arrow)
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Must-Have (P1)
- **Traces to**: `US-WBENTO-001`, `REQ-WBENTO-002`

---

### Suite 2: Metrics Proof Ribbon (`MetricsProof.astro`)

#### TC-003: 5 Verifiable Technical Claims

```gherkin
Given the MetricsProof ribbon is mounted in #features
When  the HTML page renders
Then  there are exactly 5 distinct metric cards rendered:
  1. 'Swift 6' with label 'Strict Concurrency'
  2. '0' with label 'Private APIs'
  3. '470+' with label 'Automated Tests'
  4. '< 1ms' with label 'Snap Math'
  5. '60 FPS' with label 'Divider Dragging'
  And each metric item has a crisp vector icon and subtitle explanation
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Must-Have (P1)
- **Traces to**: `US-WBENTO-002`, `REQ-WBENTO-003`

---

### Suite 3: Interactive Shortcut Matrix (`ShortcutMatrix.astro`)

#### TC-004: Category Filter Tabs & 15 Shortcut Definitions

```gherkin
Given the ShortcutMatrix component is mounted in #shortcuts
When  the HTML page renders
Then  category tab buttons exist for 'all', 'window', 'display', 'workspace', and 'utility'
  And each tab button has an ARIA role and a count badge
  And at least 15 shortcut cards/rows are present in the DOM
  And each shortcut displays authentic macOS modifier keycaps ('SF Mono', border, pill style)
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Must-Have (P1)
- **Traces to**: `US-WBENTO-003`, `REQ-WBENTO-004`

#### TC-005: Live Search Input & Zero-Match Empty State

```gherkin
Given the ShortcutMatrix component is mounted
When  inspecting the search bar controls
Then  an input element with id 'shortcut-search-input' is present
  And a clear search button with id 'shortcut-search-clear' is present
  And an empty state container with id 'shortcut-empty-state' exists with aria-live='polite'
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Should-Have (P1)
- **Traces to**: `US-WBENTO-003`, `REQ-WBENTO-005`

#### TC-006: 1-Click Clipboard Copy Data Contract

```gherkin
Given the shortcut list is rendered
When  inspecting the shortcut items
Then  every item has a 'data-copy-shortcut' attribute containing its canonical shortcut text
  And copy action buttons have class 'copy-shortcut-btn' with visual feedback container
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Must-Have (P1)
- **Traces to**: `US-WBENTO-004`, `REQ-WBENTO-006`

#### TC-007: Anti-AI-Slop & Design System Compliance

```gherkin
Given the build output in dist/index.html
When  checking CSS and markup
Then  card borders strictly use 1px hairline border tokens (var(--color-border))
  And no generic unrequested purple-pink gradients or floating neon orbs are used
  And typography uses system stack (-apple-system, SF Pro Display, SF Mono)
```

- **File**: `web/tests/bento-shortcuts.test.mjs`
- **Priority**: Must-Have (P1)
- **Traces to**: `NFR-WBENTO-001`, `NFR-WBENTO-002`
