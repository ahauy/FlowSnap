# Software Requirements Specification (SRS): US-SNAP-009

## 1. Functional Requirements

### REQ-ADR-001: Collinear Edge Identification
The system MUST detect all vertical and horizontal shared collinear edges between adjacent windows within an active display partition layout.

### REQ-ADR-002: T-Junction Multi-Window Binding
When a single window is adjacent to multiple stacked windows along a shared axis, the system MUST treat the full shared length as a single CollinearEdge and bind all adjacent window IDs to that divider.

### REQ-ADR-003: Cursor Feedback
When the mouse cursor hovers within +/- 6 points of an identified vertical or horizontal divider, the cursor MUST change to `NSCursor.resizeLeftRight` or `NSCursor.resizeUpDown` respectively, and restore to `NSCursor.arrow` on exit.

### REQ-ADR-004: Live Simultaneous Resizing
Dragging a shared divider MUST simultaneously adjust the dimensions of all windows attached to the leading side and all windows attached to the trailing side.

### REQ-ADR-005: MinSize Boundary Enforcement
The system MUST clamp divider movement such that no participating window is resized smaller than its minimum allowable width (200 pt) or height (150 pt).

### REQ-ADR-006: 60fps Live Resize Throttling
The system MUST pace AXUIElement window positioning requests at no faster than 60fps (~16.6ms), coalescing intermediate drag events.

## 2. Non-Functional Requirements

- **NFR-PERF-01**: Collinear edge detection must complete in under 5ms for up to 16 managed windows.
- **NFR-CONC-01**: Pure mathematical calculations must be isolated and Sendable; Coordinator must be isolated to `@MainActor`.
