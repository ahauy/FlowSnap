import Foundation

/// How a restore pass should treat apps that are not currently running
/// (data-model.md §1 — RestoreOptions).
///
/// `launchOfflineApps` is the default and the whole point of the feature (J2.2):
/// a workspace is an *intent*, so "my editor isn't running" is something to fix,
/// not something to skip. Turning it off is the escape hatch for a user who wants
/// positions fixed without starting a dozen apps.
public struct RestoreOptions: Equatable, Hashable, Sendable {

    /// Launch apps that are not currently running (BR-WORK-003).
    public var launchOfflineApps: Bool

    /// Cascade extra windows of the same app inside their zone (ASM-WORK-002).
    public var cascadeExtraWindows: Bool

    public init(launchOfflineApps: Bool = true, cascadeExtraWindows: Bool = true) {
        self.launchOfflineApps = launchOfflineApps
        self.cascadeExtraWindows = cascadeExtraWindows
    }

    /// The behaviour the menu's "Restore" item uses.
    public static let `default` = RestoreOptions()

    /// A pure reposition pass: never launch, never cascade.
    public static let positionOnly = RestoreOptions(launchOfflineApps: false, cascadeExtraWindows: false)
}

/// Errors raised by a restore pass (contracts §4).
public enum RestoreError: Error, Equatable, Sendable {

    /// E11 — Accessibility permission is missing; aborted before any move.
    case accessibilityDenied

    /// E8 — the workspace has no placements; nothing was attempted.
    case emptyWorkspace

    /// E14 — the store could not record `lastRestoredAt`. The moves themselves
    /// already happened, so this is surfaced as a warning, never as a failure of
    /// the restore (spec §5 E14).
    case storeFailure(WorkspaceStoreError)
}

/// Applies a workspace's layout intents to live windows (contracts §4).
///
/// Implemented by `WorkspaceManager` (ADR-002). The pass is **best-effort**:
/// per-placement problems are recorded in the `RestoreSummary` and the loop
/// continues, because a workspace whose one missing app aborted the whole restore
/// would be worse than useless (BR-WORK-004).
public protocol WorkspaceRestoring: Sendable {

    /// Restores every placement in a workspace.
    ///
    /// - Returns: a summary of what was placed and what was skipped.
    /// - Throws: only pass-level failures (`RestoreError`). Per-app problems come
    ///   back in the summary instead.
    func restore(workspace: Workspace, options: RestoreOptions) async throws -> RestoreSummary

    /// Resolves a zone to a concrete frame on the display a window currently
    /// occupies (BR-WORK-007). Exposed so the UI can preview a zone without
    /// moving anything.
    func frame(for zone: LayoutZone, windowFrame: CGRect) async -> CGRect
}
