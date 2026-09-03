import ApplicationServices
import CoreGraphics
import Testing
@testable import FlowSnap

@Suite("WindowManager Tests")
@MainActor
struct WindowManagerTests {

    private func makeManagedWindow(
        id: CGWindowID = 101,
        pid: pid_t = 9999,
        kind: WindowKind = .normal,
        isMinimized: Bool = false
    ) -> ManagedWindow {
        ManagedWindow(
            id: id,
            pid: pid,
            bundleIdentifier: "com.example.app",
            title: "Test Window",
            frame: CGRect(x: 0, y: 0, width: 800, height: 600),
            isMinimized: isMinimized,
            isResizable: true,
            kind: kind
        )
    }

    @Test("TC-FSE-006: WindowManager Reposition with Fullscreen Escape")
    func testMoveFullScreenWindowTriggersEscapeCoordinator() async throws {
        let mockAccessibility = MockAccessibilityService(isTrusted: true)
        let mockCoordinator = MockFullScreenEscapeCoordinator()
        let windowManager = WindowManager(
            accessibilityService: mockAccessibility,
            fullScreenEscapeCoordinator: mockCoordinator
        )

        let dummyElement = AXUIElementCreateSystemWide()
        let fullscreenWindow = makeManagedWindow(kind: .fullscreen)
        let targetFrame = CGRect(x: 100, y: 100, width: 600, height: 400)

        try await windowManager.move(fullscreenWindow, to: targetFrame, element: dummyElement)

        #expect(mockCoordinator.callCount == 1)
        #expect(mockCoordinator.lastPid == fullscreenWindow.pid)
        #expect(mockAccessibility.setFrameCallCount == 1)
        #expect(mockAccessibility.lastSetFrame == targetFrame)
    }

    @Test("Normal window move does not trigger FullScreenEscapeCoordinator")
    func testMoveNormalWindowDoesNotTriggerEscapeCoordinator() async throws {
        let mockAccessibility = MockAccessibilityService(isTrusted: true)
        let mockCoordinator = MockFullScreenEscapeCoordinator()
        let windowManager = WindowManager(
            accessibilityService: mockAccessibility,
            fullScreenEscapeCoordinator: mockCoordinator
        )

        let dummyElement = AXUIElementCreateSystemWide()
        let normalWindow = makeManagedWindow(kind: .normal)
        let targetFrame = CGRect(x: 200, y: 200, width: 500, height: 500)

        try await windowManager.move(normalWindow, to: targetFrame, element: dummyElement)

        #expect(mockCoordinator.callCount == 0)
        #expect(mockAccessibility.setFrameCallCount == 1)
        #expect(mockAccessibility.lastSetFrame == targetFrame)
    }
}
