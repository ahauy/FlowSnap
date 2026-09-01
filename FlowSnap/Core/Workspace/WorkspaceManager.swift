import CoreGraphics
import Foundation
import SwiftUI

/// Owns the user's saved workspaces: capture, save, rename, delete, restore.
///
/// ADR-002: this one `@MainActor ObservableObject` implements both
/// `WorkspaceCapturing` and `WorkspaceRestoring` rather than splitting them into
/// separate engines, because capture and restore are two directions over the same
/// state (the workspace list, the store, the display topology) and the project
/// already composes services this way (`AdaptiveDividerCoordinator` owns drag +
/// commit + clamp).
///
/// The published `workspaces` array is the single source of truth for the UI;
/// every mutation goes UI → manager → store → refresh, so a SwiftUI list can bind
/// directly without a second cache to keep in sync.
///
/// Traces to: data-model.md §5, contracts §1–§4.
@MainActor
public final class WorkspaceManager: ObservableObject {

    // MARK: - Published state

    /// All saved workspaces, most recently touched first.
    @Published public private(set) var workspaces: [Workspace] = []

    /// E7/E14 — a store problem the UI must explain, with a retry affordance.
    @Published public private(set) var storeError: WorkspaceStoreError?

    /// Result of the most recent restore, shown inline in the menu (spec §4.5).
    @Published public private(set) var lastRestoreSummary: RestoreSummary?

    /// The workspace whose restore is currently running, so the UI can disable
    /// the row and show progress instead of letting a second click pile up.
    @Published public private(set) var restoringID: UUID?

    // MARK: - Dependencies

    // Internal rather than private: the capture and restore extensions live in
    // their own files (`WorkspaceManager+Capture.swift`,
    // `WorkspaceManager+Restore.swift`) and need access to them.

    let store: WorkspaceStore
    let accessibilityService: any AccessibilityService
    let windowManager: any WindowManaging
    let displayManager: any DisplayManaging
    let layoutEngine: any LayoutCalculating
    let launcher: any ApplicationLaunching
    let preferences: PreferencesStore

    /// How long to wait for a launched app's first window (BR-WORK-003).
    let launchTimeout: TimeInterval

    /// Bundle id of FlowSnap itself — its own panels are never captured
    /// (BR-WORK-001).
    let ownBundleIdentifier: String?

    public init(
        store: WorkspaceStore = WorkspaceStore(),
        accessibilityService: any AccessibilityService = AXAccessibilityService(),
        windowManager: (any WindowManaging)? = nil,
        displayManager: any DisplayManaging = DisplayManager(),
        layoutEngine: any LayoutCalculating = LayoutEngine(),
        launcher: (any ApplicationLaunching)? = nil,
        preferences: PreferencesStore = PreferencesStore(),
        launchTimeout: TimeInterval = LaunchTiming.windowTimeout,
        ownBundleIdentifier: String? = Bundle.main.bundleIdentifier,
        loadAtInit: Bool = true
    ) {
        self.store = store
        self.accessibilityService = accessibilityService
        // WindowManager and AppLauncher both sit on top of the accessibility
        // service, so they are resolved here rather than as default arguments —
        // Swift forbids one parameter appearing in another's default value.
        self.windowManager = windowManager ?? WindowManager(accessibilityService: accessibilityService)
        self.displayManager = displayManager
        self.layoutEngine = layoutEngine
        // Default the launcher to one bound to *this* manager's accessibility
        // service, so a test that injects only a mock AX service does not also
        // have to hand-build a launcher.
        self.launcher = launcher ?? AppLauncher(accessibilityService: accessibilityService)
        self.preferences = preferences
        self.launchTimeout = launchTimeout
        self.ownBundleIdentifier = ownBundleIdentifier
        if loadAtInit {
            Task { @MainActor [weak self] in
                await self?.reload()
            }
        }
    }

    // MARK: - Loading

