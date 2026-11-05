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

    // MARK: - Stale window must never act on the incidentally-focused window

    @Test("move with an unresolvable window throws instead of writing onto the focused window")
    func testMoveStaleWindowThrowsInsteadOfTouchingFocusedWindow() async {
        let stale = StaleTargetAccessibilityService()
        let windowManager = WindowManager(accessibilityService: stale)
        let targetFrame = CGRect(x: 100, y: 100, width: 600, height: 400)

        await #expect(throws: AccessibilityError.cannotComplete) {
            try await windowManager.move(makeManagedWindow(), to: targetFrame)
        }
        #expect(stale.inner.setFrameCallCount == 0)
    }

    @Test("focus with an unresolvable window throws instead of raising the focused window")
    func testFocusStaleWindowThrowsInsteadOfRaisingFocusedWindow() async {
        let stale = StaleTargetAccessibilityService()
        let windowManager = WindowManager(accessibilityService: stale)

        await #expect(throws: AccessibilityError.cannotComplete) {
            try await windowManager.focus(makeManagedWindow())
        }
        #expect(stale.inner.raiseCallCount == 0)
    }

    @Test("minimize with an unresolvable window throws instead of minimizing the focused window")
    func testMinimizeStaleWindowThrowsInsteadOfMinimizingFocusedWindow() async {
        let stale = StaleTargetAccessibilityService()
        let windowManager = WindowManager(accessibilityService: stale)

        await #expect(throws: AccessibilityError.cannotComplete) {
            try await windowManager.minimize(makeManagedWindow())
        }
        #expect(stale.inner.minimizeCallCount == 0)
    }
}

/// Forwards to `MockAccessibilityService` but decouples `windowElement(for:)`
/// from `focusedWindow()`: the intended window is unresolvable while an unrelated
/// window is focused — the exact state the removed fallback used to act on.
/// The shared mock cannot express it because its `windowElement(for:)` already
/// falls back to the focused element.
private final class StaleTargetAccessibilityService: AccessibilityService, @unchecked Sendable {
    let inner = MockAccessibilityService(isTrusted: true)
    let focusedElement = AXUIElementCreateSystemWide()

    var isTrusted: Bool { inner.isTrusted }
    func openSystemSettings() { inner.openSystemSettings() }
    func focusedWindow() -> AXUIElement? { focusedElement }
    func focusedManagedWindow() -> ManagedWindow? { inner.focusedManagedWindow() }
    func windows(of pid: pid_t) -> [AXUIElement] { inner.windows(of: pid) }
    func frame(of window: AXUIElement) -> CGRect? { inner.frame(of: window) }
    func setFrame(_ frame: CGRect, for window: AXUIElement) throws { try inner.setFrame(frame, for: window) }
    func raise(_ window: AXUIElement) throws { try inner.raise(window) }
    @discardableResult
    func raise(window: ManagedWindow) -> Bool { inner.raise(window: window) }
    func windowElement(for window: ManagedWindow) -> AXUIElement? { nil }
    func allVisibleManagedWindows() -> [ManagedWindow] { inner.allVisibleManagedWindows() }
    func managedWindows(of pid: pid_t) -> [ManagedWindow] { inner.managedWindows(of: pid) }
    func minimize(_ window: AXUIElement) throws { try inner.minimize(window) }
    func unminimize(_ window: AXUIElement) throws { try inner.unminimize(window) }
    func resolvedWindows(of pid: pid_t) -> [ResolvedWindow] { inner.resolvedWindows(of: pid) }
    func exitFullScreen(_ window: AXUIElement) throws { try inner.exitFullScreen(window) }
}
