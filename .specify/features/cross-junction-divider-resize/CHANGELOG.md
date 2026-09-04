# Changelog: Multi-Window T-Junction & Crosshair Divider Resize

## [1.0.0] - 2026-09-04

### Added

- **CrossJunction Domain Model**: Added [`CrossJunction`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Domain/Layout/CrossJunction.swift) representing intersection points between orthogonal collinear dividers with a circular $14\,\text{pt}$ hit radius.
- **2D Geometry Detection & Clamping**: Added `detectJunctions`, `hitTestJunction`, and `compute2DResizedFrames` in [`CollinearEdgeDetector`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/CollinearEdgeDetector.swift) with decoupled per-axis clamping to avoid axis lockup.
- **Overlay Junction Affordance**: Extended [`AdaptiveDividerOverlayPanel`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/UI/Divider/AdaptiveDividerOverlayPanel.swift) to render a glowing accent halo and crisp white dot handle at intersection points.
- **Coordinator Drag & Cursor Switching**: Integrated `NSCursor.crosshair`, 2D live mouse dragging, and atomic cancellation in [`AdaptiveDividerCoordinator`](file:///Users/vutuanhau/Documents/PROJECT/FlowSnap/FlowSnap/Core/Layout/AdaptiveDividerCoordinator.swift).
- **Test Suite**: Added 16 geometry tests in `CollinearEdgeDetectorTests` and 3 coordinator integration tests in `AdaptiveDividerCoordinatorTests`.
- **Documentation**: Added technical docs at `docs/features/cross-junction-divider-resize/README.md`, user guide at `docs/user-guides/cross-junction-divider-resize.md`, updated `docs/PRODUCT_BACKLOG_ROADMAP.md` with `US-SNAP-023`, and synced `CONTEXT.md`.
