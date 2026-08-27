import Foundation

/// Classifies windows to determine if they should be managed.
///
/// Not all windows should be snapped — dialogs, sheets,
/// and system UI should be left alone. See spec §53.
public struct WindowClassifier: Sendable {

    public init() {}

    /// Checks if a window kind is eligible for management/snapping.
    public func shouldManage(kind: WindowKind) -> Bool {
        kind.isSnappable
    }
}
