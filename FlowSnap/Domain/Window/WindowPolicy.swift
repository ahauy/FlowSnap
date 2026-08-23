import Foundation

/// Per-app window placement policy.
///
/// Determines how FlowSnap handles a newly opened or activated
/// window for a specific application. See spec §37.
enum WindowPolicy: Codable, Hashable {
    /// Keep the window on the current Space (default).
    case currentSpace

    /// Keep the window on the current display.
    case currentDisplay

    /// Allow the window to float above managed layouts.
    case floating

    /// Remember and restore the window's last known position.
    case rememberPosition

    /// Assign the window to a specific layout zone.
    case assignedLayout(UUID)

    /// Assign the window to a specific workspace.
    case assignedWorkspace(UUID)
}
