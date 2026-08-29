# Test Plan: Top-Edge Snap Layout Picker

**Feature slug**: `top-edge-layout-picker`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (Pre-implementation)
**Traces to**: `.specify/features/top-edge-layout-picker/spec.md`

---

## Unit & Integration Tests

### 1. `LayoutEngine` Extended Tests

#### TC-TOP-001: Asymmetric 70/30 & 3-Column Calculation

```gherkin
Given a display visibleFrame with (0, 0, 1920, 1080)
When calculateFrame is called for .leftTwoThirds (70%)
Then the resulting frame is (0, 0, 1344, 1080)

When calculateFrame is called for .rightOneThird (30%)
Then the resulting frame is (1344, 0, 576, 1080)

When calculateFrame is called for .leftThird (1/3)
Then the resulting frame is (0, 0, 640, 1080)

When calculateFrame is called for .centerThird (1/3)
Then the resulting frame is (640, 0, 640, 1080)

When calculateFrame is called for .rightThird (1/3)
Then the resulting frame is (1280, 0, 640, 1080)
```

- **File**: `FlowSnapTests/Core/LayoutEngineTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-003`, `REQ-TOP-003`

---

### 2. `SnapDetector` Top-Center Detection Tests

#### TC-TOP-002: Top-Center Zone Detection (Picker Trigger) vs Maximize Snap

```gherkin
Given a display with frame (0, 0, 1920, 1080)
When cursor is at top-center (x: 960, y: 1076) (x in 30%-70% width, y within 24px of top)
Then SnapDetector identifies topCenterZone = true / triggers layout picker

When cursor is at top-left edge (x: 100, y: 1078) (x < 30% width)
Then SnapDetector identifies standard top/corner snap target

When cursor is at top-right edge (x: 1800, y: 1078) (x > 70% width)
Then SnapDetector identifies standard top/corner snap target
```

- **File**: `FlowSnapTests/Core/SnapDetectorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-001`, `REQ-TOP-001`

---

### 3. `SnapLayoutPickerManager` & Panel Lifecycle Tests

#### TC-TOP-003: Layout Templates & Slots Integrity

```gherkin
Given LayoutTemplate.standardTemplates
Then there are 4 templates: 2-Column Equal, 2-Column Asymmetric, 3-Column Equal, 4-Quarters
And all slots map to valid SnapTargets
```

- **File**: `FlowSnapTests/UI/SnapLayoutPickerManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-003`, `REQ-TOP-002`

#### TC-TOP-004: Slot Hit-Testing & Hover Projection

```gherkin
Given SnapLayoutPickerManager presenting on display (0, 0, 1920, 1080)
When mouse point is inside Slot 1 of Template 2 (Left 70%)
Then hitTestSlot returns Slot(target: .leftTwoThirds)
And previewManager.showPreview is called with the calculated 70% frame
```

- **File**: `FlowSnapTests/UI/SnapLayoutPickerManagerTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-004`, `REQ-TOP-005`

---

### 4. `DragToSnapCoordinator` Integration Tests

#### TC-TOP-005: Drag into Top-Center summons Layout Picker

```gherkin
Given DragToSnapCoordinator is tracking drag
When cursor enters Top-Center zone
Then SnapLayoutPickerManager.showPicker is called on active display
And when cursor moves over a slot, SnapPreviewManager displays the slot preview
```

- **File**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-001`, `REQ-TOP-001`, `REQ-TOP-005`

#### TC-TOP-006: Release inside Picker Slot snaps window

```gherkin
Given DragToSnapCoordinator with active hovered slot in picker
When leftMouseUp event occurs
Then CommandDispatcher.dispatch(.snap(target, targetDisplayID)) is executed
And SnapLayoutPickerManager.hidePicker is called
And flashSnapSuccess is triggered
```

- **File**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-005`, `REQ-TOP-006`

#### TC-TOP-007: Move-Away from Picker dismisses panel smoothly

```gherkin
Given SnapLayoutPicker is currently presenting
When cursor moves outside picker frame (> 20px below picker)
Then SnapLayoutPickerManager.hidePicker is called
And full-screen preview is dismissed
```

- **File**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-PICKER-006`, `REQ-TOP-007`

---

## Test Coverage Checklist

- [x] TC-TOP-001: Asymmetric 70/30 & 3-Column Calculation
- [x] TC-TOP-002: Top-Center Zone Detection vs Maximize Snap
- [x] TC-TOP-003: Layout Templates & Slots Integrity
- [x] TC-TOP-004: Slot Hit-Testing & Hover Projection
- [x] TC-TOP-005: Drag into Top-Center summons Layout Picker
- [x] TC-TOP-006: Release inside Picker Slot snaps window
- [x] TC-TOP-007: Move-Away from Picker dismisses panel smoothly
