import Foundation

/// Persists layouts and workspaces to Application Support.
///
/// MVP stores as JSON files. See spec §45.
///
/// Storage:
/// ```
/// ~/Library/Application Support/FlowSnap/
///   ├── layouts.json
///   └── workspaces.json
/// ```
final class WorkspaceStore {

    private let fileManager: FileManager
    private let appSupportURL: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.appSupportURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("FlowSnap", isDirectory: true)
    }

    // MARK: - Layouts

    func saveLayouts(_ layouts: [Layout]) throws {
        // TODO: Encode to JSON, write to layouts.json
    }

    func loadLayouts() throws -> [Layout] {
        // TODO: Read layouts.json, decode
        []
    }

    // MARK: - Workspaces

    func saveWorkspaces(_ workspaces: [Workspace]) throws {
        // TODO: Encode to JSON, write to workspaces.json
    }

    func loadWorkspaces() throws -> [Workspace] {
        // TODO: Read workspaces.json, decode
        []
    }
}
