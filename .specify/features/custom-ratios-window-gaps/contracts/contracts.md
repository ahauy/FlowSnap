# API Contracts: Custom Ratios & Window Gaps (US-SNAP-008)

**Status:** v1.0
**Slug:** custom-ratios-window-gaps

---

## 1. Overview

This feature introduces no network API endpoints. All contracts are **internal
Swift protocol interfaces** and **public type signatures** along the
Domain → Core → Infrastructure → UI seam boundaries.

---

## 2. Protocol Contracts

### 2.1 LayoutCalculating (Core layer)

Location: `FlowSnap/Core/Layout/LayoutCalculating.swift`

```swift
/// Calculate concrete frame for a single standard layout zone on a display.
///
/// - Parameters:
///   - zone: The standard partition target.
///   - availableFrame: The display's visible frame (excluding menu bar/dock).
///   - gap: Pixel gap between windows.
///   - uniform: When true, gap is subtracted from BOTH outer edges
///              (effectiveWidth = totalWidth - 2*gap). Default false (legacy inner-only).
/// - Returns: Concrete pixel frame within availableFrame.
func frame(
    for zone: LayoutZone,
    in availableFrame: CGRect,
    gap: CGFloat,
    uniform: Bool   // NEW PARAMETER
) -> CGRect
```

**Backward compatibility:** The old signature `frame(for:in:gap:)` is removed
(replaced by the new one with `uniform` defaulting to `false`). All existing
call sites passing `gap: 0` produce identical results.

### 2.2 LayoutCalculating (aggregate frames — unchanged)

```swift
func frames(
    for windows: [ManagedWindow],
    in availableFrame: CGRect,
    layout: Layout,
    gap: CGFloat
) -> [CGWindowID: CGRect]
```

No signature change. The `gap` parameter is forwarded to the single-zone
`frame` calls internally.

---

## 3. Type Contracts

### 3.1 LayoutZone (Domain)

Exposed types: `LayoutZone` enum cases (CGFloat-returning `normalizedRect`).

New cases and their `normalizedRect`:

| Zone | normalizedRect |
| :--- | :------------- |
| `.left60_40` | `CGRect(x: 0, y: 0, width: 0.6, height: 1.0)` |
| `.right40_60` | `CGRect(x: 0.6, y: 0, width: 0.4, height: 1.0)` |
| `.left80_20` | `CGRect(x: 0, y: 0, width: 0.8, height: 1.0)` |
| `.right20_80` | `CGRect(x: 0.8, y: 0, width: 0.2, height: 1.0)` |
| `.left25` | `CGRect(x: 0, y: 0, width: 0.25, height: 1.0)` |
| `.center50` | `CGRect(x: 0.25, y: 0, width: 0.5, height: 1.0)` |
| `.right25` | `CGRect(x: 0.75, y: 0, width: 0.25, height: 1.0)` |
| `.left70_30` | `CGRect(x: 0, y: 0, width: 0.7, height: 1.0)` |

Deprecated (preserved but marked):

| Zone | Alias to |
| :--- | :------- |
| `.leftTwoThirds` | `.left70_30` |

### 3.2 LayoutRatio (NEW — Domain)

```swift
public enum LayoutRatio: String, CaseIterable, Sendable, Codable, Hashable {
    case equal
    case sixtyForty
    case seventyThirty
    case eightyTwenty
    case threeColumn25_50_25

    /// Returns the LayoutZone sequence for this ratio.
    /// - gap: pixel gap for inner spacing (only relevant for 3-column).
    var zones: [LayoutZone] { get }
}
```

`zones` mapping:

| Ratio | Zones |
| :---- | :---- |
| `.equal` | `[.leftHalf, .rightHalf]` |
| `.sixtyForty` | `[.left60_40, .right40_60]` |
| `.seventyThirty` | `[.left70_30, .rightOneThird]` |
| `.eightyTwenty` | `[.left80_20, .right20_80]` |
| `.threeColumn25_50_25` | `[.left25, .center50, .right25]` |

---

## 4. PreferencesStore Contract (Infrastructure)

### 4.1 Public Interface

```swift
actor PreferencesStore: ObservableObject {
    /// Published on MainActor for SwiftUI bindings.
    @MainActor @Published private(set) var windowGap: CGFloat
    @MainActor @Published private(set) var defaultRatio: LayoutRatio

    init(defaults: UserDefaults)

    /// Set gap with clamping to {0, 4, 8, 12, 16}.
    func setWindowGap(_ newValue: CGFloat) async

    /// Set default ratio with validation.
    func setDefaultRatio(_ newValue: LayoutRatio) async
}
```

### 4.2 Clamping Contract

`setWindowGap` implements:

```
let clamped = {0, 4, 8, 12, 16}.last(where: { $0 <= newValue }) ?? 0
```

### 4.3 Default Ratio Contract

- On first launch (no stored key) → `.equal`.
- On decoding failure (corrupted value) → `.equal`.

---

## 5. SnapEngine Contract (Core)

### 5.1 Constructor

```swift
public init(
    layoutEngine: LayoutCalculating = LayoutEngine(),
    windowRegistry: WindowRegistry,
    displayManager: (any DisplayManaging)? = nil,
    preferencesStore: PreferencesStore? = nil  // NEW PARAMETER
)
```

### 5.2 Fallback Contract

All `gap` parameters in `SnapEngine` methods become `CGFloat?`:

```swift
func calculateFrame(
    for target: SnapTarget,
    window: ManagedWindow,
    availableFrame: CGRect,
    gap: CGFloat? = nil    // CHANGED: optional
) async -> CGRect?
```

When `gap` is `nil`:
1. If `preferencesStore` is non-nil → `await preferencesStore.windowGap`.
2. If `preferencesStore` is nil → `0` (legacy default).

---

## 6. Validation Boundary

| Boundary | Validation | Action |
| :------- | :--------- | :----- |
| PreferencesStore.setWindowGap | Clamp to {0,4,8,12,16} | Down-clamp |
| PreferencesStore.init (decode) | Ratio validity | Fallback to `.equal` |
| LayoutEngine.frame (gap) | `max(0, gap)` | Clamp negative |
| LayoutEngine.frame (uniform gap) | `max(0, totalWidth - 2*gap)` | Non-negative width |

---

## 7. Versioning

- No API versioning needed — all changes are internal Swift module boundaries.
- If a future network API is introduced for remote snap configuration, contract
  versioning would be added at that time.

---