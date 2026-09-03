import Foundation

/// Why a placement could not be restored (data-model.md §1 — SkipReason).
///
/// The spec deliberately avoids a binary success/failure model: an app that is
/// not installed, one that launches but never shows a window, and one whose
/// window simply isn't there are three different user experiences, each needing
/// its own line in the summary (BR-WORK-004, spec §5 E4–E5).
///
/// Placement failures are intentionally kept separate from discovery skips. This
/// lets a summary distinguish a move that failed from a window whose state could
/// not be proven safely.
public enum SkipReason: String, Codable, Equatable, Hashable, Sendable {

    /// The window manager rejected the move after the allowed attempts.
    case moveFailed

    /// The post-condition could not be proven safely (for example, no exact AX
    /// element or an unreadable frame).
    case unverifiablePlacement

    /// Full-screen exit did not complete within the bounded transition budget.
    case fullscreenTransitionTimeout

    /// E4 — no app is installed for this bundle identifier.
    case notInstalled

    /// E5 — the app launched but exposed no normal window within the 10s budget.
    case launchTimeout

    /// E5 — the app was already running but had no matching window (E10: fewer
    /// windows than at save time is not an error for the *others*).
    case noWindow

    /// P0.5 — the window was moved and verified, but the on-screen observation
    /// found it absent from the current screen's WindowServer list (typically
    /// another Space). Presentation is *known* to be missing.
    case notPresentedOnCurrentScreen

    /// P0.5 — the on-screen presentation could not be observed (window identity
    /// unresolved after a full-screen exit, or the WindowServer list was
    /// unavailable). Presentation is *unknown*, not proven absent.
    case presentationUnverifiable
}

/// A reasoned issue attached to one restore placement.
///
/// `orderIndex` is retained in the ephemeral summary so callers can preserve
/// restore order when presenting or selecting the final focus target. A default
/// keeps the pre-verification `SkippedApp(bundleIdentifier:reason:)` initializer
/// source-compatible.
public struct RestoreIssue: Equatable, Hashable, Identifiable, Sendable {

    public var id: String { "\(bundleIdentifier):\(orderIndex):\(reason.rawValue)" }

    public let bundleIdentifier: String
    public let orderIndex: Int
    public let reason: SkipReason

    public init(bundleIdentifier: String, orderIndex: Int = 0, reason: SkipReason) {
        self.bundleIdentifier = bundleIdentifier
        self.orderIndex = orderIndex
        self.reason = reason
    }

    /// User-facing reason text (spec §4.5 — plain language, not bundle-id soup).
    public var displayReason: String {
        let name = Self.appName(bundleIdentifier)
        switch reason {
        case .moveFailed: return "\(name) could not be moved"
        case .unverifiablePlacement: return "\(name) placement could not be verified"
        case .fullscreenTransitionTimeout: return "\(name) could not exit full screen"
        case .notInstalled: return "\(name) not installed"
        case .launchTimeout: return "\(name) took too long to open"
        case .noWindow: return "\(name) not running"
        case .notPresentedOnCurrentScreen: return "\(name) was positioned but is not on the current screen"
        case .presentationUnverifiable: return "\(name) presentation could not be verified"
        }
    }

    /// Turns "com.microsoft.VSCode" into "VSCode" for a readable message when no
    /// friendlier name is available from the running-app list.
    static func appName(_ bundleIdentifier: String) -> String {
        let last = bundleIdentifier.split(separator: ".").last.map(String.init) ?? bundleIdentifier
        return last.isEmpty ? bundleIdentifier : last
    }
}

/// Compatibility name retained for existing discovery consumers.
public typealias SkippedApp = RestoreIssue

/// The result of one restore pass (data-model.md §1, spec §2 J2.6).
///
/// ADR-002: assembled from the placement loop's per-app results rather than
/// accumulated ad hoc, so the counting rules live in one place and are
/// unit-testable without any Accessibility or AppKit calls.
public struct RestoreSummary: Equatable, Hashable, Sendable {

