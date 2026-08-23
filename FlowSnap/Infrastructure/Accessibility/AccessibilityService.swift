import ApplicationServices

/// Abstraction over Apple's Accessibility API (AXUIElement).
///
/// All AX calls are isolated here so Core never depends
/// on AXUIElement directly. See spec §28.
protocol AccessibilityService {
    /// Get the system-wide focused window element.
    func focusedWindow() -> AXUIElement?

    /// Get all windows for a given process.
    func windows(of pid: pid_t) -> [AXUIElement]

    /// Read the frame (position + size) of a window.
    func frame(of window: AXUIElement) -> CGRect?

    /// Move and resize a window.
    func setFrame(_ frame: CGRect, for window: AXUIElement) throws

    /// Bring a window to the front.
    func raise(_ window: AXUIElement) throws
}
