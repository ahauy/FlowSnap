# Architecture Plan: Custom Ratios & Window Gaps (US-SNAP-008)

**Status:** v1.0
**Slug:** custom-ratios-window-gaps

---

## 1. Component Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        App Layer                                 │
│  ┌──────────────────┐   ┌────────────────────────────────────┐  │
│  │ AppDependencies  │   │  GeneralSettingsView               │  │
│  │  @MainActor DI   │   │  ┌──────────────┐ ┌─────────────┐ │  │
│  │  Container       │───│→│ Gap Picker   │ │ Ratio Picker│ │  │
│  │                  │   │  └──────┬───────┘ └──────┬──────┘ │  │
│  └──────────────────┘   └─────────┼─────────────────┼────────┘  │
└───────────────────────────────────┼─────────────────┼────────────┘
                                    │                 │
                    ┌────────────────▼─────────────────▼──────────┐
                    │          Infrastructure Layer                │
                    │  ┌──────────────────────────────────────┐   │
                    │  │  PreferencesStore (actor)            │   │
                    │  │  @Published windowGap: CGFloat       │   │
                    │  │  @Published defaultRatio: LayoutRatio│   │
                    │  │  setWindowGap(_:) → clamp + persist  │   │
                    │  │  setDefaultRatio(_:) → persist        │   │
                    │  └──────────────────┬───────────────────┘   │
                    └─────────────────────┼───────────────────────┘
                                          │
                    ┌──────────────────────▼──────────────────────┐
                    │            Core Layer                        │
                    │  ┌────────────────────────────────────────┐  │
                    │  │  SnapEngine (Sendable)                 │  │
                    │  │  ┌────────────────────────────────┐    │  │
                    │  │  │ calculateFrame(target:gap:nil) │    │  │
                    │  │  │  → gap = preferencesStore?     │    │  │
                    │  │  │    ?? 0 (fallback)             │    │  │
                    │  │  └───────────────┬────────────────┘    │  │
                    │  └──────────────────┼─────────────────────┘  │
                    │                     │                        │
                    │  ┌──────────────────▼─────────────────────┐  │
                    │  │  LayoutEngine (LayoutCalculating)      │  │
                    │  │  frame(for:in:gap:uniform:) → CGRect   │  │
                    │  │  ┌────────────────────────────────┐    │  │
                    │  │  │ 60/40, 80/20, 25/50/25 math   │    │  │
                    │  │  │ uniform gap→effectiveWidth     │    │  │
                    │  │  │ flooring policy per zone       │    │  │
                    │  │  └────────────────────────────────┘    │  │
                    │  └────────────────────────────────────────┘  │
                    └──────────────────────────────────────────────┘
                                     │
                    ┌────────────────▼──────────────────────────────┐
                    │          Domain Layer                        │
                    │  ┌────────────────────┐ ┌──────────────────┐ │
                    │  │ LayoutZone (enum)  │ │ LayoutRatio (NEW)│ │
                    │  │ +8 new cases       │ │ Codable, Sendable│ │
                    │  │ deprecation alias  │ │ zones mapping    │ │
                    │  └────────────────────┘ └──────────────────┘ │
                    └──────────────────────────────────────────────┘
```

---

## 2. Data Flow

### 2.1 Snap Flow (gap read path)

```
User Action (hotkey)
    │
    ▼
SnapEngine.calculateFrame(for:target, gap: nil)
    │
    ├── preferencesStore != nil? ──yes──▶ await preferencesStore.windowGap
    │                                       │
    │  no                                   │ (clamped {0,4,8,12,16})
    │                                       ▼
    └───────────────────────────────▶ gap = 0 (legacy fallback)
                                        │
                                        ▼
                                 LayoutEngine.frame(for:zone, in:availableFrame, gap:gap, uniform:true)
                                        │
                                        ▼
                                 applyMinSizeAnchoring(frame, ...)
                                        │
                                        ▼
                                 return CGRect?
