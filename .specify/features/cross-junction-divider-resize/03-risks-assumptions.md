# Risk & Contradiction Scan: Multi-Window T-Junction & Crosshair Divider Resize

- **Feature**: `cross-junction-divider-resize`
- **Protocol**: Bounded Task

---

## 1. Risk Register

| Risk ID        | Description                                                                                | Severity | Likelihood | Mitigation Strategy                                                                                             |
| -------------- | ------------------------------------------------------------------------------------------ | -------- | ---------- | --------------------------------------------------------------------------------------------------------------- |
| `RISK-CJR-001` | Cursor / overlay flickering between 1D edge divider and 2D crosshair handle near boundary. | Medium   | Medium     | Hysteresis: activate junction mode at $\le 14\,\text{pt}$, deactivate at $> 17\,\text{pt}$ to prevent jitter.   |
| `RISK-CJR-002` | IPC performance bottlenecks when moving 3–4 windows simultaneously across 2 axes at 120Hz. | High     | Medium     | AXUIElement reference caching on mouseDown + drag event coalescing (`scheduleDragTask`).                        |
| `RISK-CJR-003` | OS window minSize deadlock when dragging diagonally into a boundary.                       | Medium   | Low        | Decoupled per-axis clamping: stop moving along clamped axis while allowing free movement along orthogonal axis. |

---

## 2. Scope Matrix (MoSCoW)

- **Must-Have**:
  - `CrossJunction` model detection for 3-window T-junctions and 4-window cross junctions.
  - Crosshair cursor (`NSCursor.crosshair`) and illuminated junction pill handle on hover.
  - Simultaneous 2D resize of 3 or 4 participating windows on drag.
  - Decoupled per-axis clamping for window `minSize`.
  - Escape key cancellation restoring original frames.
- **Won't-Have**:
  - Resizing un-tiled / overlapping floating windows.
  - Custom user-drawn multi-point polygon layouts.
