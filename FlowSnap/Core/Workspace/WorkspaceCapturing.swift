import CoreGraphics
import Foundation

/// A window offered by the capture picker (data-model.md §1 — WindowGroupSnapshot).
///
/// A thin value snapshot of `ManagedWindow` carrying only what the picker needs to
/// draw a row and what capture needs to derive a zone. Deliberately not
/// `ManagedWindow` itself: the picker must not be able to reach AX elements.
///
/// Traces to: data-model.md §1, spec §2 J1.2.
public struct WindowGroupSnapshot: Equatable, Hashable, Identifiable, Sendable {

    /// Stable picker identity. Window ids are unique per Window Server session, so
    /// pairing one with the bundle id identifies a window within a capture pass.
    public var id: String { "\(bundleIdentifier):\(windowID)" }

    public let bundleIdentifier: String
    public let windowID: CGWindowID
    public let title: String

    /// Current window frame (CG coordinates, top-left origin), used to derive the
    /// nearest `LayoutZone` and the display it sits on.
    public let frame: CGRect

    /// Whether the app is already tracked in the workspace being edited, so the
    /// picker can mark it instead of offering a duplicate (spec §4.5, ASM-WORK-002).
    public let isAlreadyTracked: Bool

    public init(
        bundleIdentifier: String,
        windowID: CGWindowID,
        title: String = "",
        frame: CGRect = .zero,
        isAlreadyTracked: Bool = false
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.windowID = windowID
        self.title = title
        self.frame = frame
        self.isAlreadyTracked = isAlreadyTracked
    }

    public init?(window: ManagedWindow, isAlreadyTracked: Bool = false) {
        // A window with no bundle id belongs to a process Launch Services could
        // not resolve; there is no intent to save for it, so it is not offerable.
        guard let bundleIdentifier = window.bundleIdentifier else { return nil }
        self.init(
            bundleIdentifier: bundleIdentifier,
            windowID: window.id,
            title: window.title,
            frame: window.frame,
            isAlreadyTracked: isAlreadyTracked
        )
    }

    /// Title for display, with a fallback for untitled windows.
    public var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Untitled window"
            : title
    }
}

/// Errors raised while capturing windows into a workspace (contracts §3).
public enum WindowCaptureError: Error, Equatable, Sendable {

    /// E11 — Accessibility permission is missing, so there is no window list.
    case accessibilityDenied

    /// E3 — every on-screen window was filtered out. Carries the breakdown so the
    /// UI can explain *why* rather than showing a bare "no windows".
    case noEligibleWindows(NoEligibleWindowsDetail)

    /// E9 — the workspace already holds the maximum number of placements.
    case placementLimitReached(limit: Int)

    /// Detail behind `noEligibleWindows` (spec §5 E3: "explain why").
    public struct NoEligibleWindowsDetail: Equatable, Hashable, Sendable {

        /// Windows seen before filtering.
        public let seen: Int

        /// Dropped because they belong to FlowSnap itself (BR-WORK-001).
        public let ownPanels: Int

        /// Dropped because they are not normal windows — system UI, dialogs,
        /// sheets, utilities, fullscreen tiles (BR-WORK-001).
        public let nonNormal: Int

        /// Dropped because they have no area (minimized or zero-sized).
        public let zeroArea: Int

        public init(seen: Int, ownPanels: Int, nonNormal: Int, zeroArea: Int) {
            self.seen = seen
            self.ownPanels = ownPanels
            self.nonNormal = nonNormal
            self.zeroArea = zeroArea
        }

        /// Human-readable explanation for the alert (E3).
        public var message: String {
            guard seen > 0 else { return "No windows are on screen right now." }
            var reasons: [String] = []
            if nonNormal > 0 { reasons.append("\(nonNormal) not standard windows") }
            if ownPanels > 0 { reasons.append("\(ownPanels) are FlowSnap's own") }
            if zeroArea > 0 { reasons.append("\(zeroArea) are hidden or zero-sized") }
            guard !reasons.isEmpty else { return "No windows are eligible for capture." }
            return "Nothing to capture — \(reasons.joined(separator: ", "))."
        }
    }
}

/// Turns the live window list into workspace placements (contracts §3).
///
/// Implemented by `WorkspaceManager`, which owns the Accessibility and display
/// services the capture needs. Capture is pure with respect to persistence: it
/// never writes to the store, so the caller controls when a workspace is created
/// (spec §2 J1.4).
public protocol WorkspaceCapturing: Sendable {

    /// On-screen windows the user may add, with the same eligibility rules capture
    /// applies (BR-WORK-001) so the picker never offers a window that capture
    /// would silently drop.
    func eligibleWindows(for tracked: Set<String>) async throws -> [WindowGroupSnapshot]

    /// Builds placements from the windows the user selected.
    func capture(from selections: [WindowGroupSnapshot]) async throws -> [WindowPlacement]
}
