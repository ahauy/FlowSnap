import CoreGraphics
import Foundation

/// Direction of cross-display workspace migration.
public enum MigrationDirection: String, Sendable, Codable, CaseIterable {
    case next
    case previous
}

/// Result of an atomic workspace migration across displays.
public enum MigrationResult: Equatable, Sendable {
    case success(windowsMigrated: Int, targetDisplayID: CGDirectDisplayID)
    case noOp(reason: NoOpReason)

    public enum NoOpReason: Equatable, Sendable {
        case singleDisplay
        case noActiveWorkspace
        case noWindowsFound
        case accessibilityDenied
    }
}

/// Protocol defining atomic multi-window workspace migration across displays.
///
/// Traces to: US-DISP-017, BR-MIG-001..005.
@MainActor
public protocol WorkspaceMigrating: AnyObject {
    /// Migrates the active workspace on the current display in the specified direction.
    ///
    /// - Parameter direction: .next or .previous.
    /// - Returns: MigrationResult indicating success count or reason for no-op.
    func migrateActiveWorkspace(
        direction: MigrationDirection
    ) async throws -> MigrationResult
}
