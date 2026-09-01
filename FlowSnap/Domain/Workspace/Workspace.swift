import Foundation

/// A saved workspace: a named collection of window placements that can be
/// restored together (data-model.md §1 — aggregate root).
///
/// Traces to: US-WORK-011 spec §2 J1–J3.
public struct Workspace: Codable, Equatable, Hashable, Identifiable, Sendable {

    /// Soft cap on placements per workspace (data-model.md §3). Enforced by the
    /// manager/UI, *not* by the decoder, so a hand-edited or future file with
    /// more entries still loads instead of being reported as corrupt.
    public static let maxPlacementCount = 8

    /// Default SF Symbol for workspaces created without an explicit icon.
    public static let defaultIcon = "square.grid.2x2"

    /// Curated SF Symbol set offered by the icon picker (spec §2 J1.2).
    /// Kept short and semantically obvious so the grid reads at a glance.
    public static let curatedIcons: [String] = [
        "square.grid.2x2", "hammer", "briefcase", "gamecontroller",
        "camera", "music.note", "paintbrush", "chart.bar",
        "doc.text", "envelope", "map", "airplane"
    ]

    public let id: UUID

    /// Unique case-insensitively across all workspaces (BR-WORK-008).
    public var name: String

    /// SF Symbol name for the list row icon.
    public var icon: String

    /// Ordered by `orderIndex`.
    public var placements: [WindowPlacement]

    public var createdAt: Date

    /// When the user last restored this workspace; `nil` if never.
    public var lastRestoredAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = Workspace.defaultIcon,
        placements: [WindowPlacement] = [],
        createdAt: Date = Date(),
        lastRestoredAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.placements = placements
        self.createdAt = createdAt
        self.lastRestoredAt = lastRestoredAt
    }

    // MARK: - Derived (spec §4.1 "N apps")

    /// Distinct apps in the workspace, sorted for stable UI ordering.
    public var uniqueBundleIDs: [String] {
        Array(Set(placements.map(\.bundleIdentifier))).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    /// Number of distinct apps — what the menu displays.
    public var appCount: Int { uniqueBundleIDs.count }

    /// Total windows expected across all apps.
    public var expectedWindowTotal: Int {
        placements.reduce(0) { $0 + $1.expectedWindowCount }
    }

    /// Nothing to restore (spec §4.5 empty state).
    public var isEmpty: Bool { placements.isEmpty }

    /// Placements in deterministic restore order (contracts §4 step 3).
    ///
    /// Re-sorting on read rather than trusting array order means a hand-edited
    /// file still restores predictably.
    public var orderedPlacements: [WindowPlacement] {
        placements.sorted {
            $0.orderIndex == $1.orderIndex
                ? $0.bundleIdentifier.localizedCaseInsensitiveCompare($1.bundleIdentifier) == .orderedAscending
                : $0.orderIndex < $1.orderIndex
        }
    }

    // MARK: - Normalisation (data-model.md §3)

    /// A copy satisfying the on-disk invariants: `orderIndex` renumbered to
    /// `0..<n` in restore order.
    ///
    /// Applied on every read *and* write so the rest of the app can assume the
    /// invariants hold and never has to re-check for gaps or duplicates.
    public var normalized: Workspace {
        let ordered = orderedPlacements.enumerated().map { index, placement -> WindowPlacement in
            var mutable = placement
            mutable.orderIndex = index
            return mutable
        }
        guard ordered != placements else { return self }
        var copy = self
        copy.placements = ordered
        return copy
    }

    // MARK: - Name rules (BR-WORK-008)

    /// Whether a usable name may be claimed: non-empty after trimming (E2).
    public static func isValidName(_ candidate: String) -> Bool {
        !trimmed(candidate).isEmpty
    }

    /// Case-insensitive, whitespace-trimmed name equality (BR-WORK-008).
    public static func isName(_ lhs: String, sameAs rhs: String) -> Bool {
        trimmed(lhs).caseInsensitiveCompare(trimmed(rhs)) == .orderedSame
    }

    public static func trimmed(_ candidate: String) -> String {
        candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The trimmed name this workspace should carry once saved.
    public var trimmedName: String { Self.trimmed(name) }
}
