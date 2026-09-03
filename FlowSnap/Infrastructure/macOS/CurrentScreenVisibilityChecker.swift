import CoreGraphics
import Foundation

/// Best-effort observation of whether a window is currently on the user's screen.
///
/// This is a **presentation observation, not a Space resolver**. The
/// implementation only knows whether a window id appears in the WindowServer's
/// on-screen list at the moment of observation — it can never identify *which*
/// Space a window belongs to, and must not pretend to (P0.5 spec §3.1; private
/// SkyLight/CGS and the deprecated `kCGWindowWorkspace` key are out of bounds).
///
/// Two lookups:
///   * `isOnCurrentScreen(windowID:)` — primary lookup by `CGWindowID` (the id
///     captured while resolving the placement's windows).
///   * `reResolveWindowID(pid:frame:)` — secondary lookup by `(pid, frame)`,
///     used exclusively after a successful full-screen exit, where some apps
///     (Chromium/Electron) destroy and recreate their window, invalidating the
///     captured id (P0.5 spec §4.5).
///
/// Traces to: ADR-0008, docs/RESTORE_CROSSSPACE_ANALYSIS.md §J.1.
public protocol CurrentScreenVisibilityChecking: Sendable {

    /// Observes whether the window with `windowID` is on the current screen.
    func isOnCurrentScreen(windowID: CGWindowID) -> OnScreenObservationResult

    /// Re-resolves the current `CGWindowID` of the window owned by `pid` whose
    /// bounds sit at `frame`, or `nil` when no on-screen entry matches.
    ///
    /// Deliberately returns `nil` instead of a synthetic id: a guessed identity
    /// is worse than no identity, because the caller would rather report the
    /// presentation as unverifiable than observe (or mis-observe) a different
    /// window.
    func reResolveWindowID(pid: pid_t, frame: CGRect) -> CGWindowID?
}

/// The three observable states of an on-screen presentation check.
public enum OnScreenObservationResult: Equatable, Sendable {

    /// The window id is present in the WindowServer's on-screen list.
    case presented

    /// The window id is absent from the on-screen list — for a window that was
    /// just moved and AX-verified this is the cross-Space / hidden signature.
    case notPresented

    /// The check itself could not be performed; presentation is unknown.
    case unverifiable(reason: ObservationFailure)
}

/// Why an observation could not be performed (P0.5 spec §3.3.5).
public enum ObservationFailure: Equatable, Hashable, Sendable {

    /// `CGWindowListCopyWindowInfo` failed or returned nothing usable.
    case cgWindowListUnavailable

    /// The window identity could not be established (zero id, or the entry
    /// belongs to FlowSnap itself).
    case identityNotResolved

    /// The WindowServer state was transiently unreadable.
    case transient
}

// swiftlint:disable type_name
// The type name below is mandated verbatim by the P0.5 spec (Step 1) and
// exceeds the default 40-character rule by 3 characters.
/// Production `CurrentScreenVisibilityChecking` backed by the public
/// `CGWindowListCopyWindowInfo` API.
///
/// Zero private API: the on-screen list is the same public snapshot
/// `AXAccessibilityService.allVisibleManagedWindows()` is built on
/// (`[.optionOnScreenOnly, .excludeDesktopElements]`), which drops minimized,
/// hidden and other-Space windows — exactly the signal this observation needs.
public final class CGWindowListCurrentScreenVisibilityChecker: CurrentScreenVisibilityChecking {
// swiftlint:enable type_name

    /// Bounds-matching tolerance for `(pid, frame)` re-resolution, mirroring
    /// the 5pt origin rule the AX-side resolver applies.
    static let frameMatchTolerance: CGFloat = 5

    public init() {}

    public func isOnCurrentScreen(windowID: CGWindowID) -> OnScreenObservationResult {
        guard windowID != 0 else { return .unverifiable(reason: .identityNotResolved) }
        guard let windowList = onScreenWindowList() else {
            return .unverifiable(reason: .cgWindowListUnavailable)
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        for info in windowList {
            // Normal layer only — the same filter every app-window snapshot in
            // the codebase applies, so desktop elements and overlays never
            // satisfy an observation.
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let number = info[kCGWindowNumber as String] as? CGWindowID, number == windowID else { continue }
            // FlowSnap's own panels never count as a presented window.
            if let pid = info[kCGWindowOwnerPID as String] as? pid_t, pid == ownPID {
                return .unverifiable(reason: .identityNotResolved)
            }
            return .presented
        }

        // The id is not on screen. For a window that was moved and AX-verified
        // moments earlier, absence is the not-presented signature (other Space,
        // hidden, minimized) rather than an unknown state.
        return .notPresented
    }

    public func reResolveWindowID(pid: pid_t, frame: CGRect) -> CGWindowID? {
        guard let windowList = onScreenWindowList() else { return nil }

        for info in windowList {
            guard let windowPID = info[kCGWindowOwnerPID as String] as? pid_t, windowPID == pid else { continue }
            guard let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else { continue }
            if abs(bounds.origin.x - frame.origin.x) < Self.frameMatchTolerance
                && abs(bounds.origin.y - frame.origin.y) < Self.frameMatchTolerance {
                return info[kCGWindowNumber as String] as? CGWindowID
            }
        }
        return nil
    }

    /// The WindowServer's on-screen window list, or `nil` when the API fails.
    private func onScreenWindowList() -> [[String: Any]]? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        return CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
    }
}
