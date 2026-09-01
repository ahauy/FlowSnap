import Foundation

/// Typed errors surfaced by the workspace persistence store (contracts §1).
public enum WorkspaceStoreError: Error, Equatable, Sendable {

    /// E7 — the JSON file exists but could not be decoded (corrupt / schema drift).
    case corruptFile

    /// The Application Support directory could not be created.
    case cannotCreateDirectory

    /// Encoding or writing the document failed (disk full, permissions, …).
    case writeFailed
}

/// Persists the user's workspaces as a single JSON document (FR-7, BR-WORK-006).
///
/// Why one file (not one per workspace): the whole set is always read together at
/// launch, it is small (tens of KB), and a single atomic write is simpler and far
/// less failure-prone than keeping a directory of files consistent.
///
/// ADR-003: an `actor`, matching the project's concurrency convention
/// (`PreferencesStore`). Every write is a full-document rewrite, atomic via
/// temp-file + rename, so a crash mid-write can never leave a half-written file.
///
/// Corruption (spec §5 E7, BR-WORK-009, RISK-WORK-004): a *read* of an unreadable
/// file throws `corruptFile` so the caller can degrade to an empty list while the
/// UI explains what happened and offers "Retry" — never a silent, crash-free
/// "you have no workspaces". A *write* is the user's consent to start over, so it
/// succeeds; but it first parks the unreadable bytes at `workspaces.corrupt.json`,
/// so nothing is destroyed and manual recovery stays possible.
///
/// Traces to: data-model.md §2/§4, contracts §1.
public actor WorkspaceStore {

    /// File name inside the Application Support directory.
    static let fileName = "workspaces.json"

    /// Where unreadable bytes are parked instead of being silently overwritten.
    static let corruptFileName = "workspaces.corrupt.json"

    /// Directory the store reads and writes. Resolved once at init so tests can
    /// point it at a temporary directory (contracts §1).
    private let directoryURL: URL

    public init(directoryURL: URL? = nil) {
        self.directoryURL = directoryURL ?? Self.defaultDirectoryURL()
    }

    /// Default location: `~/Library/Application Support/FlowSnap/`.
    static func defaultDirectoryURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("FlowSnap", isDirectory: true)
    }

    private var fileURL: URL { directoryURL.appendingPathComponent(Self.fileName) }
    private var corruptFileURL: URL { directoryURL.appendingPathComponent(Self.corruptFileName) }

    // MARK: - Reading

    /// All saved workspaces, in stored order.
    ///
    /// - Returns: `[]` when no file exists yet (first launch).
    /// - Throws: `WorkspaceStoreError.corruptFile` when the file exists but cannot
    ///   be decoded. The file is left untouched so the user can recover it by hand.
    public func loadWorkspaces() async throws -> [Workspace] {
        try readWorkspaces()
    }

    /// Synchronous read core, shared by the public read and the write path.
    private func readWorkspaces() throws -> [Workspace] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        guard let data = try? Data(contentsOf: fileURL),
              let document = try? WorkspaceDocument.decoder.decode(WorkspaceDocument.self, from: data) else {
            throw WorkspaceStoreError.corruptFile
        }
        return document.workspaces.map(\.normalized)
    }

    /// A single workspace by id, or `nil`.
    public func loadWorkspace(id: UUID) async throws -> Workspace? {
        try await loadWorkspaces().first { $0.id == id }
    }

    // MARK: - Writing

    /// Replaces the entire document (atomic temp-file + rename).
    public func saveWorkspaces(_ workspaces: [Workspace]) async throws {
        try write(WorkspaceDocument(workspaces: workspaces.map(\.normalized)))
    }

    /// Creates or replaces a workspace by id, preserving stored order.
    public func upsert(_ workspace: Workspace) async throws {
        var all = currentWorkspacesForWrite()
        let normalized = workspace.normalized
        if let index = all.firstIndex(where: { $0.id == workspace.id }) {
            all[index] = normalized
        } else {
            all.append(normalized)
        }
        try write(WorkspaceDocument(workspaces: all))
    }

    /// Removes a workspace by id.
    ///
    /// Idempotent: deleting an unknown id is a no-op, which is the right behaviour
    /// for a confirmation dialog whose result may arrive after the workspace was
    /// already deleted elsewhere (spec §4.5).
    public func deleteWorkspace(id: UUID) async throws {
        var all = currentWorkspacesForWrite()
        let before = all.count
        all.removeAll { $0.id == id }
        guard all.count != before else { return }
        try write(WorkspaceDocument(workspaces: all))
    }

    // MARK: - Internals

    /// Read path for mutations: tolerates an unreadable file, because an explicit
    /// save is the user's consent to start over (E7). The corrupt bytes are parked
    /// first, so recovery remains possible.
    private func currentWorkspacesForWrite() -> [Workspace] {
        if let loaded = try? readWorkspaces() { return loaded }
        parkCorruptFileIfNeeded()
        return []
    }

    /// Moves an unreadable file to `workspaces.corrupt.json`, once.
    ///
    /// A later corruption never clobbers the first parked copy, so the most
    /// recoverable snapshot is what survives.
    private func parkCorruptFileIfNeeded() {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path), !fileManager.fileExists(atPath: corruptFileURL.path) else { return }
        do {
            try fileManager.moveItem(at: fileURL, to: corruptFileURL)
        } catch {
            // Best effort: if the move fails we still allow the save, matching E7
            // ("next save rewrites the file"). Logged for field diagnosis.
            NSLog("[WorkspaceStore] Could not park corrupt file: \(error.localizedDescription)")
        }
    }

    private func write(_ document: WorkspaceDocument) throws {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try WorkspaceDocument.encoder.encode(document)

            // Atomic write: temp file in the SAME directory (so the rename cannot
            // cross a volume boundary), then rename over the destination.
            let temporaryURL = directoryURL.appendingPathComponent(".\(Self.fileName).tmp")
            if fileManager.fileExists(atPath: temporaryURL.path) {
                try fileManager.removeItem(at: temporaryURL)
            }
            try data.write(to: temporaryURL, options: .atomic)
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            try fileManager.moveItem(at: temporaryURL, to: fileURL)
        } catch let error as WorkspaceStoreError {
            throw error
        } catch {
            NSLog("[WorkspaceStore] Write failed: \(error.localizedDescription)")
            throw WorkspaceStoreError.writeFailed
        }
    }
}
