# Test Plan: Core Layout Calculation & Basic Snap Engine

**Feature slug**: `core-layout-snap-engine`  
**Baseline version**: 1.0 (SIGNED-OFF)  
**Written by**: `backend-developer` (TDD Stage)  
**Traces to**: `.specify/features/core-layout-snap-engine/spec/user-stories.md`

---

## Unit Tests

### `LayoutEngine` (Pure Mathematical Geometry)

#### TC-001: Standard Halves on 1920x1080 (Even Resolution)

```gherkin
Given a display visible frame of (0, 0, 1920, 1080)
When  LayoutEngine.frame(for: .leftHalf, in: bounds, gap: 0) is called
Then  returned frame is (0, 0, 960, 1080)
When  LayoutEngine.frame(for: .rightHalf, in: bounds, gap: 0) is called
Then  returned frame is (960, 0, 960, 1080)
When  LayoutEngine.frame(for: .topHalf, in: bounds, gap: 0) is called
Then  returned frame is (0, 0, 1920, 540)
When  LayoutEngine.frame(for: .bottomHalf, in: bounds, gap: 0) is called
Then  returned frame is (0, 540, 1920, 540)
```

- **File**: `FlowSnapTests/Core/LayoutEngineTests.swift`
- **Priority**: Must-Have
- **Traces to**: `US-SNAP-002` Scenario 1

---

#### TC-002: Standard Quarters on 1920x1080

```gherkin
Given a display visible frame of (0, 0, 1920, 1080)
When  LayoutEngine computes all 4 corner quarters (topLeft, topRight, bottomLeft, bottomRight)
Then  topLeft is (0, 0, 960, 540)
And   topRight is (960, 0, 960, 540)
And   bottomLeft is (0, 540, 960, 540)
And   bottomRight is (960, 540, 960, 540)
```

- **File**: `FlowSnapTests/Core/LayoutEngineTests.swift`
- **Priority**: Must-Have
- **Traces to**: `US-SNAP-002` Scenario 1

---

#### TC-003: Odd-Pixel Floor Allocation (1441x901 Display)

```gherkin
Given a display visible frame of (0, 0, 1441, 901)
When  LayoutEngine computes .leftHalf and .rightHalf
Then  leftHalf width is 720 (floor(1441 / 2))
And   rightHalf origin x is 720 and width is 721 (1441 - 720)
And   leftHalf.width + rightHalf.width == 1441 exactly
When  LayoutEngine computes .topHalf and .bottomHalf
Then  topHalf height is 450 (floor(901 / 2))
And   bottomHalf origin y is 450 and height is 451 (901 - 450)
And   topHalf.height + bottomHalf.height == 901 exactly
```

- **File**: `FlowSnapTests/Core/LayoutEngineOddPixelTests.swift`
- **Priority**: Must-Have (Zero Gaps / Overflow Invariant)
- **Traces to**: `US-SNAP-002` Scenario 2, `BR-LAYOUT-002`

---

#### TC-004: Maximize to Full Visible Bounds with Menu Bar & Dock Offsets

```gherkin
Given a display with visible bounds (0, 25, 1440, 875)
When  LayoutEngine.frame(for: .maximize, in: bounds, gap: 0) is called
Then  returned frame is (0, 25, 1440, 875) matching visible frame exactly
```

- **File**: `FlowSnapTests/Core/LayoutEngineTests.swift`
- **Priority**: Must-Have
- **Traces to**: `US-SNAP-002` Scenario 3, `BR-LAYOUT-001`

---

#### TC-005: Multi-Resolution Determinism (1440x900, 2560x1440, 3840x2160, 1080x1920)

```gherkin
Given standard resolutions: 1440x900 (MacBook), 2560x1440 (2K), 3840x2160 (4K), 1080x1920 (Portrait)
When  LayoutEngine computes all 9 zones on each resolution
Then  left + right halves span the full width
And   top + bottom halves span the full height
And   all quarters tile the display seamlessly
```

- **File**: `FlowSnapTests/Core/LayoutEngineTests.swift`
- **Priority**: Must-Have
- **Traces to**: `US-SNAP-002` AC 4

---

### `WindowRegistry` & `SnapEngine` (Stateful Coordination)

#### TC-006: Pre-Snap Frame Preservation Across Consecutive Snaps

```gherkin
Given a window with initial user frame (200, 150, 800, 600)
When  window is snapped to .leftHalf
Then  WindowRegistry records (200, 150, 800, 600) as preSnapFrame
When  window is subsequently snapped to .rightHalf, then to .maximize
Then  WindowRegistry still retains (200, 150, 800, 600) unchanged
When  Restore action is triggered
Then  target frame returned is (200, 150, 800, 600)
And   WindowRegistry clears the preSnapFrame
```

- **File**: `FlowSnapTests/Core/SnapEngineTests.swift`
- **Priority**: Must-Have
- **Traces to**: `US-SNAP-002` Scenario 4, `BR-LAYOUT-004`

---

#### TC-007: Restore Without Prior Snap is Safe No-Op

```gherkin
Given a window with no recorded preSnapFrame
When  Restore action is triggered
Then  SnapEngine returns nil and no frame mutation is executed
```

- **File**: `FlowSnapTests/Core/SnapEngineTests.swift`
- **Priority**: Must-Have
- **Traces to**: `US-SNAP-002` Scenario 5

---

## Test Coverage Checklist

- [x] Tất cả `US-SNAP-002` Scenarios 1–6 có TC tương ứng (TC-001 through TC-007)
- [x] Odd-pixel flooring invariant kiểm tra ở TC-003
- [x] Multi-resolution coverage (MacBook, FHD, 2K, 4K, Portrait) kiểm tra ở TC-005
- [x] Consecutive snap idempotency & restore lifecycle kiểm tra ở TC-006 & TC-007
- [x] Swift Concurrency actor isolation cho WindowRegistry kiểm tra ở TC-006
