# Changelog: US-SNAP-006 (drag-to-snap-preview)

## [1.0.0] - 2026-08-29

- **Intake & Elicitation**: Completed BA stage 1 & 2 interview with signed-off domain baseline.
- **Architecture Planning**: Formulated Speckit `spec.md`, `plan.md`, `data-model.md`, `contracts/`, and `tasks.md`.
- **Domain & Core**: Implemented `SnapDetector` pure geometry engine supporting 8 canonical snap zones and multi-monitor adjacent border detection.
- **Infrastructure**: Implemented `MouseDragTracker` using `NSEvent.addGlobalMonitorForEvents` with 60fps (~16ms) throttling.
- **UI Layer**: Upgraded `SnapPreviewPanel` and `SnapPreviewView` to non-activating Liquid Glass HUD overlay with 10px corner radius, 1.5px accent stroke, and 150ms fade transitions.
- **Coordinator**: Implemented `DragToSnapCoordinator` managing dwell timer state machine (100ms outer vs 250ms internal adjacent) and release-to-snap execution.
- **Verification**: 78/78 tests passing across 18 test suites with rendered user guide screenshots.
