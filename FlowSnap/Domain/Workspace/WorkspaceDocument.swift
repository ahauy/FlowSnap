import Foundation

/// The on-disk persistence envelope for the workspace store (data-model.md §2).
///
/// A single JSON document holds every workspace:
///
/// ```
/// { "schemaVersion": 1, "workspaces": [ … ] }
/// ```
///
/// Why one file (not one per workspace): the whole set is always read together at
/// launch, it is small (tens of KB), and a single atomic write is simpler and far
/// less failure-prone than keeping a directory of files consistent.
///
/// `schemaVersion` is written so a future reader can tell what produced the file.
/// Unknown fields are ignored by `JSONDecoder` by default, which is what makes the
/// schema additive-forward: a v1.1 file carrying a `mode` field still loads on
/// v1.0 (NFR-5).
///
/// Traces to: data-model.md §2, spec §3 FR-7.
public struct WorkspaceDocument: Codable, Equatable, Sendable {

    /// Current schema version written to disk.
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var workspaces: [Workspace]

    public init(workspaces: [Workspace], schemaVersion: Int = WorkspaceDocument.currentSchemaVersion) {
        self.workspaces = workspaces
        self.schemaVersion = schemaVersion
    }

    /// An empty document, used when the store file is missing (first launch).
    public static let empty = WorkspaceDocument(workspaces: [])

    /// Stable key ordering + pretty printing so the file stays diff-friendly and
    /// human-inspectable (also useful for the future export/import story).
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder = JSONDecoder()
}
