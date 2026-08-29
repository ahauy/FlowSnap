import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
struct DragToSnapCoordinatorTests {

    let primaryDisplay = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 25, width: 1920, height: 1055),
        scaleFactor: 2.0,
        isPrimary: true
    )

    let secondaryDisplay = Display(
        id: 2,
        frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
        scaleFactor: 2.0,
        isPrimary: false
    )

    // MARK: - TC-DRAG-005: Dwell Timer State Machine

    @Test func outerEdgeDwellTimerTriggersPreview() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 4),
            previewManager: previewManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()
        #expect(mouseTracker.isTracking == true)

        // Drag to left outer edge (x: 2, y: 540)
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))

        #expect(coordinator.currentCandidateZone == .left)
        #expect(previewManager.showPreviewCallCount == 0) // Not yet expired (100ms dwell)

        // Wait for 100ms dwell timeout (+ buffer)
        try await Task.sleep(nanoseconds: 130_000_000)

        #expect(previewManager.showPreviewCallCount == 1)
        #expect(previewManager.lastShownFrame == LayoutEngine().frame(for: .leftHalf, in: primaryDisplay.visibleFrame))
        #expect(coordinator.activeDetectionResult?.target == .left)

        coordinator.stop()
        #expect(mouseTracker.isTracking == false)
    }

    @Test func adjacentEdgeRequiresHigherDwellTimeout() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay, secondaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 4),
            previewManager: previewManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to right edge of primary display (x: 1918) which is adjacent to secondary
        await coordinator.handleDrag(at: CGPoint(x: 1918, y: 540))

        // Wait 120ms (which would have fired on outer edge, but NOT on adjacent edge)
        try await Task.sleep(nanoseconds: 120_000_000)
        #expect(previewManager.showPreviewCallCount == 0) // Still waiting for 250ms dwell!

        // Wait remaining time for 250ms dwell (+ buffer)
        try await Task.sleep(nanoseconds: 160_000_000)
        #expect(previewManager.showPreviewCallCount == 1)
        #expect(coordinator.activeDetectionResult?.isAdjacentEdge == true)

        coordinator.stop()
    }

    // MARK: - TC-DRAG-006: Release to Snap

    @Test func mouseReleaseAppliesSnapAndDismissesPreview() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 4),
            previewManager: previewManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to top edge (Maximize)
        await coordinator.handleDrag(at: CGPoint(x: 960, y: 1078))
        try await Task.sleep(nanoseconds: 130_000_000)
        #expect(previewManager.showPreviewCallCount == 1)

        // Release mouse
        await coordinator.handleRelease(at: CGPoint(x: 960, y: 1078))

        // Check preview dismissal and flash
        #expect(previewManager.hidePreviewCallCount == 1)
        #expect(previewManager.flashSnapSuccessCallCount == 1)

        #expect(commandDispatcher.dispatchCallCount == 1)
        #expect(commandDispatcher.dispatchedCommands.first == .snap(.maximize))

        coordinator.stop()
    }

    // MARK: - TC-DRAG-007: Move Away Cancellation

    @Test func movingAwayFromEdgeCancelsDwellAndHidesPreview() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 4),
            previewManager: previewManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to left edge and let preview show
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))
        try await Task.sleep(nanoseconds: 130_000_000)
        #expect(previewManager.showPreviewCallCount == 1)

        // Move cursor away into center (x: 960, y: 540)
        await coordinator.handleDrag(at: CGPoint(x: 960, y: 540))

        #expect(coordinator.currentCandidateZone == nil)
        #expect(coordinator.activeDetectionResult == nil)
        #expect(previewManager.hidePreviewCallCount == 1)

        coordinator.stop()
    }

    @Test func untrustedAccessibilityIgnoresDrag() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: false)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 4),
            previewManager: previewManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))
        try await Task.sleep(nanoseconds: 130_000_000)

        #expect(previewManager.showPreviewCallCount == 0)
        #expect(coordinator.currentCandidateZone == nil)

        coordinator.stop()
    }
}