    /// Re-reads the store and refreshes the published list (contracts §1).
    ///
    /// Degrades to an empty list plus a surfaced `storeError` on failure — the app
    /// stays usable and the UI can offer "Retry" (E7).
    public func reload() async {
        do {
            workspaces = try await store.loadWorkspaces()
            storeError = nil
        } catch let error as WorkspaceStoreError {
            workspaces = []
            storeError = error
        } catch {
            workspaces = []
            storeError = .writeFailed
        }
    }

    /// Clears a surfaced store error after the user acknowledged it (spec §4.5).
    public func dismissStoreError() {
        storeError = nil
    }

    /// A single workspace by id.
    public func workspace(id: UUID) -> Workspace? {
        workspaces.first { $0.id == id }
    }

    // MARK: - Save / rename / delete (contracts §5)

    /// Creates a new workspace from captured placements.
    ///
    /// - Throws: `WorkspaceError.invalidName` (E2), `.duplicateName` (E1),
    ///   `.noEligibleWindows` (E3), `.storeFailure` (E14). Nothing is persisted
    ///   when a validation error is thrown.
    @discardableResult
    public func saveWorkspace(
        named name: String,
        icon: String = Workspace.defaultIcon,
        placements: [WindowPlacement]
    ) async throws -> Workspace {
        let trimmed = Workspace.trimmed(name)
        guard Workspace.isValidName(trimmed) else {
            throw WorkspaceError.invalidName
        }
        guard !placements.isEmpty else {
            throw WorkspaceError.noEligibleWindows
        }
        guard !isNameTaken(trimmed) else {
            throw WorkspaceError.duplicateName(trimmed)
        }

        let workspace = Workspace(name: trimmed, icon: icon, placements: placements).normalized
        do {
            try await store.upsert(workspace)
        } catch {
            throw WorkspaceError.storeFailure(Self.storeError(from: error))
        }
        await reload()
        return workspace
    }

    /// Renames an existing workspace (spec §4.5).
    @discardableResult
    public func rename(id: UUID, to name: String) async throws -> Workspace {
        let trimmed = Workspace.trimmed(name)
        guard Workspace.isValidName(trimmed) else { throw WorkspaceError.invalidName }
        guard let existing = workspace(id: id) else { throw WorkspaceError.invalidName }
        guard !isNameTaken(trimmed, excluding: id) else {
            throw WorkspaceError.duplicateName(trimmed)
        }
        var updated = existing
        updated.name = trimmed
        updated = updated.normalized
        do {
            try await store.upsert(updated)
        } catch {
            throw WorkspaceError.storeFailure(Self.storeError(from: error))
        }
        await reload()
        return updated
    }

    /// Changes a workspace's icon.
    @discardableResult
    public func setIcon(id: UUID, icon: String) async throws -> Workspace {
        try await mutate(id: id) { workspace in
            var updated = workspace
            updated.icon = icon
            return updated
        }
    }

    /// Deletes a workspace (the UI owns the confirmation dialog, spec §4.5).
    public func delete(id: UUID) async throws {
        do {
            try await store.deleteWorkspace(id: id)
        } catch {
            throw WorkspaceError.storeFailure(Self.storeError(from: error))
        }
        if lastRestoreSummary != nil, workspace(id: id) == nil {
            // The summary refers to something that no longer exists.
            lastRestoreSummary = nil
        }
        await reload()
    }

    /// Whether a name is already claimed, case-insensitively (BR-WORK-008).
    public func isNameTaken(_ name: String, excluding id: UUID? = nil) -> Bool {
        workspaces.contains { workspace in
            workspace.id != id && Workspace.isName(workspace.name, sameAs: name)
        }
    }

    /// A name that will pass the uniqueness check, for "Save current layout"
    /// pre-filling the sheet (Could-Have: duplicate-name auto-suffix).
    public func suggestedName(base: String = "Workspace") -> String {
        guard isNameTaken(base) else { return base }
        var counter = 2
        while isNameTaken("\(base) \(counter)") { counter += 1 }
        return "\(base) \(counter)"
    }

