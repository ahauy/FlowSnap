import Foundation

/// Classifies windows to determine if they should be managed.
///
/// Not all windows should be snapped — dialogs, sheets,
/// and system UI should be left alone. See spec §53.
enum WindowKind {
    /// A standard application window (should be managed).
    case normal

    /// A modal dialog (should NOT be managed).
    case dialog

    /// A sheet attached to a window (should NOT be managed).
    case sheet

    /// A utility/palette window (should NOT be managed).
    case utility

    /// A fullscreen window (should NOT be managed).
    case fullscreen

    /// Could not determine window type.
    case unknown
}
