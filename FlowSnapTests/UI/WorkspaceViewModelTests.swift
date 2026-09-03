import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// T015 — the workspace view model's save/restore/delete flows (US-WORK-011 §4.5).
///
/// The view model is a façade over `WorkspaceManager`, so these tests drive the
/// *real* manager built from the same mocks the orchestration suites use. That
/// keeps them honest: they assert the transient UI state (draft name, selection,
/// inline error text, sheet open/closed, surfaced summary) rather than re-testing
/// capture/restore geometry, which T009–T011 already pin.
@MainActor
@Suite("WorkspaceViewModel")
struct WorkspaceViewModelTests {

    // MARK: - Fixtures

    private let display = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        scaleFactor: 2.0,
        isPrimary: true
    )

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapVMTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func editorWindow(id: CGWindowID = 1) -> ManagedWindow {
        WorkspaceTestFixtures.window(
            id: id, bundle: "com.editor",
            appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
    }

    private func browserWindow(id: CGWindowID = 2) -> ManagedWindow {
        WorkspaceTestFixtures.window(
            id: id, bundle: "com.browser",
            appKitFrame: CGRect(x: 720, y: 0, width: 720, height: 900)
        )
    }

    /// A manager wired from mocks; `loadAtInit: false` so the list starts empty
    /// and each test controls when it reloads.
    private func makeManager(
        windows: [ManagedWindow],
        trusted: Bool = true,
        launcher: any ApplicationLaunching = MockApplicationLaunching(),
        windowManager: MockWindowManaging = MockWindowManaging()
    ) -> WorkspaceManager {
        let accessibility = MockAccessibilityService(isTrusted: trusted)
        accessibility.mockVisibleWindows = windows
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: windowManager,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        // P0.5: scriptable presentation checker defaulting to `.presented`, so
        // restore flows surfaced through the view model keep their expectations.
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())
        return manager
    }

    // MARK: - Save flow (J1)

    @Test("Presenting the sheet preloads a suggested name and selects all candidates")
    func presentSheetPreloads() async throws {
        let manager = makeManager(windows: [editorWindow(), browserWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        #expect(model.isSavePresented)
        #expect(model.draftName == manager.suggestedName())
        #expect(model.draftIcon == Workspace.defaultIcon)

        // Wait for the async candidate fetch the sheet kicked off.
        try await waitFor { !model.availableWindows.isEmpty }
        #expect(model.availableWindows.count == 2)
        // Every candidate starts selected so the common case is one click.
        #expect(model.selectedWindowIDs.count == 2)
    }

    @Test("Saving the draft persists a workspace and closes the sheet")
    func saveDraftPersists() async throws {
        let manager = makeManager(windows: [editorWindow(), browserWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        try await waitFor { !model.availableWindows.isEmpty }
        model.draftName = "Coding"
        model.draftIcon = "hammer"
        await model.saveDraft()

        #expect(model.errorMessage == nil)
        #expect(!model.isSavePresented)
        #expect(model.workspaces.count == 1)
        #expect(model.workspaces.first?.name == "Coding")
        #expect(model.workspaces.first?.icon == "hammer")
        #expect(model.workspaces.first?.placements.count == 2)
    }

    @Test("E2 — an empty name keeps the sheet open with an inline error")
    func saveEmptyName() async throws {
        let manager = makeManager(windows: [editorWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        try await waitFor { !model.availableWindows.isEmpty }
        model.draftName = "   "
        await model.saveDraft()

        #expect(model.isSavePresented)
        #expect(model.errorMessage == "Enter a name for this workspace.")
        #expect(model.workspaces.isEmpty)
    }

    @Test("E1 — a duplicate name is rejected with the offending name")
    func saveDuplicateName() async throws {
        let manager = makeManager(windows: [editorWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        try await waitFor { !model.availableWindows.isEmpty }
        model.draftName = "Coding"
        await model.saveDraft()
        #expect(model.workspaces.count == 1)

        // Second save with the same (case-insensitive) name fails.
        model.presentSaveSheet()
        try await waitFor { !model.availableWindows.isEmpty }
        model.draftName = "coding"
        await model.saveDraft()

        #expect(model.isSavePresented)
        #expect(model.errorMessage == "A workspace named “coding” already exists.")
        #expect(model.workspaces.count == 1)
    }

    @Test("E3 — saving with nothing selected explains why and keeps the sheet open")
    func saveNoEligibleWindows() async throws {
        let manager = makeManager(windows: [editorWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        try await waitFor { !model.availableWindows.isEmpty }
        // The user unticks every candidate, so capture has nothing to work with.
        model.selectedWindowIDs = []
        model.draftName = "Empty"
        await model.saveDraft()

        #expect(model.isSavePresented)
        #expect(model.errorMessage?.contains("No windows") == true)
        #expect(model.workspaces.isEmpty)
    }

    @Test("E11 — capture without Accessibility surfaces a permission message")
    func captureDenied() async throws {
        let manager = makeManager(windows: [editorWindow()], trusted: false)
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        try await waitFor { model.errorMessage != nil }
        #expect(model.availableWindows.isEmpty)
        #expect(model.errorMessage == "FlowSnap needs Accessibility permission to see your windows.")
    }

    @Test("Toggling a candidate deselects it so it is not captured")
    func toggleSelection() async throws {
        let manager = makeManager(windows: [editorWindow(), browserWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        model.presentSaveSheet()
        try await waitFor { model.availableWindows.count == 2 }
        let browser = model.availableWindows.first { $0.bundleIdentifier == "com.browser" }
        #expect(browser != nil)
        if let browser { model.toggle(browser) }
        #expect(model.selectedWindowIDs.count == 1)

        model.draftName = "Editor only"
        await model.saveDraft()
        #expect(model.workspaces.first?.placements.count == 1)
        #expect(model.workspaces.first?.placements.first?.bundleIdentifier == "com.editor")
    }

    // MARK: - Restore flow (J2)

    @Test("A successful restore surfaces its summary")
    func restoreSurfacesSummary() async throws {
        let mover = MockWindowManaging()
        let manager = makeManager(windows: [editorWindow()], windowManager: mover)
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        // Create a workspace first.
        model.presentSaveSheet()
        try await waitFor { !model.availableWindows.isEmpty }
        model.draftName = "Coding"
        await model.saveDraft()
        let saved = try #require(model.workspaces.first)

        await model.restore(saved)

        #expect(model.errorMessage == nil)
        let summary = try #require(model.lastRestoreSummary)
        #expect(summary.placedCount == 1)
        #expect(summary.totalPlacements == 1)
        #expect(mover.moveCallCount >= 1)
    }

    @Test("A partial restore reports the skipped app in the summary")
    func restorePartialSurfacesSkips() async throws {
        // Editor is running; browser is not installed → one placed, one skipped.
        let launcher = MockApplicationLaunching(installedBundleIDs: [])
        let manager = makeManager(windows: [editorWindow()], launcher: launcher)
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        let created = try await manager.saveWorkspace(named: "Both", placements: [
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightHalf, orderIndex: 1)
        ])

        await model.restore(created)

        let summary = try #require(model.lastRestoreSummary)
        #expect(summary.placedCount == 1)
        #expect(summary.totalPlacements == 2)
        #expect(summary.skipped.map(\.bundleIdentifier) == ["com.browser"])
        // The skipped app is named in the headline (appName derives "browser").
        #expect(summary.headline.contains("browser"))
    }

    @Test("E11 — restore without Accessibility surfaces a permission message")
    func restoreDenied() async throws {
        let manager = makeManager(windows: [editorWindow()], trusted: false)
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)

        let created = try await manager.saveWorkspace(
            named: "Coding",
            placements: [WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]
        )
        await model.restore(created)

        #expect(model.lastRestoreSummary == nil)
        #expect(model.errorMessage == "FlowSnap needs Accessibility permission to move windows.")
    }

    // MARK: - Rename / delete (spec §4.5)

    @Test("Renaming updates the published list")
    func renameUpdatesList() async throws {
        let manager = makeManager(windows: [editorWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)
        let created = try await manager.saveWorkspace(
            named: "Old", placements: [WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]
        )

        await model.rename(created, to: "New")
        #expect(model.errorMessage == nil)
        #expect(model.workspaces.first?.name == "New")
    }

    @Test("E1 — renaming onto an existing name is rejected")
    func renameDuplicate() async throws {
        let manager = makeManager(windows: [editorWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)
        let alpha = try await manager.saveWorkspace(
            named: "Alpha", placements: [WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]
        )
        _ = try await manager.saveWorkspace(
            named: "Beta", placements: [WindowPlacement(bundleIdentifier: "com.editor", zone: .rightHalf)]
        )

        await model.rename(alpha, to: "beta")
        #expect(model.errorMessage == "A workspace named “beta” already exists.")
        #expect(model.workspaces.first(where: { $0.id == alpha.id })?.name == "Alpha")
    }

    @Test("Deleting removes the workspace from the list")
    func deleteRemoves() async throws {
        let manager = makeManager(windows: [editorWindow()])
        await manager.reload()
        let model = WorkspaceViewModel(manager: manager)
        let created = try await manager.saveWorkspace(
            named: "Coding", placements: [WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]
        )
        #expect(model.workspaces.count == 1)

        await model.delete(created)
        #expect(model.errorMessage == nil)
        #expect(model.workspaces.isEmpty)
    }

    // MARK: - Helpers

    /// Polls until `condition` holds or the deadline passes, so a test can await
    /// the fire-and-forget task `presentSaveSheet` starts without a fixed sleep.
    private func waitFor(
        timeout: Duration = .seconds(2),
        condition: () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if condition() { return }
            try await Task.sleep(nanoseconds: 5_000_000)
        }
        Issue.record("Condition not met within \(timeout)")
    }
}
