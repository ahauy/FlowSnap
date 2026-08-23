import CoreGraphics

/// Concrete implementation of WindowManaging.
///
/// Delegates actual window control to AccessibilityService.
/// See spec §27.
final class WindowManager: WindowManaging {

    private let accessibilityService: AccessibilityService

    init(accessibilityService: AccessibilityService) {
        self.accessibilityService = accessibilityService
    }

    func focusedWindow() async -> ManagedWindow? {
        // TODO: Query AX for focused window, convert to ManagedWindow
        nil
    }

    func move(_ window: ManagedWindow, to frame: CGRect) async throws {
        // TODO: Use accessibilityService.setFrame
    }

    func focus(_ window: ManagedWindow) async throws {
        // TODO: Use accessibilityService.raise
    }

    func minimize(_ window: ManagedWindow) async throws {
        // TODO: Use AX to minimize
    }
}
