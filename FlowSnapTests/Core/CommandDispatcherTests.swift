import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for CommandDispatcher command routing, window guard, and debouncing.
///
/// Traces to: US-SNAP-004.2 & TC-HOTKEY-008..011.
@MainActor
struct CommandDispatcherTests {

    static func makeSimulatedEnvironment(
        mockWindow: ManagedWindow?
    ) -> (CommandDispatcher, MockWindowManaging, SnapEngine, DisplayManager) {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let displayManager = DisplayManager(displayProvider: { [primary] })
        let registry = WindowRegistry()
        let snapEngine = SnapEngine(windowRegistry: registry, displayManager: displayManager)
        let mockWindowManager = MockWindowManaging(mockFocusedWindow: mockWindow)
        let dispatcher = CommandDispatcher(
            windowManager: mockWindowManager,
            snapEngine: snapEngine,
            displayManager: displayManager
        )
        return (dispatcher, mockWindowManager, snapEngine, displayManager)
    }

    @Test func leftHalfSnapDispatchMovesWindow() async throws {
        let window = ManagedWindow(
            id: 101,
            pid: 1234,
            title: "Code Editor",
            frame: CGRect(x: 200, y: 200, width: 800, height: 600),
            kind: .normal
        )
        let (dispatcher, windowManager, _, _) = Self.makeSimulatedEnvironment(mockWindow: window)

        try await dispatcher.dispatch(.snap(.zone(.leftHalf)))

        #expect(windowManager.moveCallCount == 1)
        #expect(dispatcher.lastExecutedCommand == .snap(.zone(.leftHalf)))

        guard let moved = windowManager.movedWindows.first else {
            Issue.record("Expected moved window")
            return
        }

        #expect(moved.window.id == 101)
        // Primary screen: 1440x900
        // Left half AppKit: (0, 0, 720, 900)
        // AX coordinates: (0, 900 - (0 + 900), 720, 900) = (0, 0, 720, 900)
        #expect(moved.frame.origin.x == 0)
        #expect(moved.frame.origin.y == 0)
        #expect(moved.frame.width == 720)
        #expect(moved.frame.height == 900)
    }

    @Test func maximizeAndRestoreDispatch() async throws {
        let initialFrame = CGRect(x: 100, y: 100, width: 500, height: 400)
        let window = ManagedWindow(
            id: 102,
            pid: 1235,
            title: "Browser",
            frame: initialFrame,
            kind: .normal
        )
        let (dispatcher, windowManager, _, _) = Self.makeSimulatedEnvironment(mockWindow: window)

        // 1. Maximize
        try await dispatcher.dispatch(.maximize)
        #expect(windowManager.moveCallCount == 1)
        #expect(dispatcher.lastExecutedCommand == .maximize)

        let maxMoved = windowManager.movedWindows[0]
        #expect(maxMoved.frame == CGRect(x: 0, y: 0, width: 1440, height: 900))

        // Update window's current frame to maximized for next query
        windowManager.mockFocusedWindow = ManagedWindow(
            id: 102,
            pid: 1235,
            title: "Browser",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            kind: .normal
        )

        // 2. Restore
        try await dispatcher.dispatch(.restore)
        #expect(windowManager.moveCallCount == 2)
        #expect(dispatcher.lastExecutedCommand == .restore)

        let restoredMoved = windowManager.movedWindows[1]
        // Restored AX frame should match initialFrame converted to AX:
        // Y_AX = 900 - (100 + 400) = 400
        #expect(restoredMoved.frame == CGRect(x: 100, y: 400, width: 500, height: 400))
    }

    @Test func nilFocusedWindowIsSafeNoOp() async throws {
        let (dispatcher, windowManager, _, _) = Self.makeSimulatedEnvironment(mockWindow: nil)

        try await dispatcher.dispatch(.snap(.zone(.rightHalf)))

        #expect(windowManager.moveCallCount == 0)
        #expect(dispatcher.lastExecutedCommand == nil)
    }

    @Test func debouncingRapidConsecutiveDispatches() async throws {
        let window = ManagedWindow(
            id: 103,
            pid: 1236,
            title: "Terminal",
            frame: CGRect(x: 300, y: 300, width: 600, height: 400),
            kind: .normal
        )
        let (dispatcher, windowManager, _, _) = Self.makeSimulatedEnvironment(mockWindow: window)

        // Fire first dispatch then immediately fire second to debounce the first
        let task1 = Task { @MainActor in
            try await dispatcher.dispatch(.snap(.zone(.leftHalf)))
        }
        let task2 = Task { @MainActor in
            try await dispatcher.dispatch(.snap(.zone(.rightHalf)))
        }

        _ = try await (task1.value, task2.value)

        // Only the final command should be recorded as the active command
        #expect(dispatcher.lastExecutedCommand == .snap(.zone(.rightHalf)))
        #expect(windowManager.moveCallCount >= 1)
    }
}
