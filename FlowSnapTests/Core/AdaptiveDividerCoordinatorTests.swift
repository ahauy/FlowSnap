import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
final class MockAdaptiveDividerOverlayManager: AdaptiveDividerOverlayManaging {
    var isOverlayVisible: Bool = false
    var showCallCount: Int = 0
    var updateCallCount: Int = 0
    var hideCallCount: Int = 0
    var lastContainerFrame: CGRect?
    var lastWindows: [ManagedWindow] = []
    var lastDividers: [CollinearEdge] = []
    var lastActiveDivider: CollinearEdge?
    var lastIsDragging: Bool?

    func show(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        isDragging: Bool
    ) {
        showCallCount += 1
        isOverlayVisible = true
        lastContainerFrame = containerFrame
        lastWindows = windows
        lastDividers = dividers
        lastActiveDivider = activeDivider
        lastIsDragging = isDragging
    }

    func update(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        isDragging: Bool
    ) {
        updateCallCount += 1
        lastContainerFrame = containerFrame
        lastWindows = windows
        lastDividers = dividers
        lastActiveDivider = activeDivider
        lastIsDragging = isDragging
    }

    func hide(animated: Bool) {
        hideCallCount += 1
        isOverlayVisible = false
    }
}

@MainActor
@Suite("AdaptiveDividerCoordinator Tests")
struct AdaptiveDividerCoordinatorTests {

    let displayBounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

