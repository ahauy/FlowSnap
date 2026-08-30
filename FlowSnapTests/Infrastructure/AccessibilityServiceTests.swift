import Testing
import CoreGraphics
import Foundation
@testable import FlowSnap

struct AccessibilityServiceTests {

    @Test func trustedStateReturnsTrue() {
        let service = MockAccessibilityService(isTrusted: true)
        #expect(service.isTrusted == true)
    }

    @Test func untrustedStateReturnsFalseAndBlocksQueries() {
        let window = ManagedWindow(
            id: 1,
            pid: 500,
            title: "Mock Window",
            frame: CGRect(x: 0, y: 0, width: 600, height: 400)
        )
        let service = MockAccessibilityService(isTrusted: false, mockFocusedManagedWindow: window)

        #expect(service.isTrusted == false)
        #expect(service.focusedWindow() == nil)
        #expect(service.focusedManagedWindow() == nil)
        #expect(service.windows(of: 500).isEmpty)
    }

    @Test func trustedServiceReturnsFocusedWindow() {
        let expectedWindow = ManagedWindow(
            id: 2,
            pid: 600,
            title: "Code Editor",
            frame: CGRect(x: 100, y: 100, width: 1000, height: 800),
            kind: .normal
        )
        let service = MockAccessibilityService(isTrusted: true, mockFocusedManagedWindow: expectedWindow)

        let focused = service.focusedManagedWindow()
        #expect(focused != nil)
        #expect(focused?.id == 2)
        #expect(focused?.title == "Code Editor")
        #expect(focused?.kind == .normal)
    }

    @Test func systemSettingsRouterTargetURL() {
        let expectedURLString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        #expect(SystemSettingsRouter.accessibilityURL.absoluteString == expectedURLString)
    }

    @Test func openSystemSettingsIncrementsCallCount() {
        let service = MockAccessibilityService()
        service.openSystemSettings()
        #expect(service.openSettingsCallCount == 1)
    }

    @Test func allVisibleManagedWindowsHonorsIsTrustedAndProvidesResizableStatus() {
        let fixedWindow = ManagedWindow(
            id: 10, pid: 100, title: "System Settings",
            frame: CGRect(x: 0, y: 0, width: 600, height: 500),
            isResizable: false,
            kind: .unsupported
        )
        let resizableWindow = ManagedWindow(
            id: 20, pid: 200, title: "Safari",
            frame: CGRect(x: 600, y: 0, width: 800, height: 900),
            isResizable: true,
            kind: .normal
        )

        let untrustedService = MockAccessibilityService(isTrusted: false)
        untrustedService.mockVisibleWindows = [fixedWindow, resizableWindow]
        #expect(untrustedService.allVisibleManagedWindows().isEmpty)

        let trustedService = MockAccessibilityService(isTrusted: true)
        trustedService.mockVisibleWindows = [fixedWindow, resizableWindow]
        let results = trustedService.allVisibleManagedWindows()
        #expect(results.count == 2)
        #expect(results.first { $0.id == 10 }?.isResizable == false)
        #expect(results.first { $0.id == 20 }?.isResizable == true)
    }
}
