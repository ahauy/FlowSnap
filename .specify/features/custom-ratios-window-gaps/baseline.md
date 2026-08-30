# Domain Baseline: US-SNAP-008 — Custom Ratios & Window Gaps

**Status:** SIGNED-OFF v1.0
**Date:** 2026-08-30
**Slug:** custom-ratios-window-gaps
**Epic:** EPIC-08 — Adaptive Multi-Window Resize & Gaps
**Sprint:** Sprint 2

---

## 1. Summary

US-SNAP-008 extends the `LayoutEngine` to support asymmetric ratios (60/40, 80/20, 25/50/25) and a configurable window gap (0/4/8/12/16 px) that insets both inner partitions and outer screen edges. The gap preference and default ratio are persisted in an actor-based `PreferencesStore` and consumed by `SnapEngine` at runtime.

**Three decisions resolved via elicitation (ASM-CRW-001/002/003):**

| ASM-ID | Decision | Effect |
| :----- | :------- | :----- |
| ASM-CRW-001 | Incremental `LayoutZone` cases | Add `left60_40`, `right40_60`, `left80_20`, `right20_80`, `left25`, `center50`, `right25`. Deprecate `leftTwoThirds` → `left70_30`. |
| ASM-CRW-002 | Hybrid gap semantics | Legacy inner-only gap remains default. Add `uniform` parameter to `LayoutCalculating.frame(for:in:gap:uniform:)`. When `uniform=true`, `effectiveWidth = totalWidth - 2*gap`. |
| ASM-CRW-003 | Actor + Combine PreferencesStore | `PreferencesStore` becomes an `actor` with `@Published` properties, registered in `AppDependencies`. Gap clamped to `{0,4,8,12,16}`. |

---

## 2. Business Rules (BR-)

```
BR-CRW-001 (Ratio contract): The sum of all zone widths in a row MUST equal
the available width minus total gap insets (uniform or inner-only). No pixel
overflow or underflow. Flooring policy (BR-LAYOUT-002) applies per zone.

BR-CRW-002 (Gap clamping): Gap value MUST be clamped to the set
{0, 4, 8, 12, 16} pixels. Any value outside this set is rounded down to the
nearest valid value. Default = 4.

BR-CRW-003 (Uniform gap symmetry): When uniform=true, the gap MUST be
subtracted from BOTH outer edges: effectiveWidth = totalWidth - 2*gap.
The origin is shifted by gap: effectiveOriginX = originX + gap.

BR-CRW-004 (Legacy compatibility): When uniform=false (default), the
existing inner-only gap behavior is preserved verbatim. All existing call
sites passing gap=0 produce identical results.

BR-CRW-005 (Deprecation alias): LayoutZone.leftTwoThirds is a deprecated
alias for LayoutZone.left70_30. It is NOT removed, only marked
@available(*, deprecated, renamed: "left70_30"). The normalizedRect
value (0.7 width) remains unchanged.

BR-CRW-006 (Preferences persistence): The effective gap + default ratio
are persisted in PreferencesStore. On first launch (no stored value), the
gap defaults to 4 and the default ratio to layoutZones(.leftHalf, .rightHalf).

BR-CRW-007 (minSize interaction): Gap-trimmed frames MUST still respect
minSize anchoring (BR-LAYOUT-005). If a zone's effective width after gap
deduction is less than the window's minSize width, the frame is clamped
to minSize and the gap is reduced on that edge only.
```

---

## 3. Requirements (REQ-)

