import AppKit
import Foundation

/// Abstraction over the parts of `NSWorkspace` that restore needs.
///
/// ADR-004: `NSWorkspace.shared` is a singleton that cannot be injected or faked,
/// so every launch call site goes through this protocol instead. The production
/// implementation is a thin wrapper; the test double can script the offline paths
/// in spec §5 (E4 notInstalled, E5 launchTimeout / noWindow), none of which are
/// reachable deterministically through the live `NSWorkspace`.
///
/// `openApp` is `async` because `NSWorkspace` reports the launch result on the
/// main queue — a synchronous wrapper there would deadlock the menu bar.
///
/// Traces to: contracts §2, ADR-004, BR-WORK-003.
public protocol ApplicationLaunching: Sendable {

    /// Opens the app for a bundle id and reports whether the launch succeeded.
    ///
    /// - Returns: `false` when no app is installed for the bundle id **or** the
    ///   launch was refused — spec §5 E4 groups both into one outcome
    ///   ("App not installed or cannot launch → skip, report 'notInstalled'").
    func openApp(withBundleIdentifier bundleID: String) async -> Bool

    /// Polls until the process exposes a normal window.
    ///
    /// - Parameter pid: process to observe. The restore loop resolves it through
    ///   `runningProcessIdentifier` after a launch, because `NSWorkspace` hands
    ///   back a process id and the window list is keyed by it.
    /// - Parameter timeout: hard upper bound on the wait. The restore pass is
    ///   driven by a menu click, so it must self-terminate: an app that launches
    ///   but never draws a window (Gatekeeper prompt, login sheet) must not hang
    ///   the whole restore (RISK-WORK-002).
    /// - Returns: `true` when a window appeared within `timeout`.
    func waitForFirstWindow(pid: pid_t, timeout: TimeInterval) async -> Bool

    /// Un-hides and activates an app so its restored windows are actually visible.
    ///
    /// A hidden app (Cmd+H) keeps a perfectly addressable AX window with a real
    /// frame, so a restore can "succeed" while the user sees nothing. This is the
    /// last step of the sequence. Best-effort by contract: it never throws, because
    /// a failure to reveal must not turn a placed window into a skipped placement.
    ///
    /// - Returns: `true` when the app was found and activation was accepted.
    @discardableResult
    func reveal(bundleID: String) -> Bool

    /// Un-hides an app if it was hidden (Cmd+H), without forcing stage switch or full activation.
    @discardableResult
    func unhide(bundleID: String) -> Bool

    /// Process id of a running app, or `nil` when it is not running.
    func runningProcessIdentifier(bundleID: String) -> pid_t?
}

/// Timing constants shared by every `ApplicationLaunching` implementation.
///
/// A plain enum (no cases) rather than protocol-extension statics, which Swift
/// does not allow for stored properties.
public enum LaunchTiming {

    /// The restore budget for a single app launch (BR-WORK-003: "≤ 10s").
    public static let windowTimeout: TimeInterval = 10

    /// Poll interval while waiting for a launched app's first window.
    ///
    /// 100ms picks up a normally-launching app almost immediately (it draws well
    /// inside a second) while keeping the per-poll cost negligible.
    public static let pollInterval: TimeInterval = 0.1
}

/// Production `ApplicationLaunching` backed by `NSWorkspace` plus AX polling.
///
/// Zero private API (BR-WORK-010): `NSWorkspace` and the Accessibility service are
/// the only frameworks touched here.
///
/// Traces to: ADR-004, contracts §2.
public final class AppLauncher: ApplicationLaunching, @unchecked Sendable {

    private let accessibilityService: any AccessibilityService

    public init(accessibilityService: any AccessibilityService = AXAccessibilityService()) {
        self.accessibilityService = accessibilityService
    }

    public func openApp(withBundleIdentifier bundleID: String) async -> Bool {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return false
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        do {
            // Awaiting the running application tells us the launch was accepted.
            // Whether a *window* appeared is a separate question answered by
            // `waitForFirstWindow` — keeping the two apart is what lets the
            // summary distinguish "not installed" from "took too long to open".
            _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            return true
        } catch {
            NSLog("[AppLauncher] Launch failed for \(bundleID): \(error.localizedDescription)")
            return false
        }
    }

    public func waitForFirstWindow(pid: pid_t, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if hasNormalWindow(pid: pid) { return true }
            try? await Task.sleep(nanoseconds: UInt64(LaunchTiming.pollInterval * 1_000_000_000))
        }
        // One final check: the window may have appeared during the last sleep.
        return hasNormalWindow(pid: pid)
    }

    public func runningProcessIdentifier(bundleID: String) -> pid_t? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.processIdentifier
    }

    @discardableResult
    public func reveal(bundleID: String) -> Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return false
        }
        // Un-hide first: an app hidden with Cmd+H reports a valid AX frame while
        // drawing nothing, so a restore that only moves the window looks like it
        // silently did nothing.
        if app.isHidden {
            app.unhide()
        }
        // `.activateAllWindows` also brings forward windows on another Space, which
        // is what "restore my layout" means to a user with one app per Space.
        return app.activate(options: [.activateAllWindows])
    }

    @discardableResult
    public func unhide(bundleID: String) -> Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return false
        }
        if app.isHidden {
            return app.unhide()
        }
        return true
    }

    /// Whether the process currently exposes a normal (snappable) window.
    ///
    /// Reads the app's Accessibility window list rather than the WindowServer's
    /// on-screen list. A freshly launched app often restores its previous windows
    /// minimized or on another Space, and those never appear in
    /// `allVisibleManagedWindows()` — polling there made the launcher wait out its
    /// whole budget and report `launchTimeout` for an app whose window was in fact
    /// present and addressable.
    ///
    /// Uses `isRestorable` so a freshly launched app whose only window is full-screen
    /// (macOS session restoration) is detected immediately rather than timing out.
    private func hasNormalWindow(pid: pid_t) -> Bool {
        accessibilityService.managedWindows(of: pid).contains { window in
            window.kind.isRestorable && window.frame.width > 0 && window.frame.height > 0
        }
    }
}
