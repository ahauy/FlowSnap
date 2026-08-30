# Test Plan: US-SNAP-009 Adaptive Multi-Window Divider Resize

| Test Case ID | Target Component | Scenario | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **TC-ADR-001** | `LayoutGraph` | BSP tree construction and leaf node evaluation | Correct frame mapping for all leaves |
| **TC-ADR-002** | `CollinearEdgeDetector` | 2-window vertical split detection | 1 vertical `CollinearEdge` detected at partition boundary |
| **TC-ADR-003** | `CollinearEdgeDetector` | 2-window horizontal split detection | 1 horizontal `CollinearEdge` detected at partition boundary |
| **TC-ADR-004** | `CollinearEdgeDetector` | 3-window T-junction layout | 1 vertical full-height edge with 2 trailing windows, 1 horizontal right-only edge |
| **TC-ADR-005** | `CollinearEdgeDetector` | 4-window 2x2 cross junction | 1 vertical full-height edge and 1 horizontal full-width edge |
| **TC-ADR-006** | `CollinearEdgeDetector` | Hit tolerance testing | Points within +-6pt hit divider; outside points return nil |
| **TC-ADR-007** | `CollinearEdgeDetector` | Clamped frame calculation with minSize | Frame clamping prevents windows from shrinking below minSize |
| **TC-ADR-008** | `LiveResizeThrottler` | High frequency event processing | Limits execution to 60fps (16.6ms intervals) |
| **TC-ADR-009** | `AdaptiveDividerCoordinator` | Hover cursor switching | Changes cursor to resize cursor on hover, arrow on exit |
| **TC-ADR-010** | `AdaptiveDividerCoordinator` | Live drag simultaneous multi-window resize | Dispatches updated frames to WindowManager for all collinear windows |
