# Intake Classification: US-SNAP-008

- **Feature Slug**: `custom-ratios-window-gaps`
- **User Story**: `US-SNAP-008: Tỷ lệ Bố cục Tùy chỉnh (60/40, 70/30) & Khoảng cách Cửa sổ (Custom Ratios & Window Gaps)`
- **Epic**: `EPIC 08: Adaptive Multi-Window Resize (Shared Collinear Divider) & Gaps`
- **Sprint**: Sprint 2
- **Complexity**: Effort M / single-session
- **Routing**: Bounded Task BA Pipeline (Stages 1 -> 2 -> 4 -> 5(light) -> 6(user-stories) -> 7 -> 8). Stage 3 gap-analysis replaced by the light `AS-IS-inventory.md` below because the touched surface is a single pure-math module plus one persistence key.
- **Primary Tech**: Swift 6.0, CoreGraphics pure math, UserDefaults (`PreferencesStore`), SwiftUI Settings, Swift Testing (`@Test`)
- **Depends-on**: `US-SNAP-007` = `[x]` -> gate CLEAR
- **Blocks**: `US-SNAP-009` (adaptive-divider-resize)

## Measurable Signals

| Signal                                | Value                                                            | Class Weight |
| :------------------------------------ | :--------------------------------------------------------------- | :----------- |
| New domain concepts                   | 2 (`LayoutRatio`, gap semantics)                                 | Medium       |
| Files touched (est.)                  | 8-12 (Domain/Layout, Core/Layout, Infra/Persistence, UI/Settings)| Medium       |
| Cross-layer seams crossed             | Core math + Persistence + UI settings                            | Medium       |
| Public API contract change            | `LayoutCalculating.frame(for:in:gap:)` semantics redefined       | High         |
| Persistence/migration risk            | New `UserDefaults` keys, legacy value `0`                        | Low          |
| Business-rule ambiguity in roadmap AC | Gap semantics for outer edges vs inner partitions; ratio modelling | High       |
| Reversibility                         | Pure math, fully unit-testable, reversible                       | High         |

**Classification: Bounded Task** (matches roadmap `Effort: M` + `Context-budget: single-session`; orchestrator override applied per `/command-continue-project` Step 2 routing matrix).

## Scope Anchor (from roadmap AC)

1. `LayoutEngine` computes asymmetric ratios: 60/40, 70/30, 80/20, and 3-column 25/50/25.
2. Window Gap configurable at 0 / 4 / 8 / 12 / 16 px, compensating **both** adjacent-window inner partitions **and** outer screen edges.
3. Gap + default ratio persisted in `PreferencesStore`.

## Explicitly Out of Scope (deferred to US-SNAP-009)

- `LayoutGraph` / BSP tree, collinear edge detection, live divider dragging, `minSize` clamping during divider drag.

## Stage 2 Status

**PAUSED at the interactive elicitation gate.** See `01-elicitation.md` once user answers are recorded.
Zero-hallucination policy applies: no business rule below may be silently assumed by the implementing agent.
