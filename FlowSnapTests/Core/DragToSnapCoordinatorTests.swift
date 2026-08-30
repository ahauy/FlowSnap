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
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()
        #expect(mouseTracker.isTracking == true)

        // Drag to left outer edge (x: 2, y: 540)
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))

        #expect(coordinator.currentCandidateZone == .left)
        #expect(previewManager.showPreviewCallCount == 0) // Not yet expired (50ms dwell)

        // Wait for 50ms dwell timeout (+ buffer)
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(previewManager.showPreviewCallCount == 1)
        #expect(previewManager.lastShownFrame == LayoutEngine().frame(for: .leftHalf, in: primaryDisplay.visibleFrame, gap: 0))
        #expect(coordinator.activeDetectionResult?.target == .left)

        coordinator.stop()
        #expect(mouseTracker.isTracking == false)
    }

    @Test func adjacentEdgeRequiresHigherDwellTimeout() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay, secondaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to right edge of primary display (x: 1918) which is adjacent to secondary
        await coordinator.handleDrag(at: CGPoint(x: 1918, y: 540))

        // Wait 70ms (which would have fired on outer edge, but NOT on adjacent edge)
        try await Task.sleep(nanoseconds: 70_000_000)
        #expect(previewManager.showPreviewCallCount == 0) // Still waiting for 150ms dwell!

        // Wait remaining time for 150ms dwell (+ buffer)
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(previewManager.showPreviewCallCount == 1)
        #expect(coordinator.activeDetectionResult?.isAdjacentEdge == true)

        coordinator.stop()
    }

    // MARK: - TC-DRAG-006: Release to Snap

    @Test func mouseReleaseAppliesSnapAndDismissesPreview() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to top edge (Maximize - outside top-center)
        await coordinator.handleDrag(at: CGPoint(x: 400, y: 1078))
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(previewManager.showPreviewCallCount == 1)

        // Release mouse
        await coordinator.handleRelease(at: CGPoint(x: 400, y: 1078))

        // Check preview dismissal and flash
        #expect(previewManager.hidePreviewCallCount == 1)
        #expect(previewManager.flashSnapSuccessCallCount == 1)

        #expect(commandDispatcher.dispatchCallCount == 1)
        #expect(commandDispatcher.dispatchedCommands.first == .snap(.maximize, targetDisplayID: primaryDisplay.id))

        coordinator.stop()
    }

    // MARK: - TC-DRAG-007: Move Away Cancellation

    @Test func movingAwayFromEdgeCancelsDwellAndHidesPreview() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to left edge and let preview show
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))
        try await Task.sleep(nanoseconds: 200_000_000)
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
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: false)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))
        try await Task.sleep(nanoseconds: 70_000_000)

        #expect(previewManager.showPreviewCallCount == 0)
        #expect(coordinator.currentCandidateZone == nil)

        coordinator.stop()
    }

    // MARK: - Top-Edge Snap Layout Picker Tests (US-SNAP-007)

    @Test func dragIntoTopCenterSummonsLayoutPicker() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // Drag to top-center zone (x: 960 is 50% width, y: 1078 is top edge)
        await coordinator.handleDrag(at: CGPoint(x: 960, y: 1078))

        #expect(layoutPickerManager.showPickerCallCount == 1)
        #expect(layoutPickerManager.isVisible == true)
        #expect(previewManager.showPreviewCallCount == 1)

        coordinator.stop()
        #expect(layoutPickerManager.hidePickerCallCount == 1)
    }

    @Test func releaseInsidePickerSlotSnapsWindow() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // 1. Drag into top-center to summon picker
        await coordinator.handleDrag(at: CGPoint(x: 960, y: 1078))
        #expect(layoutPickerManager.isVisible == true)

        // 2. Hover over slot (simulate hover on Left 70% slot)
        let slot = LayoutSlot(
            id: "twoColAsym-left",
            title: "Left (70%)",
            target: .leftTwoThirds,
            normalizedRect: CGRect(x: 0, y: 0, width: 0.7, height: 1.0)
        )
        layoutPickerManager.mockedSlotToReturn = slot

        // Drag point inside picker frame
        await coordinator.handleDrag(at: CGPoint(x: 800, y: 980))
        #expect(coordinator.currentCandidateZone == .leftTwoThirds)

        // 3. Release mouse inside the slot
        await coordinator.handleRelease(at: CGPoint(x: 800, y: 980))

        #expect(layoutPickerManager.hidePickerCallCount == 1)
        #expect(previewManager.flashSnapSuccessCallCount == 1)
        #expect(commandDispatcher.dispatchCallCount == 1)
        #expect(commandDispatcher.dispatchedCommands.first == .snap(.leftTwoThirds, targetDisplayID: primaryDisplay.id))

        coordinator.stop()
    }

    @Test func moveAwayFromPickerDismissesSmoothly() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager(pickerFrame: CGRect(x: 745, y: 955, width: 430, height: 92))
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService
        )

        coordinator.start()

        // 1. Open picker at top center
        await coordinator.handleDrag(at: CGPoint(x: 960, y: 1078))
        #expect(layoutPickerManager.isVisible == true)

        // 2. Move cursor downwards away from picker (y: 800 is below pickerFrame.minY 955)
        await coordinator.handleDrag(at: CGPoint(x: 960, y: 800))

        #expect(layoutPickerManager.hidePickerCallCount == 1)
        #expect(previewManager.hidePreviewCallCount >= 1)

        coordinator.stop()
    }

    @Test func dragPreviewRespectsPreferencesStoreRatioAndGap() async throws {
        let mouseTracker = MockMouseDragTracker()
        let previewManager = MockSnapPreviewManager()
        let layoutPickerManager = MockSnapLayoutPickerManager()
        let commandDispatcher = MockCommandDispatcher()
        let displayManager = MockDisplayManager(displays: [primaryDisplay])
        let accessibilityService = MockAccessibilityService(isTrusted: true)

        let defaults = UserDefaults(suiteName: "test-drag-coord-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(8)
        store.setDefaultRatio(.sixtyForty)

        let coordinator = DragToSnapCoordinator(
            mouseTracker: mouseTracker,
            detector: SnapDetector(edgeThreshold: 20),
            previewManager: previewManager,
            layoutPickerManager: layoutPickerManager,
            commandDispatcher: commandDispatcher,
            displayManager: displayManager,
            accessibilityService: accessibilityService,
            preferencesStore: store
        )

        coordinator.start()

        // Drag to left outer edge
        await coordinator.handleDrag(at: CGPoint(x: 2, y: 540))
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(previewManager.showPreviewCallCount == 1)
        let expectedFrame = LayoutEngine().frame(for: .left60_40, in: primaryDisplay.visibleFrame, gap: 8, uniform: true)
        #expect(previewManager.lastShownFrame == expectedFrame)

        coordinator.stop()
    }
}
