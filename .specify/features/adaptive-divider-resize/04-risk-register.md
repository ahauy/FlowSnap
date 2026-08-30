# Risk Register & Contradiction Scan: US-SNAP-009

## 1. Risk Matrix

| Risk ID | Description | Severity | Likelihood | Mitigation Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **RISK-ADR-01** | WindowServer IPC bottleneck causing stutter during live AX dragging | High | High | Dedicated `LiveResizeThrottler` enforcing 60fps (~16.6ms) throttle interval and dropping stale intermediate frames. |
| **RISK-ADR-02** | Rapid mouse movement collapsing windows into zero or negative width/height | High | Medium | Hard boundary clamping (`minCoordinate` / `maxCoordinate`) calculated before applying deltas. |
| **RISK-ADR-03** | Cursor flicker when mouse moves rapidly near the divider boundary | Medium | Medium | 6pt hit-test tolerance margin with hysteresis buffer. |
| **RISK-ADR-04** | Complex T-junction layouts miscalculating orthogonal spans | Medium | Low | Comprehensive unit tests covering 2-window, 3-window (T-junction), and 4-window cross layouts. |
| **RISK-ADR-05** | Conflict between DragToSnap and AdaptiveDivider | Medium | Low | Clear state isolation: Drag-to-snap requires dragging a window titlebar; AdaptiveDivider triggers only on divider gaps. |

## 2. MoSCoW Scope Lock

- **Must Have:**
  - `LayoutGraph` & `LayoutNode` spatial partitioning representations.
  - `CollinearEdgeDetector` with 2-window, 3-window T-junction, and 4-window cross support.
  - Live resize coordinate calculation with strict `minSize` clamping.
  - `LiveResizeThrottler` pacing frame dispatches at 60fps.
  - Cursor switching (`NSCursor.resizeLeftRight`, `NSCursor.resizeUpDown`, `NSCursor.arrow`).
  - Unit tests with 100% pass rate.
- **Should Have:**
  - Smooth integration with `PreferencesStore.windowGap`.
- **Could Have:**
  - Visual divider guide overlay highlight (HUD line).
- **Won't Have (v1):**
  - Saving custom divider ratios across system reboots / workspaces persistence.
