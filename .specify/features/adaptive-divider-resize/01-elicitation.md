# Stage 2 Elicitation: US-SNAP-009 Adaptive Divider Resize

## Domain Decisions & Elicitation Baseline

### ASM-ADR-001 (Collinear Edge Union Span):
When a vertical or horizontal boundary is shared between multiple windows (e.g., 1 left window vs 2 stacked right windows in a T-junction layout), the vertical boundary constitutes a single continuous `CollinearEdge`. Resizing this edge horizontally updates the width of the left window AND simultaneously updates the widths and X positions of both right windows. The horizontal boundary between the two right windows is an independent horizontal `CollinearEdge` whose span is restricted to the right column.

### ASM-ADR-002 (Hit Testing & Hover Tolerance Margin):
A shared divider is considered hovered when the mouse pointer is within +/- 6 points of the mathematical divider coordinate and falls within the divider's bounding span. When hovered, the system cursor is set to `NSCursor.resizeLeftRight` (vertical divider) or `NSCursor.resizeUpDown` (horizontal divider). Upon exiting the tolerance zone, the cursor restores to `NSCursor.arrow`.

### ASM-ADR-003 (Minimum Dimension Clamping - minSize):
Each window is guarded by a minimum width (default 200 pt) and minimum height (default 150 pt), or its explicit `ManagedWindow.minSize` if declared. During live drag of a divider, the new divider coordinate is clamped such that no window on either the leading or trailing side is squeezed below its minimum allowable dimension. Dragging beyond the clamp limit is a smooth no-op.

### ASM-ADR-004 (60fps Throttling Policy - AXUIElement Rate Limiting):
Live dragging emits mouse events at hardware polling rates (60Hz to 120Hz+ on ProMotion displays). To prevent overloading WindowServer with synchronous Accessibility IPC calls (`AXUIElementSetAttributeValue`), `LiveResizeThrottler` limits AX frame updates to at most once every 16.6 milliseconds (60fps). If multiple drag movements occur during an in-flight throttle interval, intermediate positions are dropped and only the latest target frame is applied when the timer fires.

### ASM-ADR-005 (Window Gap Integration):
When a non-zero `windowGap` is configured (from `PreferencesStore`), the divider position corresponds to the center of the gap between windows. Resizing maintains the exact gap distance between adjacent edges without accumulating floating-point drift or pixel overlap.
