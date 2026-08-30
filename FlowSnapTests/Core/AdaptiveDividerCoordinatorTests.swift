import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
@Suite("AdaptiveDividerCoordinator Tests")
struct AdaptiveDividerCoordinatorTests {

    let displayBounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

    private func makeSUT() -> (AdaptiveDividerCoordinator, MockWindowManaging, MockDisplayManager) {
        let mockWM = MockWindowManaging()
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let coordinator = AdaptiveDividerCoordinator(
            detector: CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150),
            windowManager: mockWM,
            displayManager: mockDM,
            throttler: LiveResizeThrottler(fps: 1000.0) // high fps for instant test execution
        )
        return (coordinator, mockWM, mockDM)
    }

    @Test("Hover over vertical divider changes cursor to resizeLeftRight")
    func hoverOverVerticalDividerChangesCursor() async {
        let (sut, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        // Hover directly on divider X=720
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.hoveredDivider?.orientation == .vertical)
        #expect(sut.currentCursor == .resizeLeftRight)

        // Move away
        await sut.handleMouseMoved(to: CGPoint(x: 200, y: 450))
        #expect(sut.hoveredDivider == nil)
        #expect(sut.currentCursor == .arrow)
    }

    @Test("Hover over horizontal divider changes cursor to resizeUpDown")
    func hoverOverHorizontalDividerChangesCursor() async {
        let (sut, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Bottom", frame: CGRect(x: 0, y: 0, width: 1440, height: 450))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Top", frame: CGRect(x: 0, y: 450, width: 1440, height: 450))
        sut.updateWindows([w1, w2])

        await sut.handleMouseMoved(to: CGPoint(x: 500, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.hoveredDivider?.orientation == .horizontal)
        #expect(sut.currentCursor == .resizeUpDown)
    }

    @Test("MouseDown on divider captures active divider and begins resizing")
    func mouseDownCapturesActiveDivider() async {
        let (sut, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        let hit = await sut.handleMouseDown(at: CGPoint(x: 721, y: 300))
        #expect(hit == true)
        #expect(sut.isResizing == true)
        #expect(sut.activeDivider != nil)

        let miss = await sut.handleMouseDown(at: CGPoint(x: 100, y: 100))
        #expect(miss == false)
    }

    @Test("MouseDrag dispatches simultaneous resize to WindowManager")
    func mouseDragResizesCollinearWindows() async {
        let (sut, mockWM, _) = makeSUT()
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

        // Mouse up ends session
        await sut.handleMouseUp(at: CGPoint(x: 800, y: 300))
        #expect(sut.isResizing == false)
        #expect(sut.activeDivider == nil)
        #expect(sut.currentCursor == .arrow)
    }
}
