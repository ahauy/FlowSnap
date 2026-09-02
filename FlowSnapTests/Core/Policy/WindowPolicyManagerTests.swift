import Testing
import ApplicationServices
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Tests for `WindowPolicyManager.applyPolicy` (US-WORK-013, TC-013-06).
@Suite @MainActor
struct WindowPolicyManagerTests {

    @Test func currentSpaceAppliesVisibleFrame() async throws {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 0, y: 25, width: 1920, height: 1055),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let display = MockDisplayManager(displays: [primary])
        let ax = MockAccessibilityService(isTrusted: true)
        let element = makeAXUIElement()
        let window = ManagedWindow(
            id: 7,
            pid: 1001,
            bundleIdentifier: "com.apple.Safari",
            title: "Safari",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600)
        )
        ax.mockWindowElements[window.id] = element

        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )

        try await manager.applyPolicy(for: window)

        #expect(ax.setFrameCallCount == 1)
        #expect(ax.lastSetFrame == primary.visibleFrame)
    }

    @Test func currentSpaceResolvesPolicyByBundleID() async throws {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let display = MockDisplayManager(displays: [primary])
        let ax = MockAccessibilityService(isTrusted: true)
        let element = makeAXUIElement()
        let window = ManagedWindow(
            id: 9,
            pid: 2002,
            bundleIdentifier: "com.example.app",
            title: "App",
            frame: .zero
        )
        ax.mockWindowElements[window.id] = element

        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )
        manager.setPolicy(.currentSpace, forBundleID: "com.example.app")

        try await manager.applyPolicy(for: window)
        #expect(ax.setFrameCallCount == 1)
        #expect(ax.lastSetFrame == primary.visibleFrame)
    }

    @Test func noOpPoliciesDoNotInvokeSetFrame() async throws {
        let display = MockDisplayManager(displays: [])
        let ax = MockAccessibilityService(isTrusted: true)
        let window = ManagedWindow(
            id: 1,
            pid: 1,
            bundleIdentifier: "com.example.float",
            title: "F",
            frame: .zero
        )
        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )
        manager.setPolicy(.floating, forBundleID: "com.example.float")

        try await manager.applyPolicy(for: window)
        #expect(ax.setFrameCallCount == 0)
    }

    @Test func currentSpaceThrowsWhenNoElementFound() async {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 100, height: 100),
            visibleFrame: CGRect(x: 0, y: 0, width: 100, height: 100),
            scaleFactor: 1.0,
            isPrimary: true
        )
        let display = MockDisplayManager(displays: [primary])
        let ax = MockAccessibilityService(isTrusted: true)
        let window = ManagedWindow(
            id: 1,
            pid: 1,
            bundleIdentifier: "com.example.missing",
            title: "M",
            frame: .zero
        )
        // mockWindowElements intentionally empty
        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )

        await #expect(throws: AccessibilityError.self) {
            try await manager.applyPolicy(for: window)
        }
    }
}

// MARK: - Helpers

private func makeAXUIElement() -> AXUIElement {
    // AXUIElementCreateSystemWide is the only public entry point that
    // does not require a live app. The element is only used as an
    // identity token by MockAccessibilityService.
    AXUIElementCreateSystemWide()
}
