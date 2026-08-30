# Quality & Requirements Checklist: Custom Ratios & Window Gaps (US-SNAP-008)

**Status:** v1.0
**Slug:** custom-ratios-window-gaps

Legend: [ ] = to do, [x] = done, [~] = partial / verify.

---

## 1. Functional Requirements Traceability

```
[ ] REQ-CRW-01  LayoutEngine computes frames for left60_40 / right40_60,
                left80_20 / right20_80, left25 / center50 / right25.
[ ] REQ-CRW-02  LayoutCalculating.frame(for:in:gap:uniform:) supports
                uniform=true → effectiveWidth = max(0, totalWidth - 2*gap),
                origin shift by gap; false → legacy inner-only.
[ ] REQ-CRW-03  PreferencesStore is an actor; publishes windowGap (clamped
                {0,4,8,12,16}) and defaultRatio (LayoutRatio enum);
                ObservableObject conformance.
[ ] REQ-CRW-04  PreferencesStore registered in AppDependencies; wired into
                SnapEngine constructor and GeneralSettingsView.
[ ] REQ-CRW-05  GeneralSettingsView gap Picker {0,4,8,12,16} with visual
                preview; persists immediately.
[ ] REQ-CRW-06  All SnapEngine methods fall back to PreferencesStore.windowGap
                when gap is nil.
[ ] REQ-CRW-07  leftTwoThirds deprecated alias → left70_30 via @available.
```

---

## 2. Architecture Compliance

```
[ ] DDD layering respected: Domain → Core → Infrastructure → UI → App.
[ ] Deep modules: LayoutEngine hides gap math behind LayoutCalculating.
[ ] Seam discipline: LayoutCalculating is the only seam for LayoutEngine;
    PreferencesStore exposes a minimal actor interface.
[ ] UI never imports Core internal implementations; goes through
    PreferencesStore (actor) bindings.
[ ] Feature-based cohesion: LayoutRatio in Domain/Layout alongside LayoutZone.
[ ] No force unwrap / try! / as! introduced.
```

---

## 3. Data Model & Persistence

```
[ ] New keys windowGap (Double) + defaultRatio (String raw) in UserDefaults.
[ ] No schema migration required (additive keys only).
[ ] Gap clamp {0,4,8,12,16} applied on both write (setWindowGap) and
    defensively on read.
[ ] DefaultRatio decode failure → .equal fallback.
[ ] First-launch defaults: gap=4, ratio=.equal.
```

---

## 4. Error Handling Completeness

```
[ ] EC-CRW-01  gap > totalWidth/2 → effectiveWidth clamps to 0 (no negatives).
[ ] EC-CRW-02  Out-of-set gap clamped down to nearest valid value.
[ ] EC-CRW-04  minSize anchoring respected when gap-trimmed width < minSize.
[ ] EC-CRW-06  Deprecated leftTwoThirds still resolves to 0.7-width frame.
[ ] EC-CRW-08  Actor contention on hot path: documented mitigation
    (nonisolated cache) available.
```

---

## 5. Non-Functional Requirements

```
[ ] NFR-CRW-01  frame() is O(1); no allocation beyond single CGRect.
[ ] NFR-CRW-02  Swift 6 strict concurrency: zero warnings.
[ ] NFR-CRW-03  Legacy gap=0 call sites byte-identical behavior.
[ ] NFR-CRW-04  File < 800 LOC, function < 50 LOC.
[ ] NFR-CRW-05  100% mathematical coverage of new ratio paths.
[ ] NFR-CRW-06  swiftlint lint --strict passes.
```

---

## 6. Testability

```
[ ] T-TEST-01  LayoutEngineTests: 60/40, 80/20, 25/50/25 ratio cases.
[ ] T-TEST-01  Uniform gap tests: left.width + right.width + gap == bounds.width.
[ ] T-TEST-01  Legacy gap=0 invariants unchanged.
[ ] T-TEST-02  OddPixelTests for new ratios + gap>0 paths.
[ ] T-TEST-03  PreferencesStoreTests: clamping, default ratio persistence,
               actor isolation.
[ ] SnapEngine fallback test: gap nil → preferencesStore.windowGap; nil store → 0.
```

---

## 7. Accessibility & UX

```
[ ] Gap Picker labels readable; segmented control with 5 fixed options.
[ ] Visual preview of gap effect on 2-column layout.
[ ] Immediate persistence (no explicit save button required).
[ ] VoiceOver label on gap/ratio pickers (where applicable).
```

---

## 8. Sign-off Gate

```
[ ] All REQ-CRW-01 → 07 implemented and verified by tests.
[ ] 100% mathematical coverage on LayoutEngine new paths.
[ ] swiftlint lint --strict passes with zero warnings.
[ ] Legacy behavior (gap=0) regression-tested.
[ ] ADR-003 (uniform param) signed off.
```

---