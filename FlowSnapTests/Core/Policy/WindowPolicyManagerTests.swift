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

    @Test func assignedLayoutAppliesCanonicalZoneFrame() async throws {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 1.0,
            isPrimary: true
        )
        let display = MockDisplayManager(displays: [primary])
        let ax = MockAccessibilityService(isTrusted: true)
        let element = makeAXUIElement()
        let window = ManagedWindow(
            id: 10,
            pid: 100,
            bundleIdentifier: "com.microsoft.VSCode",
            title: "VS Code",
            frame: .zero
        )
        ax.mockWindowElements[window.id] = element

        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )
        manager.setPolicy(.assignedLayout(.leftHalf), forBundleID: "com.microsoft.VSCode")

        try await manager.applyPolicy(for: window)

        #expect(ax.setFrameCallCount == 1)
        #expect(ax.lastSetFrame == CGRect(x: 0, y: 0, width: 720, height: 900))
    }

    @Test func rememberPositionRestoresClampedFrame() async throws {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 1.0,
            isPrimary: true
        )
        let display = MockDisplayManager(displays: [primary])
        let ax = MockAccessibilityService(isTrusted: true)
        let element = makeAXUIElement()
        let window = ManagedWindow(
            id: 20,
            pid: 200,
            bundleIdentifier: "com.spotify.client",
            title: "Spotify",
            frame: .zero
        )
        ax.mockWindowElements[window.id] = element

        let suiteName = "WindowPolicyManagerTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = PreferencesStore(defaults: defaults)
        // Save frame outside the 1440x900 screen
        store.saveRememberedFrame(CGRect(x: 2000, y: 100, width: 800, height: 600), forBundleID: "com.spotify.client")

        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display,
            preferencesStore: store
        )
        manager.setPolicy(.rememberPosition, forBundleID: "com.spotify.client")

        try await manager.applyPolicy(for: window)

        #expect(ax.setFrameCallCount == 1)
        let applied = try #require(ax.lastSetFrame)
        #expect(applied.maxX <= 1440)
        #expect(applied.width == 800)
        #expect(applied.height == 600)
    }

    @Test func appPolicyRuleOverridesDefaultPolicy() throws {
        let suiteName = "WindowPolicyManagerPrecedenceTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = PreferencesStore(defaults: defaults)
        let rule = AppPolicyRule(
            bundleID: "com.slack.Slack",
            appName: "Slack",
            policy: .floating
        )
        store.setAppRule(rule)

        let ax = MockAccessibilityService(isTrusted: true)
        let display = MockDisplayManager(displays: [])
        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display,
            preferencesStore: store
        )

        #expect(manager.policy(forBundleID: "com.slack.Slack") == .floating)
        #expect(manager.policy(forBundleID: "com.unregistered.app") == .currentSpace)
    }

    @Test func floatingWindowRecordsInFocusStack() async throws {
        let display = MockDisplayManager(displays: [])
        let ax = MockAccessibilityService(isTrusted: true)
        let window = ManagedWindow(
            id: 99,
            pid: 999,
            bundleIdentifier: "ru.keepcoder.Telegram",
            title: "Telegram",
            frame: .zero
        )
        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )
        manager.setPolicy(.floating, forBundleID: "ru.keepcoder.Telegram")

        try await manager.applyPolicy(for: window)

        #expect(ax.setFrameCallCount == 0)
        let target = manager.focusStack.removeFloatingWindow(windowID: 99)
        #expect(target == nil)
    }

    @Test func appliedPolicyIsOnlyAppliedOncePerWindow() async throws {
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
            id: 88,
            pid: 888,
            bundleIdentifier: "com.apple.Terminal",
            title: "Terminal",
            frame: CGRect(x: 720, y: 25, width: 720, height: 875)
        )
        ax.mockWindowElements[window.id] = element
        ax.mockElementByWindowID[window.id] = element
        ax.managedWindowsByPID[window.pid] = [window]

        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )

        // First creation event applies policy
        await manager.handle(event: .applicationWindowCreated(pid: 888, windowID: 88))
        #expect(ax.setFrameCallCount == 1)

        // Second duplicate creation event (e.g. from app re-activation) is deduped and ignored!
        await manager.handle(event: .applicationWindowCreated(pid: 888, windowID: 88))
        #expect(ax.setFrameCallCount == 1)
    }

    @Test func prePopulateExistingWindowsIgnoresPreExistingWindows() async throws {
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
        let preExisting = ManagedWindow(
            id: 77,
            pid: 777,
            bundleIdentifier: "com.apple.Terminal",
            title: "Terminal",
            frame: CGRect(x: 720, y: 25, width: 720, height: 875)
        )
        ax.mockVisibleWindows = [preExisting]
        ax.mockWindowElements[preExisting.id] = element
        ax.mockElementByWindowID[preExisting.id] = element
        ax.managedWindowsByPID[preExisting.pid] = [preExisting]

        let manager = WindowPolicyManager(
            accessibilityService: ax,
            displayManager: display
        )
        manager.prePopulateExistingWindows()

        // Focus activation on pre-existing window must NOT apply policy or overwrite frame!
        await manager.handle(event: .applicationWindowCreated(pid: 777, windowID: 77))
        #expect(ax.setFrameCallCount == 0)
    }
}

// MARK: - Helpers

private func makeAXUIElement() -> AXUIElement {
    // AXUIElementCreateSystemWide is the only public entry point that
    // does not require a live app. The element is only used as an
    // identity token by MockAccessibilityService.
    AXUIElementCreateSystemWide()
}
