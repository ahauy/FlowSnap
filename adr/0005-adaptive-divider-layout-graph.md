# ADR 0005: Spatial Constraint Graph & Collinear Edge Detection for Multi-Window Resizing

## Status
Accepted

## Date
2026-08-30

## Context
When multiple windows are tiled in a layout (2-column, 3-column, T-junction, 2x2 grid), resizing a single window leaves gaps or breaks layout coherence. We need a unified spatial model to detect shared collinear boundaries across multiple adjacent windows and resize them simultaneously in real time.

## Decision
1. **Collinear Edge Representation (`CollinearEdge`)**:
   - Model shared boundaries as continuous orthogonal line segments (`CollinearEdge`) containing union spans of adjacent windows.
   - Separate orientation into `DividerOrientation.vertical` and `DividerOrientation.horizontal`.
2. **Pure Geometric Detector (`CollinearEdgeDetector`)**:
   - Implement collinear edge grouping, hit tolerance ($\pm 6	ext{pt}$), and minSize boundary clamping as pure functional calculations with zero system dependencies.
3. **60fps Throttling Policy (`LiveResizeThrottler`)**:
   - Paces AXUIElement calls at $\le 60	ext{fps}$ (~16.6ms) during high-frequency mouse drag events to avoid overloading WindowServer IPC.

## Consequences
- **Positive**: Clean separation of geometric math from OS window manipulation. Zero AX dependencies in layout graph calculations. Simultaneous resizing of multiple windows in T-junctions works flawlessly.
- **Negative**: High-speed mouse drags across screen bounds must clamp gracefully at display edges and minSize boundaries.
