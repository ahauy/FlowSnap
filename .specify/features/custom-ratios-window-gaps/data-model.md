# Data Model: Custom Ratios & Window Gaps (US-SNAP-008)

**Status:** v1.0
**Slug:** custom-ratios-window-gaps

---

## 1. Domain Entities

### 1.1 LayoutZone (existing — extended)

Location: `FlowSnap/Domain/Layout/LayoutZone.swift`

New cases added (ASM-CRW-001):

| Case | normalizedRect | Semantics |
| :--- | :------------- | :-------- |
| `left60_40` | x:0, w:0.6 | 60% left column |
| `right40_60` | x:0.6, w:0.4 | 40% left-remaining right column |
| `left80_20` | x:0, w:0.8 | 80% left column |
| `right20_80` | x:0.8, w:0.2 | 20% right column |
| `left25` | x:0, w:0.25 | left 25% of 3-column |
| `center50` | x:0.25, w:0.5 | center 50% of 3-column |
| `right25` | x:0.75, w:0.25 | right 25% of 3-column |
| `left70_30` | x:0, w:0.7 | new canonical 70/30 case |

Deprecated alias: `leftTwoThirds` (normalizedRect 0.7 unchanged, marked
`@available(*, deprecated, renamed: "left70_30")`).

Note: The enum is `String, CaseIterable, Sendable, Codable, Hashable` — new
cases automatically inherit all conformances. **No migration required** because
the enum raw values persist in UserDefaults; a rename of raw value must be
avoided (keep existing raw strings stable).

### 1.2 LayoutRatio (NEW)

Location: `FlowSnap/Domain/Layout/LayoutRatio.swift` (new file, ~15 LOC)

| Case | Raw value | Meaning |
| :--- | :-------- | :------ |
| `.equal` | `"equal"` | 50/50 |
| `.sixtyForty` | `"sixtyForty"` | 60/40 |
| `.seventyThirty` | `"seventyThirty"` | 70/30 |
| `.eightyTwenty` | `"eightyTwenty"` | 80/20 |
| `.threeColumn25_50_25` | `"threeColumn25_50_25"` | 25/50/25 |

Conformance: `String, CaseIterable, Sendable, Codable, Hashable`.
Provides `var zones: [LayoutZone]` mapping to zone sequences for layout building.
Default = `.equal`.

---

## 2. Persistence Schema

Storage backend: **UserDefaults** (existing MVP mechanism, no DB).

### 2.1 Keys

| Key | Type stored | Owner | Default |
| :-- | :---------- | :---- | :------ |
| `"windowGap"` | Double | PreferencesStore | 4.0 |
| `"defaultRatio"` | String (raw value) | PreferencesStore | "equal" |

### 2.2 Migration Strategy

- No schema version bump required — additive keys only.
- Existing installations with no `"defaultRatio"` key fall back to `.equal`.
- Existing `"windowGap"` values outside {0,4,8,12,16} are clamped on read
  (BR-CRW-002), guaranteeing non-negative consistent state.
- Rollback: removing the two keys returns behavior to defaults; no data loss risk.

### 2.3 Seeding

- No explicit seeding phase; defaults resolved lazily on first read
  (`PreferencesStore` actor init / property accessor).

---

## 3. Concurrency Model

### 3.1 PreferencesStore (actor)

```
actor PreferencesStore: ObservableObject {
    @MainActor @Published private(set) var windowGap: CGFloat
    @MainActor @Published private(set) var defaultRatio: LayoutRatio
}
```

- State is isolated; published wrappers are MainActor for SwiftUI binding.
- `setWindowGap(_:)` / `setDefaultRatio(_:)` async methods clamp + persist.
- `nonisolated` cached snapshot for hot-path reads (optional per RISK-CRW-03).

### 3.2 Invariants

- `windowGap ∈ {0, 4, 8, 12, 16}` (post-clamp).
- `defaultRatio` always one of the 5 enumerated cases (decoding failure → `.equal`).

---

## 4. Indexing & Queries

- UserDefaults is a single flat key-value store; no indexes required.
- Access pattern: one Double read per snap (hot), one String read per settings open (cold).
- No unbounded collections — N/A for pagination.

---

## 5. Seam & Dependency Injection

| Dependency | Injected into | Via |
| :--------- | :------------ | :-- |
| `PreferencesStore` (actor) | `SnapEngine` | init param (optional, default nil) |
| `PreferencesStore` (actor) | `GeneralSettingsView` | environment object / view model |
| `PreferencesStore` (actor) | `AppDependencies` | @MainActor lazy var |

---

## 6. Files Touched Summary

| File | Change |
| :--- | :----- |
| `FlowSnap/Domain/Layout/LayoutZone.swift` | +8 cases, +1 deprecation annotation |
| `FlowSnap/Domain/Layout/LayoutRatio.swift` | NEW file |
| `FlowSnap/Core/Layout/LayoutCalculating.swift` | +`uniform` param |
| `FlowSnap/Core/Layout/LayoutEngine.swift` | new ratio math + uniform gap |
| `FlowSnap/Infrastructure/Persistence/PreferencesStore.swift` | actor conversion |
| `FlowSnap/App/AppDependencies.swift` | DI registration |
| `FlowSnap/UI/Settings/GeneralSettingsView.swift` | gap Picker |
| `FlowSnapTests/Core/LayoutEngineTests.swift` | new tests |
| `FlowSnapTests/Core/LayoutEngineOddPixelTests.swift` | new tests |
| `FlowSnapTests/Infrastructure/PreferencesStoreTests.swift` | NEW test file |

---
