# Feature: Per-App Window Policies & Smart Floating Stack (US-WORK-014)

- **Feature Slug**: `per-app-rules-floating-stack`
- **Epic**: `EPIC 12: Per-App Window Policies & Smart Floating Stacking`
- **Sprint**: Sprint 3
- **Status**: Completed & Verified (`358/358` tests passing across 55 suites, `swiftlint` clean, zero private CGS/SLS symbols)
- **Specifications**: [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/spec.md) | [baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/baseline.md) | [plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/plan.md) | [tasks.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/tasks.md) | [data-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/data-model.md) | [ADR-0009](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0009-per-app-window-policies-and-floating-stack.md)

---

## 1. Overview & Business Value

Power users rely on different workflows for different applications. While coding or document editing benefits from rigid split-screen partitions, auxiliary tools such as messengers (Slack, Telegram), calculators, and media players (Spotify) work best when floating freely above existing layouts without disturbing active side-by-side tiling.

`US-WORK-014` introduces **Per-App Window Policies & Smart Floating Stack** — empowering users to configure specialized window behaviors on a per-bundle-identifier basis:

1. **Floating Window Layout Immunity**: Windows configured with `.floating` retain their user-specified coordinates and are never automatically force-tiled when other windows snap.
2. **Smart Focus Restoration Stack**: Closing or hiding a floating window automatically returns keyboard/window focus to the previously active underlying window using `SmartFocusStack`.
3. **Display-Aware Remembered Positions**: Applications configured with `.rememberPosition` persist their last closed window geometry and restore it safely, clamped against active screen boundaries (`FrameClampingHelper`) to prevent off-screen windows when switching between desktop and mobile setups.
4. **Assigned Canonical Zones**: Applications configured with `.assignedLayout(LayoutZone)` automatically snap into designated zones (such as Left 70%, Right 30%, Maximize, or Half splits) computed via `LayoutEngine`.
5. **Interactive Settings UI**: A dedicated "App Rules" tab in `SettingsView` (`ApplicationRulesView.swift`) with live `PreferencesStore` binding, app selection suggestions, and policy pickers.

---

## 2. Architecture & Seam Discipline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              ApplicationRulesView                            │
│                  (SwiftUI, Settings Tab, PreferencesStore binding)          │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │ updates
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                                PreferencesStore                              │
│         (@Published appRules, rememberedFrames in UserDefaults)             │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │ injected into
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              WindowPolicyManager                             │
│       (@MainActor, Core/Policy/WindowPolicyManager.swift)                    │
│                                                                              │
│  • policy(forBundleID:) -> checks PreferencesStore rules > defaultPolicy    │
│  • applyPolicy(for window:) -> dispatches:                                  │
│       ├─ .currentSpace / .currentDisplay                                     │
│       ├─ .floating -> SmartFocusStack.recordFocus(isFloating: true)         │
│       ├─ .rememberPosition -> FrameClampingHelper.clamp(to: visibleFrame)    │
│       └─ .assignedLayout(zone) -> LayoutEngine.frame(for: in:)              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Key Components & Implementation Files

| Component                                                                                                                           | Path                                                | Responsibility                                                                                                  |
| :---------------------------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| [`WindowPolicy`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Window/WindowPolicy.swift)                      | `Domain/Window/WindowPolicy.swift`                  | Public domain enum supporting `.currentSpace`, `.floating`, `.rememberPosition`, `.assignedLayout(LayoutZone)`. |
| [`AppPolicyRule`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Window/AppPolicyRule.swift)                    | `Domain/Window/AppPolicyRule.swift`                 | Domain entity mapping bundleID to name, policy, and icon.                                                       |
| [`RememberedFrame`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Window/RememberedFrame.swift)                | `Domain/Window/RememberedFrame.swift`               | Value object capturing saved window geometry and display ID.                                                    |
| [`FrameClampingHelper`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Policy/FrameClampingHelper.swift)          | `Core/Policy/FrameClampingHelper.swift`             | Mathematical utility ensuring clamped visibility inside screen visibleBounds.                                   |
| [`SmartFocusStack`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Policy/SmartFocusStack.swift)                  | `Core/Policy/SmartFocusStack.swift`                 | MRU window activation tracker enabling natural focus restoration.                                               |
| [`WindowPolicyManager`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Policy/WindowPolicyManager.swift)          | `Core/Policy/WindowPolicyManager.swift`             | Policy coordinator applying per-app rules and handling window lifecycles.                                       |
| [`PreferencesStore`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Infrastructure/Persistence/PreferencesStore.swift) | `Infrastructure/Persistence/PreferencesStore.swift` | Reactive UserDefaults persistence for app rules and remembered frames.                                          |
| [`ApplicationRulesView`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/UI/Settings/ApplicationRulesView.swift)        | `UI/Settings/ApplicationRulesView.swift`            | SwiftUI settings interface for managing and testing per-app rules.                                              |

---

## 4. Verification Evidence

- **Unit Test Suite**: 358 tests passing in 55 suites (`xcodebuild test`).
- **Code Quality**: `swiftlint` clean (0 errors).
- **Public API Audit**: `bash scripts/audit-no-private-apis.sh` confirms 0 private CGS/SLS symbols used.
- **Traceability**: 100% bidirectional coverage across `BR-POLICY-001..005`, `REQ-POLICY-001..006`, and `TC-014-01..08`.
