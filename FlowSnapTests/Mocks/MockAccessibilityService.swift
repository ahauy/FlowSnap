import ApplicationServices
import CoreGraphics
import Foundation
@testable import FlowSnap

/// In-memory mock double of AccessibilityService for unit testing.
public final class MockAccessibilityService: AccessibilityService, @unchecked Sendable {

    public var isTrusted: Bool
    public var openSettingsCallCount = 0

    public var mockFocusedElement: AXUIElement?
    public var mockFocusedManagedWindow: ManagedWindow?
    public var mockFrames: [AXUIElement: CGRect] = [:]
    public var mockWindowsOfProcess: [pid_t: [AXUIElement]] = [:]

    public var setFrameCallCount = 0
    public var lastSetFrame: CGRect?
    public var raiseCallCount = 0

    public init(
        isTrusted: Bool = true,
        mockFocusedManagedWindow: ManagedWindow? = nil
    ) {
        self.isTrusted = isTrusted
        self.mockFocusedManagedWindow = mockFocusedManagedWindow
    }

    public func openSystemSettings() {
        openSettingsCallCount += 1
    }

    public func focusedWindow() -> AXUIElement? {
        guard isTrusted else { return nil }
        return mockFocusedElement
    }

    public func focusedManagedWindow() -> ManagedWindow? {
        guard isTrusted else { return nil }
        return mockFocusedManagedWindow
    }

    public func windows(of pid: pid_t) -> [AXUIElement] {
        guard isTrusted else { return [] }
        return mockWindowsOfProcess[pid] ?? []
    }

    public func frame(of window: AXUIElement) -> CGRect? {
        guard isTrusted else { return nil }
        return mockFrames[window]
    }

    public func setFrame(_ frame: CGRect, for window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        setFrameCallCount += 1
        lastSetFrame = frame
        mockFrames[window] = frame
    }

    public func raise(_ window: AXUIElement) throws {
        guard isTrusted else { throw AccessibilityError.notTrusted }
        raiseCallCount += 1
    }

    public var mockWindowElements: [CGWindowID: AXUIElement] = [:]
    public func windowElement(for window: ManagedWindow) -> AXUIElement? {
        guard isTrusted else { return nil }
        return mockWindowElements[window.id] ?? mockFocusedElement
    }

    public var mockVisibleWindows: [ManagedWindow] = []
    public func allVisibleManagedWindows() -> [ManagedWindow] {
        guard isTrusted else { return [] }
        return mockVisibleWindows
    }
}
