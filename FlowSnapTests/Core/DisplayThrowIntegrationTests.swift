import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
@Suite("DisplayThrowIntegrationTests")
struct DisplayThrowIntegrationTests {

    static func makeSimulatedEnvironment(
        displays: [Display],
        mockWindow: ManagedWindow?
    ) -> (CommandDispatcher, MockWindowManaging, MockCursorManager, SnapEngine, DisplayManager) {
        let displayManager = DisplayManager(displayProvider: { displays })
        let registry = WindowRegistry()
        let snapEngine = SnapEngine(windowRegistry: registry, displayManager: displayManager)
        let mockWindowManager = MockWindowManaging(mockFocusedWindow: mockWindow)
        let mockCursorManager = MockCursorManager()
        let navigator = DisplayNavigator()
        let dispatcher = CommandDispatcher(
            windowManager: mockWindowManager,
            snapEngine: snapEngine,
            displayManager: displayManager,
            cursorManager: mockCursorManager,
            displayNavigator: navigator
        )
        return (dispatcher, mockWindowManager, mockCursorManager, snapEngine, displayManager)
    }

    private static func makeDisplays() -> [Display] {
        let d1 = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let d2 = Display(
            id: 2,
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            scaleFactor: 2.0,
            isPrimary: false
        )
        return [d1, d2]
    }

    @Test("TC-015-06: Throwing snapped window preserves semantic snap target on target display")
    func testThrowSnappedWindow() async throws {
        let displays = Self.makeDisplays()
        // Window snapped to left half on primary (0, 0, 720, 900)
        let window = ManagedWindow(
            id: 101,
            pid: 1001,
            title: "Editor",
            frame: CGRect(x: 0, y: 0, width: 720, height: 900),
            kind: .normal
        )

        let (dispatcher, windowManager, cursorManager, _, _) = Self.makeSimulatedEnvironment(
            displays: displays,
            mockWindow: window
        )

        try await dispatcher.dispatch(.moveToNextDisplay)

        #expect(windowManager.moveCallCount == 1)
        #expect(dispatcher.lastExecutedCommand == .moveToNextDisplay)

        guard let moved = windowManager.movedWindows.first else {
            Issue.record("Expected moved window")
            return
        }

        #expect(moved.window.id == 101)
        // Target display is d2 (x: 1440, width: 1920). Left half should be 960 width.
        #expect(moved.frame.width == 960)
        #expect(moved.frame.origin.x == 1440)

        // Cursor should warp to center of new window
        #expect(cursorManager.warpedPoints.count == 1)
        let expectedCenter = CGPoint(x: moved.frame.midX, y: moved.frame.midY)
        #expect(cursorManager.lastWarpedPoint == expectedCenter)
    }

    @Test("TC-015-04 & TC-015-05: Throwing free-floating window scales proportionally and warps cursor")
    func testThrowFreeFloatingWindow() async throws {
        let displays = Self.makeDisplays()
        // Window at (144, 90, 576, 450) [10% X, 10% Y, 40% W, 50% H on 1440x900]
        let window = ManagedWindow(
            id: 102,
            pid: 1002,
            title: "Floating Notes",
            frame: CGRect(x: 144, y: 90, width: 576, height: 450),
            kind: .normal
        )

        let (dispatcher, windowManager, cursorManager, _, _) = Self.makeSimulatedEnvironment(
            displays: displays,
            mockWindow: window
        )

        try await dispatcher.dispatch(.moveToNextDisplay)

        #expect(windowManager.moveCallCount == 1)
        guard let moved = windowManager.movedWindows.first else {
            Issue.record("Expected moved window")
            return
        }

        // On d2 (1440, 0, 1920, 1080), 40% width is 768, 50% height is 540
        #expect(abs(moved.frame.width - 768) < 2)
        #expect(abs(moved.frame.height - 540) < 2)
        #expect(cursorManager.warpedPoints.count == 1)
    }

    @Test("TC-015-03: Cyclic wrap-around from last to first display")
    func testCyclicWrapAround() async throws {
        let displays = Self.makeDisplays()
        // Window located on external display d2
        let window = ManagedWindow(
            id: 103,
            pid: 1003,
            title: "Browser",
            frame: CGRect(x: 1440, y: 0, width: 960, height: 1080),
            kind: .normal
        )

        let (dispatcher, windowManager, _, _, _) = Self.makeSimulatedEnvironment(
            displays: displays,
            mockWindow: window
        )

        try await dispatcher.dispatch(.moveToNextDisplay)

        #expect(windowManager.moveCallCount == 1)
        guard let moved = windowManager.movedWindows.first else {
            Issue.record("Expected moved window")
            return
        }

        // Wrapped around to primary display d1 (x: 0, width: 1440)
        #expect(moved.frame.origin.x == 0)
        #expect(moved.frame.width == 720)
    }

    @Test("TC-015-08: Single display setup is a safe no-op")
    func testSingleDisplayNoOp() async throws {
        let singleDisplay = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let window = ManagedWindow(
            id: 104,
            pid: 1004,
            title: "Terminal",
            frame: CGRect(x: 100, y: 100, width: 600, height: 400),
            kind: .normal
        )

        let (dispatcher, windowManager, cursorManager, _, _) = Self.makeSimulatedEnvironment(
            displays: [singleDisplay],
            mockWindow: window
        )

        try await dispatcher.dispatch(.moveToNextDisplay)

        #expect(windowManager.moveCallCount == 0)
        #expect(cursorManager.warpedPoints.isEmpty)
        #expect(dispatcher.lastExecutedCommand == nil)
    }
}
