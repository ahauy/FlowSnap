import CoreGraphics
import Foundation

/// Direction of cross-display workspace migration.
public enum MigrationDirection: String, Sendable, Codable, CaseIterable {
    case next
    case previous
}

/// Result of one best-effort cross-display workspace migration pass.
///
/// The pass moves window by window and keeps going when a window refuses the move
/// (same discipline as `WorkspaceRestoring`): an aborted half-migration leaves the
/// user with a layout split across two displays and nothing to undo it with, while a
/// completed pass with recorded failures is both recoverable and reportable.
public enum MigrationResult: Equatable, Sendable {
    /// The pass moved at least one window onto `targetDisplayID`.
    ///
    /// `windowsMigrated` counts the windows that landed; `skipped` carries the ones
    /// that refused, in attempt order, so a partial pass still renders as one line.
    case success(windowsMigrated: Int, targetDisplayID: CGDirectDisplayID, skipped: [SkippedApp])

    /// Nothing on screen changed. `reason` says why, and what to do about it.
    case noOp(reason: NoOpReason)

    public enum NoOpReason: Equatable, Sendable {
        case singleDisplay
        case noActiveWorkspace
        case noWindowsFound
        case accessibilityDenied

        /// Every window was attempted and every move was refused, so the layout did
        /// not move at all — reported with the counts rather than as silence.
        case allMovesFailed(attempted: Int, skipped: [SkippedApp])
    }

    /// One-line outcome for the existing `RestoreSummaryBanner`.
    ///
    /// Every case — including the silent no-ops — produces a summary, so no
    /// migration outcome can end with the user pressing the shortcut and seeing
    /// nothing.
    public var restoreSummary: RestoreSummary {
        switch self {
        case .success(let windowsMigrated, _, let skipped):
            return MigrationResult.summary(
                moved: windowsMigrated,
                attempted: windowsMigrated + skipped.count,
                skipped: skipped
            )
        case .noOp(.allMovesFailed(let attempted, let skipped)):
            return MigrationResult.summary(moved: 0, attempted: attempted, skipped: skipped)
        case .noOp(let reason):
            // `totalPlacements: 1` is what puts the banner in its warning state: a
            // 0/0 summary would read as `isFullSuccess` and render green.
            return RestoreSummary(
                placedCount: 0,
                totalPlacements: 1,
                headlineOverride: reason.userMessage
            )
        }
    }

    private static func summary(moved: Int, attempted: Int, skipped: [SkippedApp]) -> RestoreSummary {
        var headline = "Moved \(moved)/\(attempted)"
        if !skipped.isEmpty {
            headline += " — \(skipped.map(\.displayReason).joined(separator: ", "))"
        }
        if moved == 0 && !skipped.isEmpty {
            headline += ". Unlock them and try again."
        }
        return RestoreSummary(
            placedCount: moved,
            totalPlacements: attempted,
            skipped: skipped,
            headlineOverride: headline
        )
    }
}

/// Plain-language next step per no-op reason; never a bare "failed".
public extension MigrationResult.NoOpReason {
    var userMessage: String {
        switch self {
        case .singleDisplay:
            return "Only one display is connected — plug in a second one, then migrate again."
        case .noActiveWorkspace:
            return "No workspace is active on this display — save or restore one first, then migrate."
        case .noWindowsFound:
            return "No windows of the active workspace are on this display — snap them here, then migrate again."
        case .accessibilityDenied:
            return "FlowSnap needs Accessibility permission to move windows — enable it in System Settings › Privacy & Security."
        case .allMovesFailed:
            return "Every window refused to move — unlock them and migrate again."
        }
    }
}

/// Protocol defining whole-layout workspace migration across displays in one pass.
///
/// Traces to: US-DISP-017, BR-MIG-001..005.
@MainActor
public protocol WorkspaceMigrating: AnyObject {
    /// Migrates the active workspace on the current display in the specified direction.
    ///
    /// Individual window moves never throw: they are recorded in `skipped`.
    ///
    /// - Parameter direction: .next or .previous.
    /// - Returns: MigrationResult with the moved vs refused counts, or the reason for a no-op.
    func migrateActiveWorkspace(
        direction: MigrationDirection
    ) async throws -> MigrationResult
}
