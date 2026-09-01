import Combine
import Foundation
import SwiftUI

/// View model behind every workspace UI surface (save sheet, menu list, settings
/// tab) for US-WORK-011.
///
/// It is a thin, testable façade over `WorkspaceManager`: the manager owns the
/// domain (capture, persistence, restore), while this type owns the *transient*
/// UI state a screen needs — the draft name/icon being typed, which windows the
/// picker has selected, whether a save is in flight, and the human-readable
/// message behind a thrown error.
///
/// Why a separate type rather than binding the views straight to the manager:
/// the manager is `@MainActor ObservableObject` with `@Published` domain state,
/// but it deliberately knows nothing about a sheet's half-typed name or a
/// multi-select picker. Keeping that ephemeral state here means the manager's
/// API stays a clean contract (contracts §3) and the screens stay declarative.
///
/// Traces to: US-WORK-011 spec §2 J1–J3, §4.5; contracts §4.
@MainActor
public final class WorkspaceViewModel: ObservableObject {

    // MARK: - Domain state mirrored from the manager

    /// The saved workspaces, kept in sync with `manager.workspaces`.
    @Published public private(set) var workspaces: [Workspace] = []

    /// A restore summary to surface after the last restore (spec §2 J2.6).
    @Published public private(set) var lastRestoreSummary: RestoreSummary?

    /// Whether a restore pass is running (rows disable while `true`).
    @Published public private(set) var isRestoring: Bool = false

    /// A persistence error surfaced by the manager (E7); `nil` when healthy.
    @Published public private(set) var storeError: WorkspaceStoreError?

    // MARK: - Save-sheet transient state

    /// Whether the "save current layout" sheet is presented.
    @Published public var isSavePresented: Bool = false

    /// The name being typed in the sheet (E1/E2 validated on save).
    @Published public var draftName: String = ""

    /// The SF Symbol chosen from the curated grid (spec §2 J1.2).
    @Published public var draftIcon: String = Workspace.defaultIcon

    /// On-screen windows the picker offers (populated by `loadCaptureCandidates`).
    @Published public private(set) var availableWindows: [WindowGroupSnapshot] = []

    /// The `WindowGroupSnapshot.id`s the user has ticked.
    @Published public var selectedWindowIDs: Set<String> = []

    /// Whether the candidate list is being fetched (picker shows a spinner).
    @Published public private(set) var isPreparingCapture: Bool = false

    /// Whether a save is being committed (Save button shows progress + disables).
    @Published public private(set) var isSaving: Bool = false

    /// Inline error text for the current screen (E1/E2/E3/E11). `nil` = no error.
    @Published public private(set) var errorMessage: String?

    /// The curated SF Symbols offered by the icon grid.
    public var iconChoices: [String] { Workspace.curatedIcons }

    // MARK: - Dependencies

    private let manager: WorkspaceManager
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Initialization

    public init(manager: WorkspaceManager) {
        self.manager = manager
        syncFromManager()
        // Mirror the manager's published domain state so a view bound only to
        // this model still updates when the manager reloads or a restore lands.
        // Subscribing to each `@Published` projected value (rather than
        // `objectWillChange`) delivers the *new* value synchronously in `willSet`,
        // so the mirror is never a runloop behind the manager.
        manager.$workspaces
            .sink { [weak self] in self?.workspaces = $0 }
            .store(in: &cancellables)
        manager.$lastRestoreSummary
            .sink { [weak self] in self?.lastRestoreSummary = $0 }
            .store(in: &cancellables)
        manager.$restoringID
            .sink { [weak self] in self?.isRestoring = $0 != nil }
            .store(in: &cancellables)
        manager.$storeError
            .sink { [weak self] in self?.storeError = $0 }
            .store(in: &cancellables)
    }

    private func syncFromManager() {
        workspaces = manager.workspaces
        lastRestoreSummary = manager.lastRestoreSummary
        isRestoring = manager.isRestoring
        storeError = manager.storeError
    }

    // MARK: - Save flow (spec §2 J1)

    /// Opens the save sheet and kicks off a capture-candidate fetch.
    ///
    /// - Parameter tracked: bundle ids already in the workspace being edited, so
    ///   the picker can mark them instead of offering a duplicate (ASM-WORK-002).
    public func presentSaveSheet(tracked: Set<String> = []) {
        errorMessage = nil
        selectedWindowIDs = []
        availableWindows = []
        draftName = manager.suggestedName()
        draftIcon = Workspace.defaultIcon
        isSavePresented = true
        Task { await loadCaptureCandidates(tracked: tracked) }
    }

    /// Closes the sheet and clears its transient state.
    public func cancelSave() {
        isSavePresented = false
        errorMessage = nil
        selectedWindowIDs = []
        availableWindows = []
    }

