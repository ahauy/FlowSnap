# Feature: Cross-Display Window Throw (US-DISP-015)

- **Feature Slug**: `cross-display-window-throw`
- **Epic**: `EPIC 13: Advanced Multi-Monitor Topology & Cross-Display Navigation`
- **Sprint**: Sprint 4 (Multi-Monitor Excellence)
- **Status**: Completed & Verified (`372/372` tests passing across 58 suites, `swiftlint` clean, zero private CGS/SLS symbols)
- **Specifications**: [spec.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/spec.md) | [baseline.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/baseline.md) | [plan.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/plan.md) | [tasks.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/tasks.md) | [data-model.md](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/.specify/features/cross-display-window-throw/data-model.md) | [ADR-0010](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/adr/0010-cross-display-window-throw.md)

---

## 1. Overview & Business Value

In professional macOS workflows with multiple external monitors (e.g. MacBook Pro connected to 4K displays or ultra-wide setups), moving windows between screens manually via drag-and-drop causes friction, disrupts developer focus, and creates sizing mismatches between different monitor resolutions.

`US-DISP-015` introduces **Cross-Display Window Throw & Target-Aware Snap** — allowing users to seamlessly "throw" the active window across connected monitors with global keyboard shortcuts:

1. **Global Hotkeys**:
   - `⌃⌥⇧→` (`Ctrl + Option + Shift + Right Arrow`): Move window to next display.
   - `⌃⌥⇧←` (`Ctrl + Option + Shift + Left Arrow`): Move window to previous display.
2. **Spatial Left-to-Right Topology (`DisplayNavigator`)**:
   - Screens are ordered spatially based on physical layout (`minX`, tie-break `minY`), ensuring predictable navigation matching the user's desk arrangement.
   - Cyclic modulo wrap-around: Navigating past the rightmost screen returns to the leftmost screen, and vice versa.
3. **Semantic Snap Preservation with Geometric Fallback**:
   - If the window is snapped (e.g. Left Half, Right Half, Maximize), FlowSnap preserves its semantic intent and recalculates the snap frame for the target monitor, honoring destination safe areas and window gaps.
   - If free-floating, `RelativeFrameScaler` maps proportional offsets and dimensions (`relX, relY, relW, relH`), clamped safely inside the target monitor via `FrameClampingHelper`.
4. **Instant Cursor Warping & Focus Synchronization (`CursorManager`)**:
   - Automatically warps the mouse pointer to the center of the newly positioned window on the target display (`CGWarpMouseCursorPosition`), keeping mouse and keyboard focus unified without manual pointer hunting.
5. **Single Display Graceful Degradation**:
   - Safe, instantaneous no-op when only 1 monitor is connected.

---

## 2. Architecture & Seam Discipline

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                            GlobalHotkeyManager                               │
│              (Carbon Event Hotkeys: ⌃⌥⇧→ and ⌃⌥⇧←)                           │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │ dispatches
                                        ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                             CommandDispatcher                                │
│       (@MainActor, Core/Commands/CommandDispatcher.swift)                    │
│                                                                              │
│  • .moveToNextDisplay / .moveToPreviousDisplay                               │
│  • Guard: displayManager.displays.count > 1                                  │
│  • Resolve source Display via window frame                                   │
│  • Resolve target Display via DisplayNavigator (modulo cyclic traversal)     │
│  • Frame calculation:                                                        │
│       ├─ Snapped (IoU >= 0.75): SnapEngine.calculateAXFrame on target       │
│       └─ Free-form: RelativeFrameScaler.scale + FrameClampingHelper          │
│  • WindowManager.move(window, to: targetAXFrame)                             │
│  • CursorManager.warpCursor(to: targetWindowCenter)                          │
│  • WindowManager.focus(window)                                               │
└───────────────────────────────────────┬──────────────────────────────────────┘
                                        │
             ┌──────────────────────────┴──────────────────────────┐
             ▼                                                     ▼
┌─────────────────────────┐                           ┌─────────────────────────┐
│     DisplayNavigator    │                           │   RelativeFrameScaler   │
│ (Core/Display/          │                           │ (Core/Display/          │
│  DisplayNavigator.swift)│                           │  RelativeFrameScaler.s) │
└─────────────────────────┘                           └─────────────────────────┘
```

---

## 3. Key Components & Implementation Files

| Component                                                                                                                   | Path                                       | Responsibility                                                                                  |
| :-------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------- | :---------------------------------------------------------------------------------------------- |
| [`WindowCommand`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Commands/WindowCommand.swift)          | `Domain/Commands/WindowCommand.swift`      | Domain command enum with `.moveToNextDisplay` and `.moveToPreviousDisplay`.                     |
| [`ShortcutAction`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Hotkeys/ShortcutAction.swift)         | `Domain/Hotkeys/ShortcutAction.swift`      | Out-of-the-box shortcut bindings `⌃⌥⇧→` / `⌃⌥⇧←` and commands.                                  |
| [`DisplayNavigating`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Display/DisplayNavigator.swift)      | `Core/Display/DisplayNavigator.swift`      | Protocol and concrete engine for spatial display sorting and cyclic navigation.                 |
| [`RelativeFrameScaler`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Display/RelativeFrameScaler.swift) | `Core/Display/RelativeFrameScaler.swift`   | Proportional geometric transformer mapping frames between displays with clamping.               |
| [`CursorManager`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Infrastructure/macOS/CursorManager.swift)     | `Infrastructure/macOS/CursorManager.swift` | CoreGraphics cursor warp adapter (`CGWarpMouseCursorPosition`).                                 |
| [`CommandDispatcher`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Commands/CommandDispatcher.swift)    | `Core/Commands/CommandDispatcher.swift`    | Central coordinator orchestrating the cross-display throw, scaling, moving, and cursor warping. |

---

## 4. Verification Evidence

- **Unit Test Suite**: 372 tests passing in 58 suites (`xcodebuild test`).
- **Code Quality**: `swiftlint` clean (0 errors, 0 warnings).
- **Public API Audit**: 100% Public macOS APIs (zero private CGS/SLS symbols).
- **Traceability**: 100% bidirectional coverage across `BR-DISP-007..012`, `REQ-DISP-015-001..006`, and `TC-015-01..08`.
