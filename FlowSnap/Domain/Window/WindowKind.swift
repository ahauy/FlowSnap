import Foundation

/// Semantic classification of a window to determine its eligibility for snap operations.
public enum WindowKind: String, Codable, Sendable, Hashable {
    /// Standard resizable application window (eligible for snapping).
    case normal

    /// Modal or system dialog window.
    case dialog

    /// Attached sheet window (e.g. print sheet, save sheet).
    case sheet

    /// Utility or palette window (floating panels, inspectors).
    case utility

    /// OS system element (e.g. Spotlight, Notification Center, Menubar extra, Dock).
    case system

    /// Fullscreen application window.
    case fullscreen

    /// Unrecognized or non-standard element lacking geometric or settable attributes.
    case unsupported

    /// Could not determine window type.
    case unknown

    /// Whether this window kind is eligible for snap operations.
    public var isSnappable: Bool {
        self == .normal
    }
}