    /// Fetches the windows the user may add, defaulting to all of them selected.
    public func loadCaptureCandidates(tracked: Set<String> = []) async {
        isPreparingCapture = true
        errorMessage = nil
        defer { isPreparingCapture = false }
        do {
            availableWindows = try await manager.eligibleWindows(for: tracked)
            selectedWindowIDs = Set(availableWindows.map(\.id))
        } catch let error as WindowCaptureError {
            availableWindows = []
            selectedWindowIDs = []
            errorMessage = Self.message(for: error)
        } catch {
            availableWindows = []
            selectedWindowIDs = []
            errorMessage = error.localizedDescription
        }
    }

    /// Ticks or unticks one picker row.
    public func toggle(_ snapshot: WindowGroupSnapshot) {
        if selectedWindowIDs.contains(snapshot.id) {
            selectedWindowIDs.remove(snapshot.id)
        } else {
            selectedWindowIDs.insert(snapshot.id)
        }
    }

    /// Captures the selected windows and persists a new workspace (J1.3–J1.4).
    ///
    /// On success the sheet closes; on any validation error the message is shown
    /// inline and the sheet stays open so the user can fix the name/selection.
    public func saveDraft() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let selections = availableWindows.filter { selectedWindowIDs.contains($0.id) }
        do {
            let placements = try await manager.capture(from: selections)
            _ = try await manager.saveWorkspace(
                named: draftName,
                icon: draftIcon,
                placements: placements
            )
            isSavePresented = false
            syncFromManager()
        } catch let error as WorkspaceError {
            errorMessage = Self.message(for: error)
        } catch let error as WindowCaptureError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Restore / rename / delete (spec §2 J2, §4.5)

    /// Restores a workspace, surfacing the summary or an inline error.
    public func restore(_ workspace: Workspace) async {
        errorMessage = nil
        do {
            _ = try await manager.restoreWorkspace(id: workspace.id)
        } catch let error as RestoreError {
            errorMessage = Self.message(for: error)
        } catch let error as WorkspaceError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        syncFromManager()
    }

    /// Renames a workspace (E1/E2 on failure).
    public func rename(_ workspace: Workspace, to name: String) async {
        errorMessage = nil
        do {
            _ = try await manager.rename(id: workspace.id, to: name)
        } catch let error as WorkspaceError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        syncFromManager()
    }

    /// Deletes a workspace (spec §4.5 — always behind a confirm in the UI).
    public func delete(_ workspace: Workspace) async {
        errorMessage = nil
        do {
            try await manager.delete(id: workspace.id)
        } catch let error as WorkspaceError {
            errorMessage = Self.message(for: error)
        } catch {
            errorMessage = error.localizedDescription
        }
        syncFromManager()
    }

    // MARK: - Dismissals

    public func dismissError() { errorMessage = nil }
    public func clearRestoreSummary() {
        manager.clearRestoreSummary()
        syncFromManager()
    }
    public func dismissStoreError() {
        manager.dismissStoreError()
        syncFromManager()
    }

    // MARK: - Error → message mapping (spec §5)

    /// Turns a `WorkspaceError` into the inline text the UI shows.
    static func message(for error: WorkspaceError) -> String {
        switch error {
        case .invalidName:
            return "Enter a name for this workspace."
        case .duplicateName(let name):
            return "A workspace named “\(name)” already exists."
        case .noEligibleWindows:
            return "No eligible windows to save."
        case .accessibilityDenied:
            return "FlowSnap needs Accessibility permission to move windows."
        case .storeFailure:
            return "Couldn’t save your workspaces. Check your disk and try again."
        }
    }

    /// Turns a `WindowCaptureError` into the inline text the UI shows (E3 explains why).
    static func message(for error: WindowCaptureError) -> String {
        switch error {
        case .accessibilityDenied:
            return "FlowSnap needs Accessibility permission to see your windows."
        case .noEligibleWindows(let detail):
            return detail.message
        case .placementLimitReached(let limit):
            return "A workspace can hold up to \(limit) apps."
        }
    }

    /// Turns a `RestoreError` into the inline text the UI shows.
    static func message(for error: RestoreError) -> String {
        switch error {
        case .accessibilityDenied:
            return "FlowSnap needs Accessibility permission to move windows."
        case .emptyWorkspace:
            return "This workspace has no windows to restore."
        case .storeFailure:
            return "Windows were moved, but FlowSnap couldn’t record the restore."
        }
    }

    /// Turns a raw `WorkspaceStoreError` (surfaced on `manager.storeError`) into
    /// the banner text the UI shows. The corrupt-file case is the one worth
    /// explaining, since it silently degrades to an empty list otherwise (E7).
    static func message(for error: WorkspaceStoreError) -> String {
        switch error {
        case .corruptFile:
            return "Your saved workspaces couldn’t be read. The unreadable file was kept for recovery; saving again starts a fresh list."
        case .cannotCreateDirectory:
            return "FlowSnap couldn’t create its workspace folder. Check your permissions and try again."
        case .writeFailed:
            return "FlowSnap couldn’t save your workspaces. Check your disk space and try again."
        }
    }
}