    // MARK: - Placement editing (spec §4.5 Add / Remove / Edit Layout)

    /// Adds placements to an existing workspace, skipping apps already tracked
    /// (ASM-WORK-002: one placement per app, count-aware).
    @discardableResult
    public func addPlacements(_ placements: [WindowPlacement], to id: UUID) async throws -> Workspace {
        try await mutate(id: id) { workspace in
            var updated = workspace
            for placement in placements {
                // ASM-WORK-002: one placement per app. Re-adding an app that is
                // already tracked updates its zone instead of duplicating it.
                if let index = updated.placements.firstIndex(where: {
                    $0.bundleIdentifier == placement.bundleIdentifier
                }) {
                    // Keep the app's existing slot so adding a window never
                    // reshuffles the rest of the layout.
                    var replacement = placement
                    replacement.orderIndex = updated.placements[index].orderIndex
                    updated.placements[index] = replacement
                } else {
                    var appended = placement
                    appended.orderIndex = updated.placements.count
                    updated.placements.append(appended)
                }
            }
            return updated.normalized
        }
    }

    /// Removes every placement for an app (spec §4.5 "Remove Window").
    @discardableResult
    public func removePlacement(bundleID: String, from id: UUID) async throws -> Workspace {
        try await mutate(id: id) { workspace in
            var updated = workspace
            updated.placements.removeAll { $0.bundleIdentifier == bundleID }
            return updated.normalized
        }
    }

    /// Re-assigns an app's zone (spec §4.5 "Edit Layout").
    @discardableResult
    public func setZone(_ zone: LayoutZone, for bundleID: String, in id: UUID) async throws -> Workspace {
        try await mutate(id: id) { workspace in
            var updated = workspace
            guard let index = updated.placements.firstIndex(where: { $0.bundleIdentifier == bundleID }) else {
                return updated
            }
            updated.placements[index].zone = zone
            return updated.normalized
        }
    }

    /// Replaces a workspace's placements wholesale (used by "Overwrite").
    @discardableResult
    public func setPlacements(_ placements: [WindowPlacement], of id: UUID) async throws -> Workspace {
        try await mutate(id: id) { workspace in
            var updated = workspace
            updated.placements = placements
            return updated.normalized
        }
    }

    /// Read-modify-write helper: every mutation funnels through the store so the
    /// actor serialises concurrent edits (data-model.md §5).
    private func mutate(id: UUID, _ change: (Workspace) -> Workspace) async throws -> Workspace {
        guard let existing = workspace(id: id) else { throw WorkspaceError.invalidName }
        let updated = change(existing).normalized
        do {
            try await store.upsert(updated)
        } catch {
            throw WorkspaceError.storeFailure(Self.storeError(from: error))
        }
        await reload()
        return updated
    }

    private static func storeError(from error: Error) -> WorkspaceStoreError {
        (error as? WorkspaceStoreError) ?? .writeFailed
    }

    // MARK: - Restore (contracts §4)

    /// Restores a workspace by id, resolving the summary state for the UI.
    ///
    /// - Returns: `nil` when the workspace no longer exists (deleted while the
    ///   menu was open), which the caller treats as a no-op.
    @discardableResult
    public func restoreWorkspace(id: UUID, options: RestoreOptions = .default) async throws -> RestoreSummary? {
        guard let target = workspace(id: id) else { return nil }
        // Guard against a second click piling up another pass: restore awaits
        // app launches, so it can run for seconds.
        guard restoringID == nil else { return lastRestoreSummary }
        restoringID = id
        defer { restoringID = nil }
        do {
            let summary = try await restore(workspace: target, options: options)
            lastRestoreSummary = summary
            return summary
        } catch {
            lastRestoreSummary = nil
            throw error
        }
    }

    /// Clears the inline restore summary (spec §4.5 — the user dismisses it).
    public func clearRestoreSummary() {
        lastRestoreSummary = nil
    }

    /// Whether a restore is in flight (UI disables the row while `true`).
    public var isRestoring: Bool { restoringID != nil }
}
