import Foundation

extension WorkspaceManager {

    /// Migrates the active workspace on the current display in the specified direction.
    ///
    /// Traces to: US-DISP-017, BR-MIG-001..005.
    @discardableResult
    public func migrateActiveWorkspace(
        direction: MigrationDirection,
        migrator: any WorkspaceMigrating
    ) async throws -> MigrationResult {
        try await migrator.migrateActiveWorkspace(direction: direction)
    }
}
