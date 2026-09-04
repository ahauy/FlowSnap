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
    private let lock = NSLock()

    private var _installedBundleIDs: Set<String>
    public var installedBundleIDs: Set<String> {
        get { lock.withLock { _installedBundleIDs } }
        set { lock.withLock { _installedBundleIDs = newValue } }
    }

    private var _hangingBundleIDs: Set<String>
    public var hangingBundleIDs: Set<String> {
        get { lock.withLock { _hangingBundleIDs } }
        set { lock.withLock { _hangingBundleIDs = newValue } }
    }

    private var _processIdentifiers: [String: pid_t]
    public var processIdentifiers: [String: pid_t] {
        get { lock.withLock { _processIdentifiers } }
        set { lock.withLock { _processIdentifiers = newValue } }
    }

    private var _pidsAssignedOnLaunch: [String: pid_t]
    public var pidsAssignedOnLaunch: [String: pid_t] {
        get { lock.withLock { _pidsAssignedOnLaunch } }
        set { lock.withLock { _pidsAssignedOnLaunch = newValue } }
    }

    private var _launchAttempts: [String] = []
    public var launchAttempts: [String] {
        lock.withLock { _launchAttempts }
    }

    private var _waitAttempts: [pid_t] = []
    public var waitAttempts: [pid_t] {
        lock.withLock { _waitAttempts }
    }

    public init(
        installedBundleIDs: Set<String> = [],
        hangingBundleIDs: Set<String> = [],
        processIdentifiers: [String: pid_t] = [:],
        pidsAssignedOnLaunch: [String: pid_t] = [:]
    ) {
        self._installedBundleIDs = installedBundleIDs
        self._hangingBundleIDs = hangingBundleIDs
        self._processIdentifiers = processIdentifiers
        self._pidsAssignedOnLaunch = pidsAssignedOnLaunch
    }

    public func openApp(withBundleIdentifier bundleID: String) async -> Bool {
        lock.withLock {
            _launchAttempts.append(bundleID)
            guard _installedBundleIDs.contains(bundleID) else { return false }
            if let pid = _pidsAssignedOnLaunch[bundleID] {
                _processIdentifiers[bundleID] = pid
            }
            return true
        }
    }

    public func waitForFirstWindow(pid: pid_t, timeout: TimeInterval) async -> Bool {
        lock.withLock {
            _waitAttempts.append(pid)
            let hanging = _processIdentifiers
                .filter { $0.value == pid && _hangingBundleIDs.contains($0.key) }
                .isEmpty == false
            return !hanging
        }
    }

    public func runningProcessIdentifier(bundleID: String) -> pid_t? {
        lock.withLock {
            _processIdentifiers[bundleID]
        }
    }

    private var _revealAttempts: [String] = []
    public var revealAttempts: [String] {
        lock.withLock { _revealAttempts }
    }

    private var _unrevealableBundleIDs: Set<String> = []
    public var unrevealableBundleIDs: Set<String> {
        get { lock.withLock { _unrevealableBundleIDs } }
        set { lock.withLock { _unrevealableBundleIDs = newValue } }
    }

    @discardableResult
    public func reveal(bundleID: String) -> Bool {
        lock.withLock {
            _revealAttempts.append(bundleID)
            return !_unrevealableBundleIDs.contains(bundleID)
        }
    }

    private var _unhideAttempts: [String] = []
    public var unhideAttempts: [String] {
        lock.withLock { _unhideAttempts }
    }

    @discardableResult
    public func unhide(bundleID: String) -> Bool {
        lock.withLock {
            _unhideAttempts.append(bundleID)
            return true
        }
    }
}
