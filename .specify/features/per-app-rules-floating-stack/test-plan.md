# Test Plan: Per-App Window Policies & Smart Floating Stack (US-WORK-014)

**Feature slug**: `per-app-rules-floating-stack`
**Baseline version**: 1.0 (SIGNED-OFF)
**Phase**: Phase 5 TDD (Pre-Implementation)
**Traces to**: `.specify/features/per-app-rules-floating-stack/spec.md` (REQ-POLICY-001..006, US-WORK-014-01..04)

---

## 1. Mapping Summary

| User Story / Req                                  | TC ID       | Verification Target                                                         | Test File                                                              |
| :------------------------------------------------ | :---------- | :-------------------------------------------------------------------------- | :--------------------------------------------------------------------- |
| `US-WORK-014-01` (Precedence & Assigned Zone)     | `TC-014-01` | App-specific rule overrides default `.currentSpace`                         | `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift`             |
| `US-WORK-014-01` (Precedence & Assigned Zone)     | `TC-014-02` | `.assignedLayout` applies canonical `LayoutZone` frame                      | `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift`             |
| `US-WORK-014-02` (Floating & Focus Restoration)   | `TC-014-03` | `.floating` policy exempts window from repositioning                        | `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift`             |
| `US-WORK-014-02` (Floating & Focus Restoration)   | `TC-014-04` | `SmartFocusStack` restores focus to previous window on floating close       | `FlowSnapTests/Core/Policy/SmartFocusStackTests.swift`                 |
| `US-WORK-014-03` (Remembered Position & Clamping) | `TC-014-05` | `.rememberPosition` restores saved frame                                    | `FlowSnapTests/Core/Policy/WindowPolicyManagerTests.swift`             |
| `US-WORK-014-03` (Remembered Position & Clamping) | `TC-014-06` | `FrameClampingHelper` clamps off-screen/oversized frames to visibleBounds   | `FlowSnapTests/Core/Policy/FrameClampingHelperTests.swift`             |
| `US-WORK-014-04` (Persistence & Domain Models)    | `TC-014-07` | `PreferencesStore` serializes and updates `appRules` and `rememberedFrames` | `FlowSnapTests/Infrastructure/Persistence/PreferencesStoreTests.swift` |
| `US-WORK-014-04` (Persistence & Domain Models)    | `TC-014-08` | `AppPolicyRule` and `RememberedFrame` are `Sendable`, `Codable`, `Hashable` | `FlowSnapTests/Domain/WindowPolicyModelTests.swift`                    |

---

## 2. Test Specifications (Gherkin Scenarios)

### TC-014-01: App-Specific Rule Precedence

```gherkin
Given a WindowPolicyManager with defaultPolicy = .currentSpace
  And an AppPolicyRule configured for "com.test.app" with policy .floating
When policy(forBundleID: "com.test.app") is evaluated
Then the returned policy is .floating
  And policy(forBundleID: "com.other.app") returns .currentSpace
```

### TC-014-02: Assigned Canonical Layout Zone Application

```gherkin
Given a window for "com.microsoft.VSCode" with policy .assignedLayout(.leftHalf)
  And an active display with visibleFrame (0, 0, 1440, 900)
When WindowPolicyManager.applyPolicy(for: window) is invoked
Then accessibilityService.setFrame is called with (0, 0, 720, 900)
```

### TC-014-03: Floating Policy Window Immunity

```gherkin
Given a window for "ru.keepcoder.Telegram" with policy .floating
When WindowPolicyManager.applyPolicy(for: window) is invoked
Then accessibilityService.setFrame is NOT called
  And the window is tracked in SmartFocusStack as floating
```

### TC-014-04: SmartFocusStack Focus Restoration

```gherkin
Given SmartFocusStack has recorded window 101 as focused
When a floating window 202 is focused
  And floating window 202 is removed/dismissed
Then SmartFocusStack returns window 101 as the target for focus restoration
```

### TC-014-05: Remembered Position Frame Restoration

```gherkin
Given an application "com.spotify.client" with saved frame (100, 100, 800, 600)
  And policy .rememberPosition
When WindowPolicyManager.applyPolicy(for: window) is invoked
Then accessibilityService.setFrame is called with the clamped saved frame
```

### TC-014-06: Frame Clamping Mathematical Invariants

```gherkin
Given a saved frame (2000, 500, 800, 600) outside a 1440x900 screen
When FrameClampingHelper.clamp(frame, to: screenBounds) is calculated
Then the clamped frame's maxX <= 1440
  And the clamped frame's maxY <= 900
  And at least 80% of the window area is visible on screen
```

### TC-014-07: PreferencesStore App Rules Persistence

```gherkin
Given a PreferencesStore with mock UserDefaults
When a new AppPolicyRule is added via setAppRule(_:)
Then appRules contains the new rule
  And the rule persists across PreferencesStore re-initialization
```

### TC-014-08: Value Type Sendability & Codability

```gherkin
Given instances of AppPolicyRule and RememberedFrame
When encoded to JSON and decoded back
Then the decoded instances match the originals
  And they can be passed across concurrency boundaries without compiler warnings
```
