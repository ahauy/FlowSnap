import ApplicationServices

/// Concrete implementation of AccessibilityService using AXUIElement.
///
/// This is the only place in the codebase that directly calls
/// AXUIElement APIs. See spec §28.
final class AXAccessibilityService: AccessibilityService {

    func focusedWindow() -> AXUIElement? {
        // TODO: AXUIElementCreateSystemWide() → focused app → focused window
        nil
    }

    func windows(of pid: pid_t) -> [AXUIElement] {
        // TODO: AXUIElementCreateApplication(pid) → kAXWindowsAttribute
        []
    }

    func frame(of window: AXUIElement) -> CGRect? {
        // TODO: Read kAXPositionAttribute + kAXSizeAttribute
        nil
    }

    func setFrame(_ frame: CGRect, for window: AXUIElement) throws {
        // TODO: Set kAXPositionAttribute + kAXSizeAttribute
    }

    func raise(_ window: AXUIElement) throws {
        // TODO: AXUIElementPerformAction(kAXRaiseAction)
    }
}
