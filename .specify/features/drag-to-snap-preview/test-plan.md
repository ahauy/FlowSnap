# Test Plan: Drag-to-Snap & HUD Snap Preview

**Feature slug**: `drag-to-snap-preview`
**Baseline version**: 1.0 (SIGNED-OFF)
**Written by**: AI (Antigravity) — Stage TDD (Pre-implementation)
**Traces to**: `.specify/features/drag-to-snap-preview/spec.md`

---

## Unit & Integration Tests

### 1. `SnapDetector` Tests

#### TC-DRAG-001: 4 Halves & Maximize Edge Detection

```gherkin
Given a display with frame (0, 0, 1920, 1080)
When cursor is at left edge (x: 2, y: 540) within 4px threshold
Then SnapDetector returns target .leftHalf with previewFrame (0, 0, 960, 1080)

When cursor is at right edge (x: 1918, y: 540) within 4px threshold
Then SnapDetector returns target .rightHalf with previewFrame (960, 0, 960, 1080)

When cursor is at top edge (x: 960, y: 1078) within 4px threshold
Then SnapDetector returns target .maximize with previewFrame (0, 0, 1920, 1080)

When cursor is at bottom edge (x: 960, y: 2) within 4px threshold
Then SnapDetector returns target .bottomHalf with previewFrame (0, 0, 1920, 540)
```

- **File**: `FlowSnapTests/Core/SnapDetectorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-DRAG-001`, `BR-DRAG-002`, `REQ-DRAG-002`

---

#### TC-DRAG-002: 4 Corners Zone Detection

```gherkin
Given a display with frame (0, 0, 1920, 1080)
When cursor is at top-left corner (x: 2, y: 1078)
Then SnapDetector returns target .topLeft

When cursor is at top-right corner (x: 1918, y: 1078)
Then SnapDetector returns target .topRight

When cursor is at bottom-left corner (x: 2, y: 2)
Then SnapDetector returns target .bottomLeft

When cursor is at bottom-right corner (x: 1918, y: 2)
Then SnapDetector returns target .bottomRight
```

- **File**: `FlowSnapTests/Core/SnapDetectorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-DRAG-002`, `REQ-DRAG-002`

---

#### TC-DRAG-003: Multi-Monitor Adjacent Edge Detection

```gherkin
Given Primary display A (0, 0, 1920, 1080) and Secondary display B (1920, 0, 1920, 1080) on right
When cursor is at right edge of display A (x: 1919, y: 540)
Then SnapDetector identifies edge as adjacent display boundary (isAdjacentEdge = true)

When cursor is at left edge of display A (x: 2, y: 540)
Then SnapDetector identifies edge as outer boundary (isAdjacentEdge = false)
```

- **File**: `FlowSnapTests/Core/SnapDetectorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-DRAG-001`, `REQ-DRAG-003`

---

#### TC-DRAG-004: Cursor In Deadzone / Interior Region

```gherkin
Given a display with frame (0, 0, 1920, 1080)
When cursor is at center (x: 960, y: 540) (> 4px from any edge)
Then SnapDetector returns nil
```

- **File**: `FlowSnapTests/Core/SnapDetectorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `REQ-DRAG-002`

---

### 2. `DragToSnapCoordinator` Tests

#### TC-DRAG-005: Dwell Timer State Machine & Outer vs Adjacent Edge

```gherkin
Given DragToSnapCoordinator is tracking drag events
When cursor moves to an outer edge
Then dwell timeout is set to 100ms
And after 100ms, SnapPreviewPanel.showPreview is called

When cursor moves to an adjacent internal edge
Then dwell timeout is set to 250ms
And after 250ms, SnapPreviewPanel.showPreview is called
```

- **File**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-DRAG-001`, `REQ-DRAG-003`

---

#### TC-DRAG-006: Release-to-Snap & Preview Dismissal

```gherkin
Given a preview overlay is currently active for .leftHalf
When leftMouseUp event is received
Then SnapEngine.snap is invoked with .leftHalf on the frontmost window
And SnapPreviewPanel.hidePreview is called
```

- **File**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-DRAG-004`, `REQ-DRAG-005`

---

#### TC-DRAG-007: Cancel / Move-Away Dismissal

```gherkin
Given a preview overlay is currently active or dwell timer is running
When cursor moves > 20px away from edge
Then dwell timer is cancelled
And SnapPreviewPanel.hidePreview is called
```

- **File**: `FlowSnapTests/Core/DragToSnapCoordinatorTests.swift`
- **Priority**: Must-Have (P0)
- **Traces to**: `BR-DRAG-005`, `REQ-DRAG-006`

---

## Test Coverage Checklist

- [x] TC-DRAG-001: 4 Halves & Maximize Edge Detection
- [x] TC-DRAG-002: 4 Corners Zone Detection
- [x] TC-DRAG-003: Multi-Monitor Adjacent Edge Detection
- [x] TC-DRAG-004: Deadzone / Interior nil return
- [x] TC-DRAG-005: Dwell timer outer vs adjacent edge differentiation
- [x] TC-DRAG-006: Mouse up release-to-snap execution
- [x] TC-DRAG-007: Move-away cancellation & dismissal
