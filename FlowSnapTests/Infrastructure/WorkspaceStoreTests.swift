import Foundation
import Testing
@testable import FlowSnap

/// Unit tests for the WorkspaceStore actor (T005).
///
/// Traces to US-WORK-011: BR-006/009 persistence, E7 corrupt file,
/// atomic overwrite, upsert/delete semantics.
@Suite("WorkspaceStore")
struct WorkspaceStoreTests {

    /// Creates an isolated store backed by a fresh temp directory.
    private func makeStore() -> (WorkspaceStore, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapStoreTests-\(UUID().uuidString)", isDirectory: true)
        return (WorkspaceStore(directoryURL: dir), dir)
    }

    private func makeWorkspace(name: String = "Coding", zone: LayoutZone = .leftHalf) -> Workspace {
        Workspace(
            name: name,
            icon: "hammer",
            placements: [
                WindowPlacement(bundleIdentifier: "com.microsoft.VSCode", zone: zone, expectedWindowCount: 1, orderIndex: 0)
            ]
        )
    }

    // MARK: - Round-trip

    @Test func roundTripPreservesWorkspaces() async throws {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let workspace = makeWorkspace()
        try await store.upsert(workspace)

        let loaded = try await store.loadWorkspaces()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Coding")
        #expect(loaded.first?.placements.first?.zone == .leftHalf)
        #expect(loaded.first?.placements.first?.bundleIdentifier == "com.microsoft.VSCode")
        #expect(loaded.first?.placements.first?.expectedWindowCount == 1)
    }

    // MARK: - Missing file

    @Test func missingFileReturnsEmptyArray() async throws {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let loaded = try await store.loadWorkspaces()
        #expect(loaded.isEmpty)
    }

    // MARK: - Corrupt file (E7)

    @Test func corruptFileThrowsCorruptFileError() async throws {
        let (store, dir) = validStoreWithContent("this is not json {{{")
        defer { try? FileManager.default.removeItem(at: dir) }

        await #expect(throws: WorkspaceStoreError.corruptFile) {
            try await store.loadWorkspaces()
        }
    }

    @Test func corruptFileRecoversOnNextSave() async throws {
        let (store, dir) = validStoreWithContent("{{{ corrupt")
        defer { try? FileManager.default.removeItem(at: dir) }

        // Corrupt state does not block writes (E7 recovery path).
        try await store.upsert(makeWorkspace())
        let loaded = try await store.loadWorkspaces()
        #expect(loaded.count == 1)
    }

    // MARK: - Atomic overwrite

    @Test func secondSaveOverwritesFirst() async throws {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        try await store.upsert(makeWorkspace(name: "First"))
        try await store.upsert(makeWorkspace(name: "Second"))

        let loaded = try await store.loadWorkspaces()
        #expect(loaded.count == 2)
        #expect(loaded.map(\.name) == ["First", "Second"])
    }

    // MARK: - Upsert semantics

    @Test func upsertUpdatesExistingByID() async throws {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        var workspace = makeWorkspace(name: "Original")
        try await store.upsert(workspace)
        workspace.name = "Renamed"
        try await store.upsert(workspace)

        let loaded = try await store.loadWorkspaces()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Renamed")
    }

    // MARK: - Delete

    @Test func deleteRemovesWorkspace() async throws {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        let workspace = makeWorkspace()
        try await store.upsert(workspace)
        try await store.deleteWorkspace(id: workspace.id)

        let loaded = try await store.loadWorkspaces()
        #expect(loaded.isEmpty)
    }

    @Test func deleteNonexistentIDIsNoOp() async throws {
        let (store, dir) = makeStore()
        defer { try? FileManager.default.removeItem(at: dir) }

        try await store.upsert(makeWorkspace())
        try await store.deleteWorkspace(id: UUID())

        let loaded = try await store.loadWorkspaces()
        #expect(loaded.count == 1)
    }

    // MARK: - Schema envelope

    @Test func documentEnvelopeCarriesSchemaVersion() throws {
        let doc = WorkspaceDocument(workspaces: [makeWorkspace()])
        #expect(doc.schemaVersion == WorkspaceDocument.currentSchemaVersion)

        let data = try JSONEncoder().encode(doc)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["schemaVersion"] as? Int == 1)
        #expect(json?["workspaces"] != nil)
    }

    @Test func decodeIgnoresUnknownFields() throws {
        // Forward compatibility (NFR-5): a v1.1 file with extra fields decodes on v1.0.
        let json = """
        {
          "schemaVersion": 1,
          "futureField": "ignored",
          "workspaces": [
            {
              "id": "11111111-1111-1111-1111-111111111111",
              "name": "Future",
              "icon": "hammer",
              "createdAt": 0,
              "lastRestoredAt": null,
              "placements": [
                {
                  "bundleIdentifier": "com.apple.Safari",
                  "zone": "leftHalf",
                  "expectedWindowCount": 2,
                  "orderIndex": 0,
                  "mode": "exclusive"
                }
              ]
            }
          ]
        }
        """
        let data = Data(json.utf8)
        let doc = try JSONDecoder().decode(WorkspaceDocument.self, from: data)
        #expect(doc.workspaces.count == 1)
        #expect(doc.workspaces.first?.placements.first?.expectedWindowCount == 2)
    }

    // MARK: - Helpers

    private func validStoreWithContent(_ content: String) -> (WorkspaceStore, URL) {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapStoreTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? content.write(to: dir.appendingPathComponent("workspaces.json"), atomically: true, encoding: .utf8)
        return (WorkspaceStore(directoryURL: dir), dir)
    }
}
