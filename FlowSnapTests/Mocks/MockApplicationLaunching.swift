import Foundation
@testable import FlowSnap

/// Scriptable test double for `ApplicationLaunching` (ADR-004).
///
/// The three offline paths in spec §5 — E4 not installed, E5 launch timeout, and
/// E5/E10 "running but no window" — are all unreachable deterministically through
/// the live `NSWorkspace`: whether an app is installed depends on the machine
/// running the test. This double makes each one a constructor argument.
public final class MockApplicationLaunching: ApplicationLaunching, @unchecked Sendable {

    /// Bundle ids that `openApp` reports as launchable. Anything absent fails,
    /// modelling E4.
    public var installedBundleIDs: Set<String>

    /// Bundle ids whose launch is accepted but which never draw a window,
    /// modelling E5.
    public var hangingBundleIDs: Set<String>

    /// Process ids reported for a bundle id. `nil` models "not running".
    public var processIdentifiers: [String: pid_t]

    /// Process ids assigned when a launch succeeds. Seeded into
    /// `processIdentifiers` by `openApp`, so an app is genuinely "not running"
    /// until it is launched — which is what makes the launch path testable.
    public var pidsAssignedOnLaunch: [String: pid_t]

    /// How many launches have been requested, in order — lets a test assert the
    /// pass did not launch something it should have found already running.
    public private(set) var launchAttempts: [String] = []
    public private(set) var waitAttempts: [pid_t] = []

    public init(
        installedBundleIDs: Set<String> = [],
        hangingBundleIDs: Set<String> = [],
        processIdentifiers: [String: pid_t] = [:],
        pidsAssignedOnLaunch: [String: pid_t] = [:]
    ) {
        self.installedBundleIDs = installedBundleIDs
        self.hangingBundleIDs = hangingBundleIDs
        self.processIdentifiers = processIdentifiers
        self.pidsAssignedOnLaunch = pidsAssignedOnLaunch
    }

    public func openApp(withBundleIdentifier bundleID: String) async -> Bool {
        launchAttempts.append(bundleID)
        guard installedBundleIDs.contains(bundleID) else { return false }
        if let pid = pidsAssignedOnLaunch[bundleID] {
            processIdentifiers[bundleID] = pid
        }
        return true
    }

    public func waitForFirstWindow(pid: pid_t, timeout: TimeInterval) async -> Bool {
        waitAttempts.append(pid)
        // The "hanging" set is keyed by bundle id, so resolve back through the
        // pid map rather than storing pids directly — a test then only has to
        // name the app, not invent a process id.
        let hanging = processIdentifiers
            .filter { $0.value == pid && hangingBundleIDs.contains($0.key) }
            .isEmpty == false
        return !hanging
    }

    public func runningProcessIdentifier(bundleID: String) -> pid_t? {
        processIdentifiers[bundleID]
    }

    /// Bundle ids revealed (un-hidden + activated) after being placed.
    public private(set) var revealAttempts: [String] = []
    /// Bundle ids whose reveal should fail, to exercise the best-effort path.
    public var unrevealableBundleIDs: Set<String> = []

    @discardableResult
    public func reveal(bundleID: String) -> Bool {
        revealAttempts.append(bundleID)
        return !unrevealableBundleIDs.contains(bundleID)
    }
}
