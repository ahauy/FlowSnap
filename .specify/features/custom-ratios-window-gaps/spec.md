# Technical Specification: Custom Ratios & Window Gaps (US-SNAP-008)

**Status:** v1.0 (Derived from baseline.md v1.0 SIGNED-OFF)
**Slug:** custom-ratios-window-gaps
**Epic:** EPIC-08 — Adaptive Multi-Window Resize & Gaps
**Sprint:** Sprint 2

---

## 1. Technical Scope & Boundaries

### 1.1 In Scope

- `LayoutZone` gains 7 new asymmetric/3-column cases + `left70_30` alias (ASM-CRW-001).
- `LayoutCalculating.frame(for:in:gap:uniform:)` gains a `uniform` parameter (ASM-CRW-002).
- `PreferencesStore` converts to an `actor` with `@Published` gap + default ratio (ASM-CRW-003).
- `SnapEngine` consumes `PreferencesStore.windowGap` as fallback when `gap` is not provided.
- `GeneralSettingsView` stub replaced with a real gap Picker.
- `LayoutRatio` new enum type (Codable + Sendable) in Domain.

### 1.2 Out of Scope

- Drag-to-snap edge drop for new ratios (future US).
- Per-app gap/ratio overrides (roadmap TODO, not this US).
- Custom (arbitrary) user-defined ratios beyond the enumerated set.
- Vertical gap (gap is width-only; height partition gap unchanged).
- Touch bar / accessibility shortcuts for new ratios.

### 1.3 Source-Breaking Change Notice

`LayoutCalculating` protocol gains a `uniform` parameter. The only conformer is
`LayoutEngine` (verified in `FlowSnap/Core/Layout/`). Blast radius is one file +
`SnapEngine` internal call sites.

---

## 2. Technical Stack & Constraints (from 00-tech-context.md)

| Item | Constraint |
| :--- | :--------- |
| Language | Swift 6.0 (strict concurrency, zero warnings) |
| Frameworks | SwiftUI + AppKit (macOS 14.0+) |
| Architecture | DDD & Deep Modules |
| Concurrency | Actors, @MainActor, Sendable |
| Storage | UserDefaults + Local JSON |
| Build | XcodeGen (project.yml) + Xcode 16.0+ |
| Test | Swift Testing (@Test) + XCTest |
| Lint | swiftlint lint --strict must pass |

Hard DoD rules: no force unwrap / try! / as!; file < 800 LOC; function < 50 LOC;
100% mathematical coverage on LayoutEngine new ratio paths.

---

## 3. User Journeys & Functional Requirements

### 3.1 Journey J-CRW-1: User sets a custom gap in Settings

1. User opens Settings → General.
2. Gap Picker shows options 0/4/8/12/16 px with a 2-column visual preview.
3. User selects 12 px; value persists immediately via `PreferencesStore`.
4. Next snap operation uses 12 px gap on both inner partitions AND outer edges.

### 3.2 Journey J-CRW-2: User snaps to a 60/40 asymmetric zone

1. User presses the hotkey for `left60_40`.
2. `SnapEngine` reads gap (explicit or `PreferencesStore.windowGap`).
3. `LayoutEngine.frame(for: .left60_40, in:, gap:, uniform:)` returns left 60% frame.
4. Window is positioned with minSize anchoring respected (BR-CRW-007).

### 3.3 Journey J-CRW-3: Default ratio persistence

1. User sets default ratio to `.eightyTwenty` in Settings.
2. Ratio persisted via `PreferencesStore.defaultRatio`.
3. New multi-window layouts default to the persisted ratio.

### Functional Requirements Traceability

| REQ-ID | Requirement | Verified By |
| :----- | :---------- | :---------- |
| REQ-CRW-01 | New ratio frames (60/40, 80/20, 25/50/25) | T-TEST-01, T-TEST-02 |
| REQ-CRW-02 | Uniform gap effectiveWidth = totalWidth - 2*gap | T-TEST-01 |
| REQ-CRW-03 | Actor PreferencesStore with gap + defaultRatio | T-TEST-03 |
| REQ-CRW-04 | DI registration in AppDependencies | build/compile + manual |
| REQ-CRW-05 | Gap Picker UI in GeneralSettingsView | snapshot + manual |
| REQ-CRW-06 | SnapEngine fallback to PreferencesStore.windowGap | unit test |
| REQ-CRW-07 | leftTwoThirds deprecation alias to left70_30 | build (no warnings) |

---

## 4. Non-Functional Requirements (NFR-)

```
NFR-CRW-01 (Performance): frame() must remain O(1); no allocation beyond a
single CGRect per call. Gap read path must not block the UI; actor read of a
single Double is acceptable.

NFR-CRW-02 (Concurrency): Swift 6 strict concurrency — zero warnings.
PreferencesStore must be Sendable-aware; @Published access on MainActor.

NFR-CRW-03 (Compatibility): Legacy call sites passing gap=0 must produce
byte-identical frames before/after the change (BR-CRW-004).

NFR-CRW-04 (Maintainability): Each file < 800 LOC; each function < 50 LOC.
Protocol surface stays minimal (Deep Module).

NFR-CRW-05 (Testability): 100% mathematical coverage of new ratio paths.
Pure function tests without AppKit/AX dependencies.

NFR-CRW-06 (Lint): swiftlint lint --strict must pass.
```

---

## 5. Edge Cases, Error Handling & Recovery

| EC-ID | Edge Case | Behavior |
| :---- | :-------- | :------- |
| EC-CRW-01 | `gap` > totalWidth/2 with uniform=true | effectiveWidth clamps to 0 (`max(0, ...)`); frames degenerate to empty width, no negative width (already guarded). |
| EC-CRW-02 | Gap value outside {0,4,8,12,16} | Clamped down to nearest valid set value (BR-CRW-002). |
| EC-CRW-03 | First launch, no stored preference | Defaults: gap=4, defaultRatio=.equal (BR-CRW-006). |
| EC-CRW-04 | Zone width after gap < minSize width | Frame clamped to minSize; gap reduced on that edge only (BR-CRW-007). |
| EC-CRW-05 | Odd pixel widths with gap | Flooring policy per zone (BR-LAYOUT-002); invariant holds with gap re-expressed. |
| EC-CRW-06 | `.leftTwoThirds` passed from legacy call sites | Forwards to `.left70_30` semantics; deprecation warning surfaced once, no runtime change. |
| EC-CRW-07 | `frames(for:in:layout:gap:)` window count < layout zones | Truncated to `min(count, zones.count)` — unchanged behavior. |
| EC-CRW-08 | Actor contention on hot snap path | Gap read is a single Double; if profiling shows contention, cache via `nonisolated` snapshot (RISK-CRW-03 mitigation). |

---

## 6. Error Handling Strategy

- No throwing functions introduced; failure modes are representational (empty
  CGRect, nil optionals) and handled at the call site, consistent with existing
  `LayoutEngine` design.
- `PreferencesStore` read failures (missing key) recover to documented defaults.
- No network calls, so no retry/timeout policy required.

---

## 7. Clarifications

### 7.1 Accepted Elicitation Decisions (from baseline)

- **ASM-CRW-001**: Incremental `LayoutZone` cases — enum-based approach chosen.
- **ASM-CRW-002**: Hybrid gap semantics — `uniform` parameter, legacy inner-only default.
- **ASM-CRW-003**: Actor + Combine `PreferencesStore`.

### 7.2 Open Clarifications (proposed, awaiting sign-off)

None blocking at spec level — all major decisions resolved during Phase 1.
One minor note flagged for the implementer in plan.md ADR-003 (see plan.md).

---
