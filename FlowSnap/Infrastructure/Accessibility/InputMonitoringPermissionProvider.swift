import Foundation

/// Checks and requests Input Monitoring permission (TCC).
///
/// Input Monitoring is required for CGEventTap to track
/// global cursor position during drag-to-snap operations.
/// This is a separate TCC permission from Accessibility.
/// See spec §29.
protocol InputMonitoringPermissionProvider {
    /// Whether FlowSnap has been granted Input Monitoring permission.
    var isAuthorized: Bool { get }

    /// Prompt the user to grant Input Monitoring permission.
    /// Opens System Settings to the appropriate pane.
    func requestPermission()
}
