import CoreGraphics

/// Represents a physical display connected to the Mac.
///
/// Wraps the essential geometry information that FlowSnap needs
/// to perform display-aware snapping. See spec §26, §33.
public struct Display: Identifiable, Hashable, Sendable {
    public let id: CGDirectDisplayID

    /// Full frame including menu bar and dock areas.
    public let frame: CGRect

    /// Usable frame excluding menu bar and dock.
    public let visibleFrame: CGRect

    /// Retina scale factor (1.0, 2.0, etc.).
    public let scaleFactor: CGFloat

    /// Indicates whether this display is the macOS Primary Display (origin at (0,0) in AppKit).
    public let isPrimary: Bool

    public init(
        id: CGDirectDisplayID,
        frame: CGRect,
        visibleFrame: CGRect,
        scaleFactor: CGFloat,
        isPrimary: Bool? = nil
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.scaleFactor = scaleFactor
        self.isPrimary = isPrimary ?? (frame.origin == .zero)
    }
}