```

### 2.2 Settings Flow

```
User selects gap in Picker
    │
    ▼
GeneralSettingsView
    │
    ▼
PreferencesStore.setWindowGap(12)
    │
    ├── clamp to {0,4,8,12,16}
    │
    ▼
UserDefaults.set(Double(12), forKey: "windowGap")
    │
    ▼
@MainActor @Published var windowGap = 12
    │
    ▼
SwiftUI view re-renders (gap preview updates)
```

---

## 3. Architecture Decision Records

### ADR-001: Enum-Based Zone Cases vs. Parameterized Ratio

**Status:** Accepted

**Context:** Need to support 60/40, 80/20, 25/50/25 ratios. Two approaches:
add new enum cases (ASM-CRW-001) or make `LayoutZone` parameterized with a
ratio value.

**Decision:** Add fixed enum cases. Swift enums are exhaustive, pattern-matchable,
and `CaseIterable` for UI pickers. A parameterized `LayoutZone(ratio: 0.6)`
would lose exhaustiveness guarantees and complicate normalizedRect computation.

**Consequences:**
- Positive: Exhaustive switch by compiler; no runtime validation of ratio values.
- Negative: More cases; but still < 20 cases total, well within maintainable range.
- Alternative considered: Parameterized `indirect` enum — rejected due to
  added complexity and loss of static guarantees.

### ADR-002: Actor PreferencesStore with @Published on MainActor

**Status:** Accepted

**Context:** `PreferencesStore` must be accessible from both SwiftUI views
(requires `ObservableObject`) and the hot-path `SnapEngine` (performance-sensitive
reads). Swift 6 strict concurrency forces actor isolation.

**Decision:** Declare `PreferencesStore` as an `actor`, expose `@Published`
properties via `@MainActor` wrapper. This gives SwiftUI a valid `ObservableObject`
conformance (actor on MainActor) while isolating the internal state.

**Consequences:**
- Positive: Clear thread safety; SwiftUI binding works.
- Negative: Hot-path read requires `await` or `nonisolated` cached snapshot.
- Mitigation: If profiling shows contention, cache a `nonisolated` let value
  updated on write.

### ADR-003: uniform Parameter on LayoutCalculating vs. Separate Method

**Status:** Proposed (awaiting sign-off)

**Context:** The gap semantics change (BR-CRW-002) introduces uniform outer-edge
gap. Should this be a new method (`frameWithUniformGap`) or a parameter on the
existing method?

**Decision:** Add a `uniform: Bool` parameter with default `false`. This is a
source-breaking change but only one conformer exists (`LayoutEngine`). A
separate method would duplicate the switch statement and increase maintenance
surface.

**Consequences:**
- Positive: Single overridable method; internal branching is in one place.
- Negative: Callers with gap>0 may inadvertently use inner-only mode by
  forgetting `uniform: true`. Mitigated by `SnapEngine` always passing
  `uniform: true` for gap>0 scenarios.

## 4. Seam Boundaries

| Seam | Interface | Implementer | Consumer |
| :--- | :-------- | :---------- | :------- |
| Layout calculation | `LayoutCalculating` | `LayoutEngine` | `SnapEngine` |
| Preferences | `PreferencesStore` (actor) | concrete actor | `SnapEngine`, `GeneralSettingsView` |
| Zone definition | `LayoutZone` (enum) | — | `LayoutEngine`, `SnapEngine`, UI |

---

## 5. Risk Register

| RISK-ID | Description | Likelihood | Impact | Mitigation |
| :------ | :---------- | :--------- | :----- | :--------- |
| RISK-CRW-01 | Test invariants break with uniform gap | High | Medium | Re-express as `left.width + right.width + gap == bounds.width` in uniform tests |
| RISK-CRW-02 | Deprecation warnings in all switch statements | Medium | Low | Handle via `case .leftTwoThirds: return .left70_30` forwarding |
| RISK-CRW-03 | Actor contention on hot snap path | Low | Medium | Cache nonisolated snapshot; profile before optimizing |

---