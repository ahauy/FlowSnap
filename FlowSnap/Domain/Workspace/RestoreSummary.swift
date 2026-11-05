import Foundation

/// Why a placement could not be restored (data-model.md §1 — SkippedApp).
///
/// The spec deliberately avoids a binary success/failure model: an app that is
/// not installed, one that launches but never shows a window, and one whose
/// window simply isn't there are three different user experiences, each needing
/// its own line in the summary (BR-WORK-004, spec §5 E4–E5).
///
/// A restore still treats a refused move as good enough (E6 — best effort,
/// logged): the user's observable outcome is "the window is where it was before".
/// `.notMoved` is the exception for passes where a refused move leaves the user's
/// layout split across displays, i.e. cross-display migration.
public enum SkipReason: String, Codable, Equatable, Hashable, Sendable {

    /// E4 — no app is installed for this bundle identifier.
    case notInstalled

    /// E5 — the app launched but exposed no normal window within the 10s budget.
    case launchTimeout

    /// E5 — the app was already running but had no matching window (E10: fewer
    /// windows than at save time is not an error for the *others*).
    case noWindow

    /// A window that was there but refused the move (fixed-size panel, modal, AX
    /// failure). Unlike a restore, cross-display migration reports these rather
    /// than counting them as placed, because the user is left looking at a layout
    /// split across two displays.
    case notMoved
}

/// An app that restore could not place, with the reason (data-model.md §1).
public struct SkippedApp: Equatable, Hashable, Identifiable, Sendable {

    public var id: String { "\(bundleIdentifier):\(reason.rawValue)" }

    public let bundleIdentifier: String
    public let reason: SkipReason

    public init(bundleIdentifier: String, reason: SkipReason) {
        self.bundleIdentifier = bundleIdentifier
        self.reason = reason
    }

    /// User-facing reason text (spec §4.5 — plain language, not bundle-id soup).
    public var displayReason: String {
        let name = Self.appName(bundleIdentifier)
        switch reason {
        case .notInstalled: return "\(name) not installed"
        case .launchTimeout: return "\(name) took too long to open"
        case .noWindow: return "\(name) not running"
        case .notMoved: return "\(name) couldn't be moved"
        }
    }

    /// Turns "com.microsoft.VSCode" into "VSCode" for a readable message when no
    /// friendlier name is available from the running-app list.
    static func appName(_ bundleIdentifier: String) -> String {
        let last = bundleIdentifier.split(separator: ".").last.map(String.init) ?? bundleIdentifier
        return last.isEmpty ? bundleIdentifier : last
    }
}

/// The result of one placement pass — a restore, or a cross-display migration
/// (data-model.md §1, spec §2 J2.6).
///
/// ADR-002: assembled from the placement loop's per-app results rather than
/// accumulated ad hoc, so the counting rules live in one place and are
/// unit-testable without any Accessibility or AppKit calls.
public struct RestoreSummary: Equatable, Hashable, Sendable {

    /// Placements whose window(s) were successfully moved into their zone.
    public let placedCount: Int

    /// Total placements attempted.
    public let totalPlacements: Int

    /// Apps that could not be placed, in restore order.
    public let skipped: [SkippedApp]

    /// Wording for passes whose outcome is not a "restore" (cross-display
    /// migration, advisory no-ops). Shown verbatim by `headline` so those callers
    /// reuse this summary and its banner instead of inventing a parallel type.
    public let headlineOverride: String?

    public init(
        placedCount: Int,
        totalPlacements: Int,
        skipped: [SkippedApp] = [],
        headlineOverride: String? = nil
    ) {
        self.placedCount = placedCount
        self.totalPlacements = totalPlacements
        self.skipped = skipped
        self.headlineOverride = headlineOverride
    }

    /// Everything landed (spec §4.5 success state).
    public var isFullSuccess: Bool { skipped.isEmpty && placedCount == totalPlacements }

    /// Nothing to restore (an empty workspace).
    public var isEmpty: Bool { totalPlacements == 0 }

    /// Headline text, e.g. "Restored 3/3" or "Restored 2/3 — VS Code not running".
    public var headline: String {
        if let headlineOverride { return headlineOverride }
        guard !isEmpty else { return "Nothing to restore" }
        guard !skipped.isEmpty else { return "Restored \(placedCount)/\(totalPlacements)" }
        let reasons = skipped.map(\.displayReason)
        return "Restored \(placedCount)/\(totalPlacements) — \(reasons.joined(separator: ", "))"
    }

    /// Per-app detail lines for the summary area.
    public var details: [String] {
        skipped.map { "\($0.bundleIdentifier): \($0.displayReason)" }
    }
}

/// Errors raised while saving, renaming or restoring a workspace (contracts §5).
public enum WorkspaceError: Error, Equatable, Sendable {

    /// E2 — name was empty or whitespace-only.
    case invalidName

    /// E1 / BR-WORK-008 — another workspace already uses this name
    /// (case-insensitively).
    case duplicateName(String)

    /// E3 — no eligible on-screen windows; nothing was persisted.
    case noEligibleWindows

    /// E11 — Accessibility permission is missing; restore aborted before any move.
    case accessibilityDenied

    /// E7 / E14 — the persistence layer failed.
    case storeFailure(WorkspaceStoreError)
}
