# Test Plan: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature slug**: `cross-junction-divider-resize`
- **Baseline version**: 1.0 (SIGNED-OFF)
- **Traces to**: `.specify/features/cross-junction-divider-resize/spec/user-stories.md`

---

## Unit Tests

### `CollinearEdgeDetector`

#### TC-CJR-001: Detect T-Junction intersection point

```gherkin
Given 3 windows (VSCode left full-height, Chrome top-right, Terminal bottom-right)
When detectJunctions is called on the detected collinear edges
Then 1 CrossJunction is returned at (720, 450) with hitRadius 14.0
  And participatingWindowIDs contains all 3 window IDs
```

**File**: `FlowSnapTests/Core/CollinearEdgeDetectorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-CJR-001` Scenario 1

#### TC-CJR-002: Detect 4-Window Cross Junction intersection point

```gherkin
Given 4 windows tiled in a 2x2 grid
When detectJunctions is called
Then 1 CrossJunction is returned at the central intersection
  And participatingWindowIDs contains all 4 window IDs
```

**File**: `FlowSnapTests/Core/CollinearEdgeDetectorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-CJR-001` Scenario 2

#### TC-CJR-003: 2D simultaneous resize computation with decoupled clamping

```gherkin
Given a T-junction at (720, 450) with 3 participating windows
When compute2DResizedFrames is called with target point (800, 500)
Then the left window width becomes 800
  And top-right window origin is (800, 500)
  And bottom-right window origin is (800, 0) with height 500
```

**File**: `FlowSnapTests/Core/CollinearEdgeDetectorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-CJR-002` Scenario 1

---

## Integration Tests

### `AdaptiveDividerCoordinator`

#### TC-CJR-004: Hover within 14pt switches cursor to crosshair

```gherkin
Given 3 windows in T-junction layout
When mouse moves to (720, 450)
Then currentCursor is NSCursor.crosshair
  And hoveredJunction is non-nil
```

**File**: `FlowSnapTests/Core/AdaptiveDividerCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-CJR-001` Scenario 1

#### TC-CJR-005: Live 2D drag updates all participating window frames

```gherkin
Given an active drag starting at (720, 450)
When handleMouseDragged is called to (760, 480)
Then all 3 windows receive updated frames matching the 2D junction
```

**File**: `FlowSnapTests/Core/AdaptiveDividerCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-CJR-002` Scenario 1

#### TC-CJR-006: Escape key cancels 2D drag and restores original frames

```gherkin
Given an active 2D junction drag
When Escape key is pressed
Then isResizing is false
  And original window frames are restored
```

**File**: `FlowSnapTests/Core/AdaptiveDividerCoordinatorTests.swift`
**Priority**: Must-Have
**Traces to**: `US-CJR-003` Scenario 1