    private func makeSUT(
        overlayManager: AdaptiveDividerOverlayManaging? = nil
    ) -> (AdaptiveDividerCoordinator, MockWindowManaging, MockDisplayManager, MockAdaptiveDividerOverlayManager?) {
        let mockWM = MockWindowManaging()
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let mockOverlay = (overlayManager as? MockAdaptiveDividerOverlayManager) ?? MockAdaptiveDividerOverlayManager()
        let coordinator = AdaptiveDividerCoordinator(
            detector: CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150),
            windowManager: mockWM,
            displayManager: mockDM,
            throttler: LiveResizeThrottler(fps: 1000.0), // high fps for instant test execution
            overlayManager: mockOverlay
        )
        return (coordinator, mockWM, mockDM, mockOverlay)
    }

    @Test("Hover over vertical divider changes cursor to resizeLeftRight and reveals overlay with persistent resting state")
    func hoverOverVerticalDividerChangesCursor() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        // Hover directly on divider X=720
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.hoveredDivider?.orientation == .vertical)
        #expect(sut.currentCursor == .resizeLeftRight)
        #expect(mockOverlay?.showCallCount == 1)
        #expect(mockOverlay?.isOverlayVisible == true)
        #expect(mockOverlay?.lastActiveDivider?.orientation == .vertical)

        // Move away within the same display (transitions to resting outline with activeDivider == nil)
        await sut.handleMouseMoved(to: CGPoint(x: 200, y: 450))
        #expect(sut.hoveredDivider == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(mockOverlay?.showCallCount == 2)
        #expect(mockOverlay?.isOverlayVisible == true)
        #expect(mockOverlay?.lastActiveDivider == nil)
    }

    @Test("Hover over horizontal divider changes cursor to resizeUpDown")
    func hoverOverHorizontalDividerChangesCursor() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Bottom", frame: CGRect(x: 0, y: 0, width: 1440, height: 450))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Top", frame: CGRect(x: 0, y: 450, width: 1440, height: 450))
        sut.updateWindows([w1, w2])

        await sut.handleMouseMoved(to: CGPoint(x: 500, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.hoveredDivider?.orientation == .horizontal)
        #expect(sut.currentCursor == .resizeUpDown)
        #expect(mockOverlay?.showCallCount == 1)
    }

    @Test("MouseDown on divider captures active divider and begins resizing")
    func mouseDownCapturesActiveDivider() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        let hit = await sut.handleMouseDown(at: CGPoint(x: 721, y: 300))
        #expect(hit == true)
        #expect(sut.isResizing == true)
        #expect(sut.activeDivider != nil)
        #expect(mockOverlay?.lastIsDragging == true)

        let miss = await sut.handleMouseDown(at: CGPoint(x: 100, y: 100))
        #expect(miss == false)
    }

    @Test("MouseDrag dispatches simultaneous resize to WindowManager and updates overlay")
    func mouseDragResizesCollinearWindows() async {
        let (sut, mockWM, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 10, pid: 1, title: "VSCode", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 20, pid: 2, title: "Chrome", frame: CGRect(x: 720, y: 450, width: 720, height: 450))
        let w3 = ManagedWindow(id: 30, pid: 3, title: "Terminal", frame: CGRect(x: 720, y: 0, width: 720, height: 450))
        sut.updateWindows([w1, w2, w3])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 300))
        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 300))

        #expect(mockWM.moveCallCount >= 3)
        #expect(sut.managedWindows.first { $0.id == 10 }?.frame.width == 800)
        #expect(sut.managedWindows.first { $0.id == 20 }?.frame.origin.x == 800)
        #expect(sut.managedWindows.first { $0.id == 20 }?.frame.width == 640)
        #expect(sut.managedWindows.first { $0.id == 30 }?.frame.origin.x == 800)
        #expect(sut.managedWindows.first { $0.id == 30 }?.frame.width == 640)
        #expect(mockOverlay?.updateCallCount ?? 0 >= 1)
        #expect(mockOverlay?.lastIsDragging == true)

        // Mouse up ends session and restores resting outline
        await sut.handleMouseUp(at: CGPoint(x: 800, y: 300))
        #expect(sut.isResizing == false)
        #expect(sut.activeDivider == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(mockOverlay?.lastActiveDivider == nil)
    }

    @Test("Real-time overlay updates during drag while window moves are throttled, followed by atomic final snap on mouseUp")
    func realTimeOverlayWithThrottledWindowUpdatesAndAtomicSnapOnMouseUp() async {
        let mockWM = MockWindowManaging()
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let mockOverlay = MockAdaptiveDividerOverlayManager()

        final class ControlledThrottler: LiveResizeThrottling, @unchecked Sendable {
            var allow: Bool = false
            func shouldProcess(timestamp: TimeInterval) -> Bool { allow }
            func reset() {}
        }
        let controlledThrottler = ControlledThrottler()

        let coordinator = AdaptiveDividerCoordinator(
            detector: CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150),
            windowManager: mockWM,
            displayManager: mockDM,
            throttler: controlledThrottler,
            overlayManager: mockOverlay
        )

        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        coordinator.updateWindows([w1, w2])

        // 1. Mouse down on divider X=720
        _ = await coordinator.handleMouseDown(at: CGPoint(x: 720, y: 450))
        #expect(coordinator.isResizing == true)

        // 2. Drag to X=850 with throttling active (allow = false)
        controlledThrottler.allow = false
        await coordinator.handleMouseDragged(to: CGPoint(x: 850, y: 450))

        // Visual overlay MUST update in real-time (120Hz ProMotion)
        #expect(mockOverlay.updateCallCount == 1)
        #expect(mockOverlay.lastWindows.first { $0.id == 1 }?.frame.width == 850)
        #expect(mockOverlay.lastWindows.first { $0.id == 2 }?.frame.origin.x == 850)
        #expect(mockOverlay.lastWindows.first { $0.id == 2 }?.frame.width == 590)

        // WindowManager move MUST NOT have been called due to throttling
        #expect(mockWM.moveCallCount == 0)

        // 3. Mouse up at final release position X=850
        await coordinator.handleMouseUp(at: CGPoint(x: 850, y: 450))

        // Atomic final snap MUST execute on WindowManager to guarantee 100% exact alignment
        #expect(mockWM.moveCallCount == 2)
        #expect(coordinator.managedWindows.first { $0.id == 1 }?.frame.width == 850)
        #expect(coordinator.managedWindows.first { $0.id == 2 }?.frame.origin.x == 850)
        #expect(coordinator.managedWindows.first { $0.id == 2 }?.frame.width == 590)
        #expect(coordinator.isResizing == false)
    }
}
