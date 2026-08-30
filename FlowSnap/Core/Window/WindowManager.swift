import ApplicationServices
import CoreGraphics
import Foundation

/// Concrete implementation of WindowManaging.
///
/// Delegates actual window control to AccessibilityService on the MainActor.
/// See spec §27.
@MainActor
public final class WindowManager: WindowManaging {

    private let accessibilityService: AccessibilityService

    public init(accessibilityService: AccessibilityService) {
        self.accessibilityService = accessibilityService
    }

    public func focusedWindow() async -> ManagedWindow? {
        accessibilityService.focusedManagedWindow()
    }

    public func move(_ window: ManagedWindow, to frame: CGRect) async throws {
        // Prevent snapping FlowSnap's own windows
        if window.pid == ProcessInfo.processInfo.processIdentifier {
            return
        }
        let element: AXUIElement
        if let targetElement = accessibilityService.windowElement(for: window) {
            element = targetElement
        } else if let focused = accessibilityService.focusedWindow() {
            element = focused
        } else {
            throw AccessibilityError.cannotComplete
        }

        try accessibilityService.setFrame(frame, for: element)
    }

    public func focus(_ window: ManagedWindow) async throws {
        // Prevent focusing FlowSnap's own windows
        if window.pid == ProcessInfo.processInfo.processIdentifier {
            return
        }
        let element: AXUIElement
        if let targetElement = accessibilityService.windowElement(for: window) {
            element = targetElement
        } else if let focused = accessibilityService.focusedWindow() {
            element = focused
        } else {
            throw AccessibilityError.cannotComplete
        }
        try accessibilityService.raise(element)
    }

    public func minimize(_ window: ManagedWindow) async throws {
        // AX minimize can be added when needed
    }
}
