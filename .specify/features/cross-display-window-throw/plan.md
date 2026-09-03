# Technical Plan — Cross-Display Window Throw (US-DISP-015)

- **Feature Slug**: `cross-display-window-throw`
- **Specification**: [.specify/features/cross-display-window-throw/spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/spec.md)
- **Baseline**: [.specify/features/cross-display-window-throw/baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/baseline.md) (SIGNED-OFF v1.0)
- **Contracts**: [.specify/features/cross-display-window-throw/contracts/DisplayNavigationContracts.swift](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/contracts/DisplayNavigationContracts.swift)

---

## 1. Architecture & Seam Discipline (Deep Modules)

Following Ousterhout's Deep Module and Seam Discipline principles:

- **Domain Layer**:
  - `WindowCommand.swift`: Add `.moveToNextDisplay` and `.moveToPreviousDisplay`.
  - `ShortcutAction.swift`: Set default command to `.moveToNextDisplay` / `.moveToPreviousDisplay` and default shortcuts to `⌃⌥⇧→` / `⌃⌥⇧←`.
- **Core Layer**:
  - `DisplayNavigator.swift`: Pure spatial calculation component sorting displays horizontally from left to right with cyclic modulo arithmetic.
  - `RelativeFrameScaler.swift`: Pure geometric scaling utility converting coordinates from source visible bounds to target visible bounds and delegating to `FrameClampingHelper`.
  - `DisplayManaging.swift` & `DisplayManager.swift`: Ensure `nextDisplay` and `previousDisplay` methods are fully supported.
  - `WindowManager.swift` / `CommandDispatcher.swift`: Coordinate the throw action:
    1. Resolve focused window.
    2. Query displays. If count <= 1, early return (no-op).
    3. Identify current display from window frame.
    4. Calculate target display via `DisplayNavigator`.
    5. Compute target frame: if window was snapped, re-snap with `SnapEngine`; otherwise scale with `RelativeFrameScaler`.
    6. Update window frame via `AccessibilityService.setFrame`.
    7. Warp cursor to target window center point (`CGPoint(x: newFrame.midX, y: newFrame.midY)`) via `CursorWarping`.
    8. Maintain keyboard focus via `AccessibilityService.setFocus`.
- **Infrastructure Layer**:
  - `CursorManager.swift`: Wrapper over `CGWarpMouseCursorPosition` conforming to `CursorWarping` protocol for dependency injection and testability.
- **UI Layer**:
  - `ShortcutSettingsView.swift`: Already displays `ShortcutCategory.displays`; automatically shows default hotkeys and allows custom key rebinding.
- **App Layer**:
  - `AppDependencies.swift`: Inject `CursorManager` and wire `DisplayNavigator`.

---

## 2. Concurrency & Performance Latency Budget

- **Swift 6 Strict Concurrency**:
  - `DisplayNavigator`, `RelativeFrameScaler`, `WindowCommand` are pure `Sendable`.
  - `WindowManager` and `CommandDispatcher` operate on `@MainActor`.
  - Zero cross-actor data races.
- **Latency Budget (< 50ms total)**:
  - Topology calculation: < 1ms (in-memory array sort of 2–4 screens).
  - Relative frame scaling: < 1ms (pure math).
  - AX `setFrame` + `setFocus`: ~15–20ms.
  - `CGWarpMouseCursorPosition`: < 2ms.
  - Total latency: ~20–25ms (well under the 50ms budget).

---

## 3. Implementation Sequence

1. **Domain & Contracts**:
   - Update `WindowCommand.swift`.
   - Update `ShortcutAction.swift` with default hotkeys and commands.
2. **Core Math & Spatial Logic (TDD Red -> Green)**:
   - Implement and test `DisplayNavigator.swift` with diverse multi-monitor geometries.
   - Implement and test `RelativeFrameScaler.swift` with resolution scaling and clamping.
3. **Infrastructure**:
   - Implement `CursorManager.swift` and mock double for tests.
4. **Coordination Pipeline**:
   - Wire cross-display window throw into `WindowManager` / `CommandDispatcher`.
5. **UI & End-to-End Tests**:
   - Verify Settings UI shortcut recorder displays `⌃⌥⇧→` and `⌃⌥⇧←`.
   - Complete unit and integration test suite.
