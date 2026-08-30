# Task Breakdown: Custom Ratios & Window Gaps (US-SNAP-008)

**Status:** v1.0
**Slug:** custom-ratios-window-gaps
**Convention:** `[P]` = parallelizable, `[S]` = sequential (blocking).
Each task declares its exact target file path(s).

---

## Phase 1 — Domain & Contracts (Types first)

### T-DOM-01 — Extend LayoutZone with new ratio cases `[S]`
- **File:** `FlowSnap/Domain/Layout/LayoutZone.swift`
- **Change:** Add `left60_40`, `right40_60`, `left80_20`, `right20_80`,
  `left25`, `center50`, `right25`, `left70_30` cases with `normalizedRect`
  values per contracts.md §3.1.
- **Accept:** `normalizedRect` values exact; enum conformances intact; compile clean.

### T-DOM-02 — Create LayoutRatio enum `[S]`
- **File:** `FlowSnap/Domain/Layout/LayoutRatio.swift` (NEW)
- **Change:** `enum LayoutRatio: String, CaseIterable, Sendable, Codable, Hashable`
  with cases `.equal`, `.sixtyForty`, `.seventyThirty`, `.eightyTwenty`,
  `.threeColumn25_50_25`; provide `zones: [LayoutZone]` mapping per contracts.md §3.2.
- **Accept:** Raw values stable for persistence; mapping correct; ~15 LOC.

### T-DOM-03 — Deprecate leftTwoThirds alias `[S]`
- **File:** `FlowSnap/Domain/Layout/LayoutZone.swift`
- **Change:** Mark `.leftTwoThirds` with
  `@available(*, deprecated, renamed: "left70_30")`. Keep `normalizedRect`
  value (0.7) unchanged. Forward any switch over deprecated value.
- **Accept:** `swift build` emits no unexpected warnings; behavior unchanged.

---

## Phase 2 — Core Logic, Persistence & Wiring

### T-CORE-01 — Add uniform param to LayoutCalculating `[P]`
- **File:** `FlowSnap/Core/Layout/LayoutCalculating.swift`
- **Change:** Add `uniform: Bool = false` parameter to
  `frame(for:in:gap:uniform:)`. Update doc comment.
- **Accept:** Protocol compiles; `LayoutEngine` conforms.

### T-CORE-02 — Implement new ratio + uniform gap math in LayoutEngine `[S]`
- **File:** `FlowSnap/Core/Layout/LayoutEngine.swift`
- **Change:**
  - When `uniform == true`: `effectiveWidth = max(0, totalWidth - 2*gap)`,
    `effectiveOriginX = originX + gap` (BR-CRW-003).
  - Compute 60/40, 80/20, and 3-column 25/50/25 frames; re-use floor policy.
  - Refactor three-column math so `left25/center50/right25` uses gap correctly.
- **Accept:** All 4 invariant categories hold; legacy gap=0 identical;
  `left.width + right.width + gap == bounds.width` for uniform tests.

### T-PERSIST-01 — Convert PreferencesStore to actor `[S]`
- **File:** `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift`
- **Change:**
  - `actor PreferencesStore: ObservableObject`.
  - `@MainActor @Published private(set) var windowGap: CGFloat` clamped to
    `{0,4,8,12,16}`, default 4.
  - `@MainActor @Published private(set) var defaultRatio: LayoutRatio`, default `.equal`.
  - `func setWindowGap(_:) async` with clamp; `func setDefaultRatio(_:) async`.
  - Keep `defaults` storage; defensive clamp on read.
- **Accept:** Actor isolation valid; clamp contract (contracts.md §4.2).

### T-CORE-03 — Wire PreferencesStore into SnapEngine `[S]`
- **File:** `FlowSnap/Core/Layout/SnapEngine.swift`
- **Change:**
  - Add `preferencesStore: PreferencesStore? = nil` init param.
  - Change `gap` params to `CGFloat? = nil` on `calculateFrame`, `frame`,
    `calculateAXFrame` (both overloads), `calculateFrameOnNextDisplay`.
  - Resolve: `gap ?? await preferencesStore?.windowGap ?? 0`.