```
REQ-CRW-01 (LayoutEngine — New Ratios)
  The LayoutEngine must compute frames for the following new zones:
  - left60_40 / right40_60  (60% left, 40% right)
  - left80_20 / right20_80  (80% left, 20% right)
  - left25 / center50 / right25  (25% center-weighted 3-column)
  Coverage: 100% via Swift Testing @Test cases.

REQ-CRW-02 (LayoutEngine — Uniform Gap)
  LayoutCalculating.frame(for:in:gap:uniform:) must accept a uniform
  parameter. When true, compute effectiveWidth = max(0, totalWidth - 2*gap)
  and shift origin by gap. When false, preserve legacy inner-only gap.

REQ-CRW-03 (PreferencesStore — Actor)
  Convert PreferencesStore to an actor. Publish:
  - windowGap: CGFloat  (clamped to {0,4,8,12,16})
  - defaultRatio: LayoutRatio  (new type: .equal, .sixtyForty, .seventyThirty,
    .eightyTwenty, .threeColumn25_50_25)
  Conform to ObservableObject via @MainActor published wrapper.

REQ-CRW-04 (PreferencesStore — DI Registration)
  Register PreferencesStore in AppDependencies. Wire into SnapEngine
  so that SnapEngine reads gap from PreferencesStore as default when
  none is explicitly passed. Wire into GeneralSettingsView for slider UI.

REQ-CRW-05 (GeneralSettingsView — Gap Slider)
  Replace the current stub with a Picker or segmented control offering
  {0, 4, 8, 12, 16} px. Display a visual preview of how the gap affects
  a 2-column layout. Persist immediately via PreferencesStore.

REQ-CRW-06 (SnapEngine — Default Gap Consumption)
  All SnapEngine methods that accept a gap parameter (calculateFrame,
  frame, calculateAXFrame, calculateFrameOnNextDisplay) must fall back
  to PreferencesStore.windowGap when gap is not explicitly provided or
  when gap is nil. This ensures the Settings slider takes effect globally.

REQ-CRW-07 (Deprecation — leftTwoThirds)
  Add @available(*, deprecated, renamed: "left70_30") to LayoutZone.leftTwoThirds.
  Add a new case left70_30 with identical normalizedRect. Update all
  switch statements or add a default case for the deprecated value.
```

---

## 4. User Story (US-) Mapping

| US-ID | Description | Epic | Effort | AC Coverage |
| :---- | :---------- | :--- | :----- | :---------- |
| US-SNAP-008 | Custom Ratios (60/40, 70/30, 80/20) & Window Gaps | EPIC-08 | M | REQ-CRW-01 → REQ-CRW-07 |

---

## 5. Task Breakdown

### 5.1 Domain Layer (~2 files, ~80 new LOC)

| Task | File | Change |
| :--- | :--- | :----- |
| T-DOM-01 | `FlowSnap/Domain/Layout/LayoutZone.swift` | Add 7 new enum cases + deprecation alias. Add `left70_30` case. |
| T-DOM-02 | `FlowSnap/Domain/Layout/LayoutRatio.swift` | **NEW** — Define `LayoutRatio` enum: `.equal`, `.sixtyForty`, `.seventyThirty`, `.eightyTwenty`, `.threeColumn25_50_25`. Codable + Sendable. |

### 5.2 Core Layer (~2 files, ~100 new LOC)

| Task | File | Change |
| :--- | :--- | :----- |
| T-CORE-01 | `FlowSnap/Core/Layout/LayoutCalculating.swift` | Add `uniform` parameter to `frame(for:in:gap:uniform:)` with default `false`. |
| T-CORE-02 | `FlowSnap/Core/Layout/LayoutEngine.swift` | Implement new ratio zones + uniform gap math. Refactor three-column gap logic for 25/50/25 variant. |

### 5.3 Persistence Layer (~1 file, ~60 new LOC)

| Task | File | Change |
| :--- | :--- | :----- |
| T-PERSIST-01 | `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift` | Convert to `actor`. Add `@Published` properties. Add gap clamping. Add `defaultRatio` property. Add `nonisolated` observable wrapper. |
| T-PERSIST-02 | `FlowSnap/App/AppDependencies.swift` | Register `PreferencesStore` instance. Pipe into `SnapEngine` constructor. |

### 5.4 UI Layer (~1 file, ~40 new LOC)

