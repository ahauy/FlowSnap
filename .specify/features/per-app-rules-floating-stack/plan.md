# Technical Plan — Per-App Window Policies & Smart Floating Stack (US-WORK-014)

- **Feature Slug**: `per-app-rules-floating-stack`
- **Specification**: [.specify/features/per-app-rules-floating-stack/spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/spec.md)
- **Baseline**: [.specify/features/per-app-rules-floating-stack/baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/per-app-rules-floating-stack/baseline.md) (SIGNED-OFF v1.0)
- **ADR**: [adr/0009-per-app-window-policies-and-floating-stack.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0009-per-app-window-policies-and-floating-stack.md)

---

## 1. Architectural Architecture & Seam Discipline

Following Ousterhout's Deep Module and Seam Discipline principles:

- **Domain Layer**:
  - `WindowPolicy.swift`: Update enum cases to support `.assignedLayout(LayoutZone)` and conform to `Sendable`, `Codable`, `Hashable`.
  - `AppPolicyRule.swift`: Model entity representing configured app rules.
  - `RememberedFrame.swift`: Model value object for saved window bounds.
- **Core Layer**:
  - `WindowPolicyManager.swift`:
    - Inject `PreferencesStore` or rule repository.
    - Implement full `applyPolicy(for window: ManagedWindow)`:
      - `.currentSpace` / `.currentDisplay`: Use existing visibleFrame centering/placement.
      - `.floating`: Record in `SmartFocusStack`, do not alter window size/position.
      - `.rememberPosition`: Retrieve saved frame, clamp to `display.visibleFrame`, and set via `accessibilityService.setFrame`.
      - `.assignedLayout(zone)`: Compute frame using `LayoutEngine.calculateFrame(zone, in: display.visibleFrame)` and set via `accessibilityService.setFrame`.
    - Handle `WindowEvent.applicationWindowCreated`, `applicationTerminated`, and window destruction.
  - `SmartFocusStack.swift`: Pure `@MainActor` focus tracker tracking window activation order and popping the previously focused window upon floating app destruction.
  - `FrameClampingHelper.swift`: Pure mathematical utility function clamping a `CGRect` within a target screen `visibleFrame`.
- **Infrastructure Layer**:
  - `PreferencesStore.swift`:
    - Add `@Published public private(set) var appRules: [AppPolicyRule]`.
    - Add `@Published public private(set) var rememberedFrames: [String: RememberedFrame]`.
    - Provide thread-safe mutations: `setAppRule`, `removeAppRule`, `saveRememberedFrame`, `rememberedFrame`.
- **UI Layer**:
  - `ApplicationRulesView.swift`:
    - Bind reactively to `PreferencesStore.appRules`.
    - Provide a sheet or modal to add installed / running applications.
    - Offer a picker to choose policies (`.currentSpace`, `.floating`, `.rememberPosition`, `.assignedLayout`).
    - When `.assignedLayout` is chosen, display a secondary zone picker.
- **App Layer**:
  - Update `AppDependencies.swift` to pass `preferencesStore` into `WindowPolicyManager`.

---

## 2. Concurrency & Actor Isolation

- **Swift 6 Strict Concurrency**:
  - All UI elements (`ApplicationRulesView`) and managers (`WindowPolicyManager`, `PreferencesStore`, `SmartFocusStack`) are isolated to `@MainActor`.
  - Data transfer types (`AppPolicyRule`, `RememberedFrame`, `WindowPolicy`) conform strictly to `Sendable`.
  - Async operations invoking `AccessibilityService` bridge cleanly across actors.

---

## 3. Step-by-Step Implementation Sequence

1. **Domain Entities**:
   - Update `WindowPolicy.swift` with `case assignedLayout(LayoutZone)`.
   - Create `AppPolicyRule.swift` and `RememberedFrame.swift`.
2. **Infrastructure Persistence**:
   - Extend `PreferencesStore.swift` with `appRules` and `rememberedFrames` loading, saving, and `@Published` properties.
3. **Core Logic**:
   - Create `FrameClampingHelper.swift` with unit tests for bounds safety.
   - Create `SmartFocusStack.swift` for MRU window focus tracking.
   - Update `WindowPolicyManager.swift` to support all policies with precedence rules.
4. **UI Integration**:
   - Connect `ApplicationRulesView.swift` to `PreferencesStore`.
   - Implement "Add Application" sheet and policy picker.
5. **Fullstack Integration & Tests**:
   - Wire `AppDependencies.swift`.
   - Write comprehensive unit tests in `WindowPolicyManagerTests.swift` and `PreferencesStoreTests.swift`.
