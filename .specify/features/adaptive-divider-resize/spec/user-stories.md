# User Stories: US-SNAP-009 Adaptive Multi-Window Divider Resize

## US-SNAP-009: Adaptive Multi-Window Divider Resize

### Scenario 1: 2-Window Left/Right Split Resizing
- **Given**: Two windows snapped to left and right halves with an 8px window gap.
- **When**: The user hovers the cursor over the vertical divider between them.
- **Then**: The cursor changes to `NSCursor.resizeLeftRight`.
- **When**: The user drags the divider 100px to the right.
- **Then**: The left window expands by 100px and the right window shrinks by 100px, maintaining the 8px gap.

### Scenario 2: 3-Window T-Junction Resizing
- **Given**: Window 1 occupies the left half (full height), Window 2 occupies the top-right quarter, and Window 3 occupies the bottom-right quarter.
- **When**: The user drags the main vertical divider 80px to the right.
- **Then**: Window 1 width increases by 80px, and both Window 2 and Window 3 decrease in width by 80px and shift right by 80px simultaneously.
- **When**: The user drags the horizontal divider between Window 2 and Window 3 downwards by 50px.
- **Then**: Window 2 height increases by 50px, Window 3 height decreases by 50px, and Window 1 remains completely unaffected.

### Scenario 3: MinSize Clamping Protection
- **Given**: A window on the right with a minimum width of 200px and current width of 250px.
- **When**: The user attempts to drag the vertical divider 150px to the right.
- **Then**: The divider movement is clamped at +50px, preventing the right window from shrinking below 200px.
