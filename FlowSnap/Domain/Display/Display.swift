import CoreGraphics

/// Represents a physical display connected to the Mac.
///
/// Wraps the essential geometry information that FlowSnap needs
/// to perform display-aware snapping. See spec §26, §33.
struct Display: Identifiable, Hashable {
    let id: CGDirectDisplayID

    /// Full frame including menu bar and dock areas.
    let frame: CGRect

    /// Usable frame excluding menu bar and dock.
    let visibleFrame: CGRect

    /// Retina scale factor (1.0, 2.0, etc.).
    let scaleFactor: CGFloat
}
