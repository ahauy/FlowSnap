# Test Plan: Cross-Display Window Throw (US-DISP-015)

**Feature slug**: `cross-display-window-throw`
**Baseline version**: 1.0 (SIGNED-OFF)
**Phase**: Phase 5 TDD (Pre-Implementation)
**Traces to**: `.specify/features/cross-display-window-throw/spec.md` (`REQ-DISP-015-001..006`, `US-DISP-015-01..04`)

---

## 1. Mapping Summary

| User Story / Req                    | TC ID       | Verification Target                                                                            | Test File                                                       |
| :---------------------------------- | :---------- | :--------------------------------------------------------------------------------------------- | :-------------------------------------------------------------- |
| `REQ-DISP-015-001` (Hotkeys)        | `TC-015-01` | `ShortcutAction.nextDisplay` and `previousDisplay` have correct default keycodes and modifiers | `FlowSnapTests/Domain/ShortcutActionTests.swift`                |
| `REQ-DISP-015-002` (Topology)       | `TC-015-02` | `DisplayNavigator` sorts displays left-to-right (`minX`, tie-break `minY`)                     | `FlowSnapTests/Core/Display/DisplayNavigatorTests.swift`        |
| `REQ-DISP-015-002` (Topology)       | `TC-015-03` | `DisplayNavigator.nextDisplay` and `previousDisplay` wrap cyclically modulo N                  | `FlowSnapTests/Core/Display/DisplayNavigatorTests.swift`        |
| `REQ-DISP-015-003` (Scaling)        | `TC-015-04` | `RelativeFrameScaler` maps relative (x, y, w, h) from source to target display                 | `FlowSnapTests/Core/Display/RelativeFrameScalerTests.swift`     |
| `REQ-DISP-015-003` (Scaling)        | `TC-015-05` | `RelativeFrameScaler` clamps frame inside target visibleBounds with min size 200x200           | `FlowSnapTests/Core/Display/RelativeFrameScalerTests.swift`     |
| `REQ-DISP-015-004` (Semantic Snap)  | `TC-015-06` | Snapped window preserves `SnapTarget` on target display with target `WindowGap`                | `FlowSnapTests/Core/Display/DisplayThrowCoordinatorTests.swift` |
| `REQ-DISP-015-005` (Cursor Warp)    | `TC-015-07` | Cursor warps to center of target window (`midX`, `midY`) and re-asserts focus                  | `FlowSnapTests/Core/Display/DisplayThrowCoordinatorTests.swift` |
| `REQ-DISP-015-006` (Single Display) | `TC-015-08` | Single display setup returns nil / no-op with zero side-effects                                | `FlowSnapTests/Core/Display/DisplayNavigatorTests.swift`        |

---

## 2. Test Specifications (Gherkin Scenarios)

### TC-015-01: Default Shortcut Keycode & Modifiers

```gherkin
Given the ShortcutAction enum
When examining .nextDisplay and .previousDisplay
Then .nextDisplay has keyCode 124 (Right Arrow) and modifiers (Ctrl | Option | Shift)
  And .previousDisplay has keyCode 123 (Left Arrow) and modifiers (Ctrl | Option | Shift)
  And defaultCommand maps to .moveToNextDisplay and .moveToPreviousDisplay
```

### TC-015-02: Spatial Topology Left-to-Right Sorting

```gherkin
Given three displays with origin X at 1920, -1440, and 0
When DisplayNavigator.sortedDisplays is called
Then the displays are returned in order: [-1440, 0, 1920]
```

### TC-015-03: Cyclic Modulo Display Navigation

```gherkin
Given sorted displays [Display 0, Display 1, Display 2]
When nextDisplay(after: Display 2) is called
Then it returns Display 0 (cyclic wrap-around)
When previousDisplay(before: Display 0) is called
Then it returns Display 2 (cyclic wrap-around)
```

### TC-015-04: Proportional Relative Frame Scaling

```gherkin
Given a source display of size (0, 0, 1920, 1080)
  And a target display of size (1920, 0, 3840, 2160)
  And a window at (192, 108, 960, 540) [occupying 10% x, 10% y, 50% w, 50% h]
When RelativeFrameScaler.scale is invoked
Then the window is scaled to target at (1920 + 384, 0 + 216, 1920, 1080)
```

### TC-015-05: Target Frame Clamping & Minimum Size

```gherkin
Given a tiny or off-screen window relative to a source screen
When RelativeFrameScaler.scale is invoked with a target screen
Then the resulting frame width >= 200 and height >= 200
  And the frame is completely inside the target display's visible bounds
```

### TC-015-06: Single Display Graceful Degradation

```gherkin
Given only 1 active display in the system
When nextDisplay(after: display) or previousDisplay(before: display) is called
Then the returned display is nil
```

### TC-015-07: Cursor Warping on Thrown Window

```gherkin
Given an active window thrown to target frame (100, 200, 800, 600)
When the throw coordination pipeline completes
Then cursorManager.warpCursor is called with point (500, 500)
  And accessibilityService.setFocus is called for the window
```
