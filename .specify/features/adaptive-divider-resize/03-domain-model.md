# Domain Model: US-SNAP-009 Adaptive Multi-Window Divider Resize

## 1. Domain Entities & Value Objects

```mermaid
classDiagram
    class DividerOrientation {
        <<enumeration>>
        vertical
        horizontal
    }

    class CollinearEdge {
        +UUID id
        +DividerOrientation orientation
        +CGFloat coordinate
        +ClosedRange<CGFloat> span
        +CGRect hitRect
        +[CGWindowID] leadingWindowIDs
        +[CGWindowID] trailingWindowIDs
        +CGFloat minCoordinate
        +CGFloat maxCoordinate
        +contains(CGPoint point) bool
    }

    class LayoutNode {
        <<enum / struct>>
        +leaf(CGWindowID, CGRect, CGSize?)
        +split(SplitAxis, CGFloat, CGFloat, LayoutNode, LayoutNode)
        +computeFrames(CGRect) Dictionary
        +allLeaves() List
    }

    class LayoutGraph {
        +LayoutNode root
        +List<CollinearEdge> dividers
        +detectDividers(CGFloat) List<CollinearEdge>
        +divider(at: CGPoint, tolerance: CGFloat) CollinearEdge?
        +applyResize(CollinearEdge, CGFloat) LayoutGraph
    }

    class LiveResizeThrottler {
        <<actor / helper>>
        +TimeInterval minInterval
        +shouldProcess(TimeInterval) bool
        +submit(ResizedFrames) async
    }

    class AdaptiveDividerCoordinator {
        <<@MainActor>>
        +updateWindows(List<ManagedWindow>)
        +handleMouseMoved(CGPoint)
        +handleMouseDown(CGPoint)
        +handleMouseDragged(CGPoint)
        +handleMouseUp(CGPoint)
    }

    LayoutGraph --> LayoutNode : contains
    LayoutGraph --> CollinearEdge : detects
    AdaptiveDividerCoordinator --> CollinearEdge : tracks active
    AdaptiveDividerCoordinator --> LiveResizeThrottler : throttles with
```

## 2. Finite State Machine: Adaptive Divider Resize Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Idle

    Idle --> HoveringDivider : Mouse enters divider tolerance (+-6pt)
    HoveringDivider --> Idle : Mouse leaves divider tolerance / resets NSCursor.arrow
    HoveringDivider --> Resizing : Mouse Down on shared divider / capture initial bounds
    
    Resizing --> Resizing : Mouse Dragged / throttled 60fps frame update
    Resizing --> Idle : Mouse Up / commit final frames, reset NSCursor.arrow
```

## 3. Business Rules (BR-)

```
BR-ADR-001 (Collinear Alignment): Windows are collinear along an edge if their bounding coordinates along that axis match within the gap tolerance (+- 2px) and their orthogonal spans overlap by >= 10 points.

BR-ADR-002 (Composite Divider Union): If multiple adjacent windows share the same boundary line (e.g. left window vs top-right & bottom-right windows), they are united into a single CollinearEdge with span equal to the union of overlapping spans.

BR-ADR-003 (Cursor Affordance): Hovering within the hit tolerance (+- 6 points) of a vertical divider displays NSCursor.resizeLeftRight. Hovering within the hit tolerance of a horizontal divider displays NSCursor.resizeUpDown.

BR-ADR-004 (MinSize Boundary Preservation): The divider coordinate CANNOT be moved past the point where any leading window width/height < minSize or any trailing window width/height < minSize (default minWidth=200, minHeight=150).

BR-ADR-005 (60fps Throttled Dispatch): Drag updates MUST be throttled to 60fps (minimum 16.6ms between AXUIElement positioning calls) to prevent UI thread lockups and WindowServer starvation.

BR-ADR-006 (Zero Floating-Point Gap Drift): During resizing, the total width/height of the container minus gaps MUST equal the sum of resized window dimensions at every step.
```
