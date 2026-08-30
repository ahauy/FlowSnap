# Elicitation Record: US-SNAP-008 (custom-ratios-window-gaps)

Stage 2 interview — 1 batch, 3 questions (Effort M / single-session calibration).
Conducted by orchestrator per `/command-continue-project` Stage 2 gate; answers confirmed by user.

## Resolved Decisions (Assumption Audit Trail)

| ASM-ID            | Question | Decision | Rationale |
| :---------------- | :------- | :------- | :-------- |
| ASM-CRW-001 | Ratio modelling | **Option A — Incremental enum cases** | Minimal blast radius, consistent with existing `LayoutZone` convention. Deprecate `leftTwoThirds` -> `left70_30`. |
| ASM-CRW-002 | Gap semantics | **Option B — Hybrid (backwards compatible)** | Keep legacy inner-only gap as default; add `uniform` parameter for full 2*gap outer inset. Existing `gap=0` path stays unchanged. |
| ASM-CRW-003 | PreferencesStore wiring | **Option A — Actor + Combine, registered in DI** | Aligns with Swift 6 Strict Concurrency + DDD DI container pattern. |

## Q1: Ratio modelling — Option A (INCREMENTAL)

- Add enum cases for 60/40, 80/20, and 25/50/25.
- Mark `leftTwoThirds` (actual value 70%) as deprecated with `renamed: "left70_30"` (CONTEXT.md rule 5: deprecate, never delete).
- Existing equal-thirds (`leftThird/centerThird/rightThird`) stay as-is.

## Q2: Gap semantics — Option B (HYBRID)

- Default (legacy): inner-gutter-only gap, outer edges flush — unchanged for existing callers.
- New `uniform` behavior: inset ALL zones from both outer edges by `gap` (`effectiveWidth = totalWidth - 2*gap`).
- Backwards compatible; existing `gap: 0` callers unaffected. Settings slider opts in to uniform.

## Q3: PreferencesStore — Option A (ACTOR + COMBINE)

- Convert to `actor`, publish observable values.
- Register in `AppDependencies`.
- Clamp gap to allowed set {0, 4, 8, 12, 16}.
- `SnapEngine` consumes as default; `GeneralSettingsView` binds; tests inject mock.

## Open Items (deferred)

- None within US-SNAP-008 scope. Divider-drag (`LayoutGraph`, collinear edges) deferred to US-SNAP-009 per roadmap.
