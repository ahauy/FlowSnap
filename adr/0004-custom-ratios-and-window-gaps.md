# ADR-0004: Support Custom Asymmetric Ratios and Configurable Window Gaps

- **Status:** Accepted
- **Date:** 2026-08-30
- **Deciders:** FlowSnap Architecture Council & Core Engineering
- **Technical context:** Modern ultra-wide and multi-monitor setups require flexible asymmetric window partitions (60/40, 70/30, 80/20, 25/50/25) and configurable window gaps (0, 4, 8, 12, 16 px) that inset both inner gutters and outer screen edges without pixel overflow or jitter under Swift 6 strict concurrency.

## Context

FlowSnap's foundational layout calculation engine (`US-SNAP-002`) originally provided 9 standard partition zones (halves, quarters, maximize) with zero-gap or inner-gutter-only geometry. While sufficient for standard laptop screens, this presented two significant limitations for power users:

1. **Lack of Asymmetric Workflow Splits**: Developers and knowledge workers frequently pair a primary wide window (editor, browser) with a secondary narrow window (terminal, reference docs, chat) using 60/40, 70/30, 80/20, or 25/50/25 splits.
2. **Missing Outer-Edge Window Gaps**: Tiling window management enthusiasts expect visual separation (padding) not only between adjacent windows but also along display screen boundaries (Dock/Menu Bar margins).
3. **Odd-Pixel Geometric Invariants**: When introducing gaps on displays with odd dimensions (e.g. $1441 \times 901$), the sum of all window widths plus gaps must strictly equal the display bounds ($W_1 + W_2 + 3 \times \text{gap} = W_{\text{total}}$) without 1px overlaps or rounding drift.
4. **Concurrency & State Decoupling**: Preferences for gap size and default layout ratios must be readable synchronously/asynchronously across background snapping pipelines ([`SnapEngine`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/SnapEngine.swift)) while seamlessly binding to SwiftUI settings views ([`GeneralSettingsView`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/UI/Settings/GeneralSettingsView.swift)) under Swift 6 strict concurrency.

## Decision

We chose to implement discrete enum-based asymmetric ratios and a hybrid uniform gap calculation coordinated by an actor-based preferences store:

1. **Discrete `LayoutZone` Enum Expansion & `LayoutRatio` Domain Model**:
   - Added 7 new discrete enum cases to [`LayoutZone`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Layout/LayoutZone.swift): `.left60_40`, `.right40_60`, `.left80_20`, `.right20_80`, `.left25`, `.center50`, `.right25`, and `.left70_30`.
   - Deprecated `LayoutZone.leftTwoThirds` with `@available(*, deprecated, renamed: "left70_30")` to unify ratio naming conventions while maintaining backward compatibility.
   - Introduced [`LayoutRatio`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Layout/LayoutRatio.swift) (`.equal`, `.sixtyForty`, `.seventyThirty`, `.eightyTwenty`, `.threeColumn25_50_25`) mapping deterministically to ordered `[LayoutZone]` arrays.

2. **Hybrid Gap Protocol & Flooring Math in `LayoutEngine`**:
   - Extended [`LayoutCalculating.frame(for:in:gap:uniform:)`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/LayoutCalculating.swift#L18-L23) with a `uniform: Bool = false` parameter.
   - When `uniform = true` (`BR-CRW-003`), the origin shifts inward by `gap` ($x_{\text{origin}} = x_0 + \text{gap}$), and effective width deducts both outer margins and inner gutters ($W_{\text{eff}} = W_{\text{total}} - 3 \times \text{gap}$ for 2 columns, $W_{\text{total}} - 4 \times \text{gap}$ for 3 columns).
   - Preserved `BR-LAYOUT-002` integer flooring ($\lfloor W_{\text{eff}} \times \text{ratio} \rfloor$) and allocated remainder to adjacent partitions, guaranteeing zero overflow.

3. **Observable Actor-Compatible `PreferencesStore`**:
   - Created [`PreferencesStore`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Infrastructure/Persistence/PreferencesStore.swift) (`@MainActor final class: ObservableObject`) encapsulating `UserDefaults` persistence with strict gap down-clamping to $\{0, 4, 8, 12, 16\}$ px (`BR-CRW-002`).
   - Registered `PreferencesStore` in [`AppDependencies`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/App/AppDependencies.swift) and injected into [`SnapEngine`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/SnapEngine.swift).

4. **Dynamic Gap Fallback in `SnapEngine`**:
   - `SnapEngine` methods accept `gap: CGFloat? = nil`. If `nil`, `SnapEngine` resolves `await preferencesStore.windowGap`, defaulting to `0` if unconfigured (`REQ-CRW-06`).

## Consequences

### Positive

- **Compile-Time Safety & Exhaustiveness**: Swift compiler guarantees all layout cases are handled in pattern matches without runtime validation overhead.
- **Pixel-Perfect Math**: Deterministic $O(1)$ calculations with zero memory allocations per frame computation.
- **Seamless UI Data Binding**: SwiftUI settings views reactively update and persist gap selections with instant visual feedback.
- **Zero Regression**: Existing call sites passing `gap = 0` or legacy parameters produce identical frames.

### Negative / Trade-offs

- **Fixed Ratio Set**: Arbitrary user-defined percentages (e.g. 63.5%) are not supported out of the box. This is an intentional product design decision to preserve hotkey simplicity and clean keyboard ergonomics.
- **Protocol Signature Expansion**: Required updating the single existing conformer ([`LayoutEngine`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/LayoutEngine.swift)) with the new `uniform` parameter.

### Alternatives considered

1. **Parameterized `LayoutZone.custom(ratio: CGFloat)`**:
   - _Why not_: Eliminates compile-time exhaustive `switch` safety, introduces runtime division-by-zero or out-of-bounds risks, and significantly complicates hotkey serialization and UI picker generation.
2. **Separate `frameWithUniformGap(...)` Protocol Method**:
   - _Why not_: Would duplicate layout switch statements across two parallel methods in `LayoutEngine`, increasing maintenance overhead and drift risk.
3. **Direct `@AppStorage` in SwiftUI Views without Central Store**:
   - _Why not_: Fails the architectural requirement that non-UI background components (such as [`SnapEngine`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/SnapEngine.swift) and global keyboard hotkey dispatchers) must query user gap preferences outside the SwiftUI view hierarchy.

## Related

- `CONTEXT.md` entries: `LayoutZone`, `LayoutEngine`, `SnapEngine`, `LayoutRatio`, `PreferencesStore`
- Feature folder: `.specify/features/custom-ratios-window-gaps/`
- Specifications: [baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/custom-ratios-window-gaps/baseline.md), [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/custom-ratios-window-gaps/spec.md), [plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/custom-ratios-window-gaps/plan.md)
