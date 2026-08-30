# AS-IS Inventory: custom-ratios-window-gaps (light Stage 3 substitute)

Generated inline by the orchestrator after the `business-analyst` dispatch exhausted its tool-call
budget without producing artifacts (two-strike fallback). Every claim below was read from source.

## 1. Ratio zones that ALREADY exist

`FlowSnap/Domain/Layout/LayoutZone.swift` (enum, `String` raw, `CaseIterable`, `Codable`, `Sendable`, `Hashable`):

| Zone                                   | normalizedRect                     | Added in |
| :------------------------------------- | :--------------------------------- | :------- |
| leftHalf / rightHalf                   | 0.5 / 0.5                          | US-SNAP-002 |
| topHalf / bottomHalf                   | 0.5 height                         | US-SNAP-002 |
| topLeft / topRight / bottomLeft / bottomRight | 0.5 x 0.5                   | US-SNAP-002 |
| maximize                               | 1.0 x 1.0                          | US-SNAP-002 |
| leftTwoThirds (0.7) / rightOneThird (0.3) | 70/30                           | US-SNAP-007 |
| leftThird / centerThird / rightThird   | 1/3 each                           | US-SNAP-007 |

Missing vs US-SNAP-008 AC: **60/40**, **80/20**, and **3-column 25/50/25** (the existing 3-column is equal 1/3, not 25/50/25).

Naming note: `leftTwoThirds` is a misnomer already shipped - it means 70%, not 2/3. Any new ratio
modelling must decide whether to keep, deprecate-alias, or rename it (CONTEXT.md rule 5: never delete
a term in use; mark `deprecated -> alias`).

## 2. How `gap` is modelled TODAY

`LayoutCalculating` protocol (`FlowSnap/Core/Layout/LayoutCalculating.swift`):

```
func frame(for zone: LayoutZone, in availableFrame: CGRect, gap: CGFloat) -> CGRect
func frames(for windows: [ManagedWindow], in availableFrame: CGRect, layout: Layout, gap: CGFloat) -> [CGWindowID: CGRect]
```

`LayoutEngine.frame(for:in:gap:)` current algorithm (`FlowSnap/Core/Layout/LayoutEngine.swift:23-90`):

- `safeGap = max(0, gap)`
- `effectiveWidth  = totalWidth  - safeGap`   (ONE gap, not two)
- `effectiveHeight = totalHeight - safeGap`
- `threeColEffectiveWidth = totalWidth - 2 * safeGap`
- left partition width = `floor(effectiveWidth / 2)`, right = remainder; right origin = `originX + leftWidth + safeGap`
- top partition height = `floor(effectiveHeight / 2)`, bottom = remainder; top origin = `originY + bottomHeight + safeGap`
- 70/30: `floor(effectiveWidth * 0.7)` / remainder
- 3-col equal: `floor(w/3)`, `floor((w-c1)/2)`, remainder; offsets `+safeGap`, `+2*safeGap`
- `maximize` returns the FULL `availableFrame` - gap is ignored entirely.

Consequence (the real defect this story must resolve): **only one inner gutter is reserved, and the
outer screen-edge padding is never applied.** With gap = 8 on a 1440x900 screen, `leftHalf` yields
`CGRect(x: 0, y: 0, width: 716, height: 892)` - the window still touches the left screen edge and the
Dock/menu-bar boundary, while the right half is inset by 8 from the right edge only. So the current
model is "half-gap, asymmetric", not "uniform gap". Any change here is a **behavioural contract change**
for already-shipped zones and needs a regression decision (see Q2).

## 3. Call sites that hard-code `gap: 0` or omit gap

