# User Guide: Adaptive Multi-Window Divider Resize

## Introduction
FlowSnap's **Adaptive Multi-Window Divider Resize** allows you to seamlessly resize adjacent snapped windows by simply dragging the shared border between them.

---

## Key Features

### 1. Smart Divider Hover
When you move your mouse cursor over the boundary between two or more adjacent windows, FlowSnap recognizes the shared edge and transforms your cursor into an intuitive resize indicator:
- **Left / Right Split**: Cursor changes to `⬌` (Resize Left/Right).
- **Top / Bottom Split**: Cursor changes to `⬍` (Resize Up/Down).

### 2. Simultaneous Multi-Window Resizing
In complex layouts such as a **T-junction** (e.g. VS Code on the left half, Chrome and Terminal stacked on the right):
- Dragging the central vertical divider resizes VS Code while simultaneously resizing **both** Chrome and Terminal!
- Dragging the horizontal divider between Chrome and Terminal adjusts their relative heights without disturbing VS Code.

### 3. Window Minimum Size Protection
FlowSnap guarantees that dragging a divider will never accidentally collapse or hide a window. Every window maintains its minimum usable size (at least 200px width and 150px height).

### 4. 60fps Smooth Motion
Even on ProMotion 120Hz displays, FlowSnap intelligently throttles system Accessibility calls to maintain fluid 60fps performance without stutter or lag.

---

## Tips & Shortcuts
- **Window Gap Support**: If you configured a window gap in FlowSnap Settings (e.g. 8px), you can click and drag anywhere within the gap between the windows.
- **Cancel Drag**: Pressing `Escape` or releasing outside the screen will cleanly finish the resize interaction.
