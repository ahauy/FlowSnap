import CoreGraphics
import Foundation

/// A window being tracked and managed by FlowSnap.
///
/// Represents a snapshot of a window's state. Does not hold
/// a reference to the underlying AXUIElement — that mapping
/// lives in the Infrastructure layer (AccessibilityService).
public struct ManagedWindow: Identifiable, Hashable, Sendable {
    public let id: CGWindowID
    public let pid: pid_t
    public let bundleIdentifier: String?
    public let title: String

    public var frame: CGRect
    public var isMinimized: Bool
    public var isResizable: Bool
    public var kind: WindowKind

    public init(
        id: CGWindowID,
        pid: pid_t,
        bundleIdentifier: String? = nil,
        title: String,
        frame: CGRect,
        isMinimized: Bool = false,
        isResizable: Bool = true,
        kind: WindowKind = .normal
    ) {
        self.id = id
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.title = title
        self.frame = frame
        self.isMinimized = isMinimized
        self.isResizable = isResizable
        self.kind = kind
    }
}
