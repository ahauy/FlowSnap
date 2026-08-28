# Test Plan: Display-Aware Multi-Monitor Manipulation (US-SNAP-003)

**Feature slug**: `display-aware-manipulation`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: AI (`backend-developer`) — Stage TDD (before implementation)  
**Traces to**: `.specify/features/display-aware-manipulation/spec/user-stories.md`

---

## 1. Unit Tests

### `CoordinateTransformer`

#### TC-DISP-001: Standard AppKit to AX Rect Inversion

```gherkin
Given a primary screen height of 900 points
When converting an AppKit rect (x: 0, y: 450, width: 720, height: 450)
Then the resulting AX rect has origin (x: 0, y: 0) and size (720, 450)
```

- **File**: `FlowSnapTests/Core/CoordinateTransformerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.1` Scenario 1.1

#### TC-DISP-002: Exact Mathematical Involution

```gherkin
Given any arbitrary rect R and primary screen height H
When evaluating toAppKit(toAX(R, primaryScreenHeight: H), primaryScreenHeight: H)
Then the resulting rect exactly matches R with zero drift
```

- **File**: `FlowSnapTests/Core/CoordinateTransformerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.1` Scenario 1.2

#### TC-DISP-003: Negative Coordinate External Screen Inversion

```gherkin
Given a primary screen height of 1080 points and an external screen below it at y: -900, height: 900
When converting a window frame at (x: 100, y: -800, width: 600, height: 400)
Then the resulting AX rect is (x: 100, y: 1480, width: 600, height: 400)
```

- **File**: `FlowSnapTests/Core/CoordinateTransformerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.1` Scenario 1.3

#### TC-DISP-004: Sub-pixel Float Precision

```gherkin
Given a rect with fractional coordinates (x: 100.25, y: 200.5, width: 500.75, height: 350.125) and height 1000
When converting to AX coordinates
Then all coordinates preserve exact fractional precision without rounding
```

- **File**: `FlowSnapTests/Core/CoordinateTransformerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.1` Scenario 1.4

---

### `DisplayManager`

#### TC-DISP-005: Straddling Window Resolved to Maximum Overlap Display

```gherkin
Given Display 1 at (0, 0, 1440, 900) and Display 2 at (1440, 0, 1920, 1080)
When a window frame is (1300, 100, 500, 400)
Then the resolved display is Display 2 (144,000 pt² vs 56,000 pt²)
```

- **File**: `FlowSnapTests/Infrastructure/DisplayManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.2` Scenario 2.1

#### TC-DISP-006: Contained Window Resolution

```gherkin
Given Display 1 and Display 2
When a window is located entirely within Display 1
Then the resolved display is Display 1
```

- **File**: `FlowSnapTests/Infrastructure/DisplayManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.2` Scenario 2.2

#### TC-DISP-007: Off-screen Fallback to Cursor Location

```gherkin
Given Display 1 and Display 2 and a window outside all screen bounds
When cursor is located at (1600, 500) on Display 2
Then the resolved display falls back to Display 2
```

- **File**: `FlowSnapTests/Infrastructure/DisplayManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.2` Scenario 2.3

#### TC-DISP-008: Mirrored Displays Coalescing

```gherkin
Given an external display mirroring the primary screen
When querying available displays on DisplayManaging
Then only the master display is returned, avoiding duplicates
```

- **File**: `FlowSnapTests/Infrastructure/DisplayManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.3` Scenario 3.2

#### TC-DISP-009: Cyclic Multi-Display Navigation

```gherkin
Given two displays (Screen 1, Screen 2)
When calling nextDisplay(after: Screen 1) -> Screen 2
And when calling nextDisplay(after: Screen 2) -> Screen 1 (cycles around)
```

- **File**: `FlowSnapTests/Infrastructure/DisplayManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.4` Scenario 4.1

#### TC-DISP-010: Single Screen Navigation Guard

```gherkin
Given only a single screen is connected
When calling nextDisplay(after: Screen 1)
Then nil is returned
```

- **File**: `FlowSnapTests/Infrastructure/DisplayManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `US-SNAP-003.4` Scenario 4.2

---

### `SnapEngine` (Multi-Monitor Coordination)

#### TC-DISP-011: Multi-Monitor Target Frame & AX Conversion

```gherkin
Given a window on Secondary Display (1440, 0, 1920, 1080) and Primary Screen Height 900
When snapping window to .leftHalf
Then SnapEngine calculates the zone within Secondary visibleFrame and converts to AX coordinates
```

- **File**: `FlowSnapTests/Core/MultiMonitorSnapEngineTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-DISP-002`, `REQ-DISP-003`

#### TC-DISP-012: Move Window to Next Display Preserving Zone

```gherkin
Given a window snapped to .leftHalf on Display 1
When executing move to next display
Then the window frame is calculated for .leftHalf on Display 2
```

- **File**: `FlowSnapTests/Core/MultiMonitorSnapEngineTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-DISP-006`

---

## 2. Test Coverage Checklist

- [x] All `US-SNAP-003.1` scenarios (1.1, 1.2, 1.3, 1.4) have corresponding TCs
- [x] All `US-SNAP-003.2` scenarios (2.1, 2.2, 2.3) have corresponding TCs
- [x] All `US-SNAP-003.3` scenarios (3.1, 3.2) have corresponding TCs
- [x] All `US-SNAP-003.4` scenarios (4.1, 4.2) have corresponding TCs
- [x] Concurrency and strict Sendable invariants verified
- [x] Sub-pixel floating point precision verified