- **Accept:** Fallback contract (contracts.md §5.2); legacy nil→0 preserved.

### T-PERSIST-02 — Register PreferencesStore in AppDependencies `[S]`
- **File:** `FlowSnap/App/AppDependencies.swift`
- **Change:**
  - Add `public lazy var preferencesStore: PreferencesStore = PreferencesStore()`.
  - Pass into `SnapEngine(preferencesStore:)` and `GeneralSettingsView`/view model.
- **Accept:** DI container builds; `@MainActor` isolation holds.

---

## Phase 3 — UI

### T-UI-01 — Gap & ratio pickers in GeneralSettingsView `[S]`
- **File:** `FlowSnap/UI/Settings/GeneralSettingsView.swift`
- **Change:**
  - Replace stub with gap Picker over `{0,4,8,12,16}` px + visual 2-column
    preview; bind to `PreferencesStore.windowGap` (async set).
  - Ratio Picker over `LayoutRatio.allCases` bound to `defaultRatio`.
  - Persist immediately on change.
- **Accept:** UI compiles; settings persist; preview updates live.

---

## Phase 4 — Tests & Verification

### T-TEST-01 — New ratio + uniform gap tests `[S]`
- **File:** `FlowSnapTests/Core/LayoutEngineTests.swift`
- **Change:** Add `@Test` cases for 60/40, 80/20, 25/50/25; uniform gap
  invariant `left.width + right.width + gap == bounds.width`; keep legacy
  gap=0 cases unchanged.
- **Accept:** 100% mathematical coverage of new ratio paths.

### T-TEST-02 — Odd-pixel tests for new ratios `[P]`
- **File:** `FlowSnapTests/Core/LayoutEngineOddPixelTests.swift`
- **Change:** Add odd-pixel cases (e.g. width 767, gap 4) for new ratios;
  re-express invariants for gap>0 path.
- **Accept:** Flooring policy holds; no negative widths.

### T-TEST-03 — PreferencesStore actor tests `[S]`
- **File:** `FlowSnapTests/Infrastructure/PreferencesStoreTests.swift` (NEW)
- **Change:** Test gap clamping {0,4,8,12,16}; default ratio persistence;
  first-launch defaults; actor isolation (async writes).
- **Accept:** All clamp/persistence cases pass under Swift Testing.

### T-TEST-04 — SnapEngine fallback test `[S]`
- **File:** `FlowSnapTests/Core/SnapEngineTests.swift` (or existing SnapEngine test file)
- **Change:** Verify gap=nil falls back to `preferencesStore.windowGap`;
  nil store → 0.
- **Accept:** Fallback contract verified.

### T-QA-01 — Full quality gate `[S]`
- **Files:** all touched files
- **Change:** Run `swift build` (zero warnings), `swiftlint lint --strict`,
  full test suite; verify legacy gap=0 regression; verify ADR-003 sign-off.
- **Accept:** All NFR-CRW-01..06 met; checklist §8 fully checked.

---

## Dependency Graph

```
T-DOM-01 ──► T-DOM-02 ──► T-DOM-03
T-CORE-01 (P, parallel with T-DOM-03)
T-CORE-02 ── (needs T-DOM-01)
T-PERSIST-01 ── (needs T-DOM-02)
T-CORE-03 ── (needs T-CORE-02, T-PERSIST-01)
T-PERSIST-02 ── (needs T-PERSIST-01, T-CORE-03)
T-UI-01 ── (needs T-PERSIST-02)
T-TEST-01 ── (needs T-CORE-02)
T-TEST-02 (P with T-TEST-01, needs T-CORE-02)
T-TEST-03 ── (needs T-PERSIST-01)
T-TEST-04 ── (needs T-CORE-03)
T-QA-01 ── (needs all)
```

Suggested execution order:
T-DOM-01 → T-DOM-02 → [T-DOM-03 ∥ T-CORE-01] → T-CORE-02 → T-PERSIST-01 →
T-CORE-03 → T-PERSIST-02 → T-UI-01 → [T-TEST-01 ∥ T-TEST-02] → T-TEST-03 →
T-TEST-04 → T-QA-01.

---