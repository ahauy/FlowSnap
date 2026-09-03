import CoreGraphics
import Foundation
@testable import FlowSnap

/// Scriptable test double for `CurrentScreenVisibilityChecking` (P0.5 Step 7).
///
/// Both protocol methods are scriptable independently, so a test can pin the
/// re-resolve contract (T14) separately from the observation contract (T1–T5).
/// Unscripted observations default to `.presented`, which keeps every
/// presentation-agnostic restore test at its pre-P0.5 expectation.
///
/// `@unchecked Sendable`: the mutable scripting state is confined to the
/// @MainActor test that owns the manager under test, mirroring
/// `MockAccessibilityService`.
public final class MockCurrentScreenVisibilityChecker: CurrentScreenVisibilityChecking, @unchecked Sendable {

    /// Per-window observation results. Window ids absent from this map fall
    /// back to `defaultObservationResult`.
    public var observationResults: [CGWindowID: OnScreenObservationResult] = [:]

    /// Result used when a window id has no scripted entry.
    public var defaultObservationResult: OnScreenObservationResult = .presented

    /// Re-resolved ids keyed by the queried pid. Only consulted when the pid is
    /// not listed in `pidsReResolvingToNil`.
    public var reResolvedIDs: [pid_t: CGWindowID] = [:]

    /// Pids whose re-resolution is scripted to fail (return `nil`).
    public var pidsReResolvingToNil: Set<pid_t> = []

    public private(set) var isOnCurrentScreenCalls: [CGWindowID] = []
    public private(set) var reResolveCalls: [(pid: pid_t, frame: CGRect)] = []

    public var isOnCurrentScreenCallCount: Int { isOnCurrentScreenCalls.count }
    public var reResolveWindowIDCallCount: Int { reResolveCalls.count }

    public init() {}

    public func isOnCurrentScreen(windowID: CGWindowID) -> OnScreenObservationResult {
        isOnCurrentScreenCalls.append(windowID)
        return observationResults[windowID] ?? defaultObservationResult
    }

    public func reResolveWindowID(pid: pid_t, frame: CGRect) -> CGWindowID? {
        reResolveCalls.append((pid, frame))
        if pidsReResolvingToNil.contains(pid) { return nil }
        return reResolvedIDs[pid]
    }

    /// Clears every call record (per-test setup convenience).
    public func resetCalls() {
        isOnCurrentScreenCalls = []
        reResolveCalls = []
    }
}