| Site | File:line | Current |
| :--- | :-------- | :------ |
| `SnapEngine.calculateFrame` default param | Core/Layout/SnapEngine.swift:37 | `gap: CGFloat = 0` |
| `SnapEngine.frame(...)` | SnapEngine.swift:62 | default 0 |
| `SnapEngine.calculateAXFrame` (x2) | SnapEngine.swift:75, 89 | default 0 |
| `SnapEngine.calculateFrameOnNextDisplay` | SnapEngine.swift:114 | default 0 |
| `CommandDispatcher.executeSnap` | Core/Commands/CommandDispatcher.swift:~127 | **never passes gap** |
| `CommandDispatcher.executeMoveToDisplay` | same file | never passes gap |
| `DragToSnapCoordinator` preview (picker slot) | Core/Layout/DragToSnapCoordinator.swift:106 | `gap: 0` literal |
| `DragToSnapCoordinator` release snap | DragToSnapCoordinator.swift:199 | `gap: 0` literal |
| `SnapDetector.detectZone` preview | Core/Layout/SnapDetector.swift:~96 | calls `frame(for:in:)` (no gap arg at all) |
| `SnapLayoutPickerView` card drawing | UI/LayoutPicker/SnapLayoutPickerView.swift:88 | `gap: 2` - purely cosmetic card padding, unrelated to window gap |

So even if a gap preference existed, **no runtime path would consume it today**.

## 4. Persistence AS-IS

`FlowSnap/Infrastructure/Persistence/PreferencesStore.swift` (whole file, 24 lines):

- `final class PreferencesStore` - **not** `Sendable`, **not** an actor, internal access level (no `public`).
- Single key: `windowGap: CGFloat` backed by `defaults.double(forKey: "windowGap")`.
- Bug: unset key returns `0.0`, so there is no distinguishable "never configured" state and no default
  other than 0. Also `CGFloat` is not directly storable - it is bridged via `Double`, fine, but the
  getter has no clamping to the allowed set {0,4,8,12,16}.
- `PreferencesStore` is **not registered in `AppDependencies`** and is referenced by zero other files
  (verified by grep). It is dead code today.
- Remaining TODOs in file: launch-at-login, per-app policies, custom shortcuts (belong to US-SNAP-010).

`FlowSnap/UI/Settings/GeneralSettingsView.swift` is a stub: `Form { Text("General Settings") }` with a
`// TODO: Window gap slider (spec §18)`.

## 5. Test AS-IS

- `FlowSnapTests/Core/LayoutEngineTests.swift` - TC-001/002/004/005, all with default gap.
- `FlowSnapTests/Core/LayoutEngineOddPixelTests.swift` - BR-LAYOUT-002 flooring invariants
  (`left.width + right.width == bounds.width`, `right.maxX == bounds.width`). **These invariants break
  by design once outer-edge gap is introduced** -> must be re-expressed as
  `left.width + right.width + gap == effectiveWidth` style, or the legacy zero-gap path must be pinned.
- No test anywhere asserts `gap > 0` behaviour (grep for `gap` in FlowSnapTests returns only
  `gap: 0` in DragToSnapCoordinatorTests and a comment).
- `FlowSnapTests` has no `PreferencesStore` test file.

## 6. Build wiring constraint

`project.yml` `FlowSnapLab` target compiles `FlowSnap/Domain`, `FlowSnap/Core`, `FlowSnap/Infrastructure`,
`FlowSnap/UI/SnapPreview`, `FlowSnap/UI/MenuBar`, `FlowSnap/UI/LayoutPicker` - i.e. **not** `FlowSnap/UI/Settings`.
Anything the Lab must exercise therefore has to live in Domain/Core/Infrastructure. `PreferencesStore`
is currently internal to the `FlowSnap` module and invisible to `FlowSnapTests` unless `@testable import`
is used (tests do use `@testable import FlowSnap`, so internal is reachable).

## 7. Gap between AS-IS and US-SNAP-008 AC

| AC | Status | Work needed |
| :--| :----- | :----------- |
| Ratios 60/40, 70/30, 80/20, 3-col 25/50/25 | 70/30 + equal-thirds exist; rest missing | Ratio modelling decision (Q1) |
| Gap 0/4/8/12/16 compensating inner AND outer edges | Only one inner gutter, no outer padding | Redesign `LayoutEngine` gap math (Q2) |
| Persist gap + default ratio in `PreferencesStore` | Key exists but dead, no default, no clamping, not wired | Make store observable + wire into DI + consume at call sites (Q3) |
