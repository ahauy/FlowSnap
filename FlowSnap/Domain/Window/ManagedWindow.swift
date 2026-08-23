import CoreGraphics

/// A window being tracked and managed by FlowSnap.
///
/// Represents a snapshot of a window's state. Does not hold
/// a reference to the underlying AXUIElement — that mapping
/// lives in the Infrastructure layer (AccessibilityService).
struct ManagedWindow: Identifiable, Hashable {
    let id: CGWindowID
    let pid: pid_t
    let bundleIdentifier: String?
    let title: String

    var frame: CGRect
    var isMinimized: Bool
}