    /// Placements whose window(s) were successfully moved into their zone.
    public let placedCount: Int

    /// Placements for which moving failed after the allowed attempts.
    public let failedCount: Int

    /// Placements for which success could not be proven safely.
    public let unverifiableCount: Int

    /// Placements skipped before a placement attempt (discovery/launch).
    public let skippedCount: Int

    /// P0.5 — placements that were moved and verified but are not on the
    /// user's current screen.
    public let movedButNotPresentedCount: Int

    /// Total placements attempted.
    public let totalPlacements: Int

    /// Apps that could not be placed, in restore order.
    public let failed: [RestoreIssue]
    public let unverifiable: [RestoreIssue]
    public let skipped: [RestoreIssue]
    public let movedButNotPresented: [RestoreIssue]

    public init(
        placedCount: Int,
        failedCount: Int? = nil,
        unverifiableCount: Int? = nil,
        skippedCount: Int? = nil,
        movedButNotPresentedCount: Int? = nil,
        totalPlacements: Int,
        failed: [RestoreIssue] = [],
        unverifiable: [RestoreIssue] = [],
        skipped: [RestoreIssue] = [],
        movedButNotPresented: [RestoreIssue] = []
    ) {
        self.placedCount = placedCount
        self.failed = failed
        self.unverifiable = unverifiable
        self.skipped = skipped
        self.movedButNotPresented = movedButNotPresented
        self.failedCount = failedCount ?? failed.count
        self.unverifiableCount = unverifiableCount ?? unverifiable.count
        self.skippedCount = skippedCount ?? skipped.count
        self.movedButNotPresentedCount = movedButNotPresentedCount ?? movedButNotPresented.count
        self.totalPlacements = totalPlacements
    }

    /// Everything landed (spec §4.5 success state).
    ///
    /// P0.5: "full success" also means the user can *see* every window — a
    /// moved-but-not-presented placement keeps the summary out of the green.
    public var isFullSuccess: Bool {
        failedCount == 0 && unverifiableCount == 0 && skippedCount == 0
            && movedButNotPresentedCount == 0 && placedCount == totalPlacements
    }

    /// Nothing to restore (an empty workspace).
    public var isEmpty: Bool { totalPlacements == 0 }

    /// Headline text, e.g. "Restored 3/3" or "Restored 2/3 — VS Code not running".
    public var headline: String {
        guard !isEmpty else { return "Nothing to restore" }
        let allIssues = failed + unverifiable + skipped + movedButNotPresented
        if allIssues.isEmpty {
            return "Restored \(placedCount)/\(totalPlacements)"
        }
        let reasons = allIssues.map(\.displayReason)
        return "Restored \(placedCount)/\(totalPlacements) — \(reasons.joined(separator: ", "))"
    }

    /// Per-app detail lines for the summary area.
    public var details: [String] {
        (failed + unverifiable + skipped + movedButNotPresented)
            .map { "\($0.bundleIdentifier): \($0.displayReason)" }
    }
}

/// The result of handling one placement. It is deliberately independent from
/// the aggregate summary so the restore core can process each result in order.
public struct RestorePlacementResult: Equatable, Hashable, Sendable {

    public enum Category: String, Codable, Equatable, Hashable, Sendable {
        case placed
        /// P0.5 — moved and verified, but absent from the current screen's
        /// WindowServer on-screen list (typically another Space). Distinct from
        /// `.unverifiable`: here the observation *proves* the window is not
        /// presented rather than failing to look.
        case movedButNotPresented
        case failed
        case unverifiable
        case skipped
    }

    public let bundleIdentifier: String
    public let orderIndex: Int
    public let category: Category
    public let reason: SkipReason?

    public init(
        bundleIdentifier: String,
        orderIndex: Int,
        category: Category,
        reason: SkipReason? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.orderIndex = orderIndex
        self.category = category
        self.reason = reason
    }

    public var isVerified: Bool { category == .placed && reason == nil }
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
