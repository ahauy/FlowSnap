import Foundation

/// Checks and requests Accessibility permission (TCC).
///
/// Accessibility permission is required to control windows
/// of other applications via AXUIElement. See spec §29.
protocol AccessibilityPermissionProvider {
    /// Whether FlowSnap has been granted Accessibility permission.
    var isTrusted: Bool { get }

    /// Prompt the user to grant Accessibility permission.
    /// Opens System Settings to the appropriate pane.
    func requestPermission()
}
