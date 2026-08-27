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
}