| Task | File | Change |
| :--- | :--- | :----- |
| T-UI-01 | `FlowSnap/UI/Settings/GeneralSettingsView.swift` | Replace stub with gap Picker + ratio Picker. Bind to `PreferencesStore`. |

### 5.5 Tests (~1 file, ~120 new LOC)

| Task | File | Change |
| :--- | :--- | :----- |
| T-TEST-01 | `FlowSnapTests/Core/LayoutEngineTests.swift` | Add test cases for 60/40, 80/20, 25/50/25 ratios. Add uniform gap test cases. Update existing invariant assertions to account for hybrid gap. |
| T-TEST-02 | `FlowSnapTests/Core/LayoutEngineOddPixelTests.swift` | Add odd-pixel tests for new ratios. Re-express existing invariants for gap>0 path. |
| T-TEST-03 | `FlowSnapTests/Infrastructure/PreferencesStoreTests.swift` | **NEW** — Test gap clamping, default ratio persistence, actor isolation. |

---

## 6. Risk Register (RISK-)

| RISK-ID | Description | Likelihood | Impact | Mitigation |
| :------ | :---------- | :--------- | :----- | :--------- |
| RISK-CRW-01 | Existing test invariants (`left.width + right.width == bounds.width`) break when gap>0 with uniform=true | High | Medium | Re-express invariants as `left.width + right.width + gap == bounds.width` for uniform test cases. Legacy gap=0 tests unchanged. |
| RISK-CRW-02 | `leftTwoThirds` deprecation triggers compiler warnings in all switch statements | Medium | Low | Add `@available` annotation. All existing switch statements must handle it via `case .leftTwoThirds: return .left70_30` forwarding. |
| RISK-CRW-03 | Actor isolation of PreferencesStore may cause thread contention on the hot path (SnapEngine reads gap on every snap) | Low | Medium | Gap reads are trivial (single Double). Actor re-entrancy is fine. If contention appears, cache with `nonisolated` critical section. |

---

## 7. Acceptance Criteria Traceability

| AC (from Roadmap) | Requirement | Verified By |
| :---------------- | :---------- | :---------- |
| LayoutEngine computes 60/40, 70/30, 80/20, 3-column 25/50/25 | REQ-CRW-01 | T-TEST-01, T-TEST-02 |
| Window Gap 0/4/8/12/16 compensating inner AND outer edges | REQ-CRW-02 | T-TEST-01 (uniform section) |
| Persist gap + default ratio in PreferencesStore | REQ-CRW-03, REQ-CRW-04 | T-TEST-03 |
| Settings UI allows gap selection | REQ-CRW-05 | Manual verification + snapshot test |

---

## 8. Handover Brief

**For system-architect (Speckit pipeline):**
- Read `.specify/features/custom-ratios-window-gaps/00-tech-context.md` for tech stack.
- Key decisions: enum-based ratios (ASM-CRW-001), hybrid gap (ASM-CRW-002), actor PreferencesStore (ASM-CRW-003).
- `LayoutCalculating` protocol gains a `uniform` parameter — this is a **source-breaking change** for all conforming types. `LayoutEngine` is the only conformer, so blast radius is small.
- `PreferencesStore` becomes an actor — all call sites that read `windowGap` must be `await`-ed or use a `nonisolated` cached wrapper.
- `GeneralSettingsView` is a stub — must be replaced with real Picker bindings.
- `SnapEngine` must accept an optional `PreferencesStore` reference and fall back to its values when `gap` is nil.

**For backend-developer (TDD pipeline):**
- Implement in order: Domain (T-DOM-01, T-DOM-02) → Core (T-CORE-01, T-CORE-02) → Persistence (T-PERSIST-01, T-PERSIST-02) → UI (T-UI-01) → Tests (T-TEST-01, T-TEST-02, T-TEST-03).
- Follow TDD: Write tests first, then implement.
- Ensure `swiftlint lint --strict` passes.
- Ensure 100% mathematical coverage on LayoutEngine new ratio paths.

---

**SIGNED-OFF v1.0** — Approved for Speckit pipeline.