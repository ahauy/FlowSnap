import Testing
import AppKit
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Tests for `WorkspaceObserver` (US-WORK-013).
///
/// A real `NSWorkspace` cannot be driven deterministically (no public API
/// to inject a fake NSRunningApplication), so the test path injects a
/// `NotificationCenter` and posts synthetic NSWorkspace notifications with
/// a hand-built `NSRunningApplication` user-info payload.
@Suite @MainActor
struct WorkspaceObserverTests {

    // MARK: - TC-013-01

    @Test func publishesApplicationLaunchedOnDidLaunch() async {
        let bus = EventBus()
        let center = NotificationCenter()
        let observer = WorkspaceObserver(eventBus: bus, notificationCenter: center)

        var received: [WindowEvent] = []
        bus.subscribe(observer) { received.append($0) }

        observer.startObserving()
        defer {
            observer.stopObserving()
            bus.unsubscribe(observer)
        }

        let app = makeRunningApplication(pid: 1001, bundleID: "com.apple.Safari")
        let info: [String: Any] = [NSWorkspace.applicationUserInfoKey: app]
        let notification = Notification(
            name: NSWorkspace.didLaunchApplicationNotification,
            userInfo: info
        )
        center.post(notification)

        // Notification handler hops to @MainActor via Task — give the hop
        // a chance to land before asserting.
        try? await Task.sleep(nanoseconds: 100_000_000)

        let launched = applicationLaunchedEvents(in: received)
        #expect(launched.contains { $0.pid == 1001 && $0.bundleID == "com.apple.Safari" })
    }

    // MARK: - TC-013-08

    @Test func publishesApplicationLaunchedOnDidActivate() async {
        let bus = EventBus()
        let center = NotificationCenter()
        let observer = WorkspaceObserver(eventBus: bus, notificationCenter: center)

        var received: [WindowEvent] = []
        bus.subscribe(observer) { received.append($0) }

        observer.startObserving()
        defer {
            observer.stopObserving()
            bus.unsubscribe(observer)
        }

        let app = makeRunningApplication(pid: 2002, bundleID: "com.apple.Terminal")
        let info: [String: Any] = [NSWorkspace.applicationUserInfoKey: app]
        center.post(
            Notification(
                name: NSWorkspace.didActivateApplicationNotification,
                userInfo: info
            )
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        let launched = applicationLaunchedEvents(in: received)
        #expect(launched.contains { $0.pid == 2002 && $0.bundleID == "com.apple.Terminal" })
    }

    @Test func publishesApplicationTerminatedOnDidTerminate() async {
        let bus = EventBus()
        let center = NotificationCenter()
        let observer = WorkspaceObserver(eventBus: bus, notificationCenter: center)

        var received: [WindowEvent] = []
        bus.subscribe(observer) { received.append($0) }

        observer.startObserving()
        defer {
            observer.stopObserving()
            bus.unsubscribe(observer)
        }

        let app = makeRunningApplication(pid: 3003, bundleID: "com.example.quitter")
        let info: [String: Any] = [NSWorkspace.applicationUserInfoKey: app]
        center.post(
            Notification(
                name: NSWorkspace.didTerminateApplicationNotification,
                userInfo: info
            )
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        let terminated = received.compactMap { event -> pid_t? in
            if case .applicationTerminated(let pid) = event { return pid } else { return nil }
        }
        #expect(terminated.contains(3003))
    }

    @Test func stopObservingRemovesAllTokens() async {
        let bus = EventBus()
        let center = NotificationCenter()
        let observer = WorkspaceObserver(eventBus: bus, notificationCenter: center)

        observer.startObserving()
        observer.stopObserving()

        var received: [WindowEvent] = []
        bus.subscribe(observer) { received.append($0) }
        defer { bus.unsubscribe(observer) }

        let app = makeRunningApplication(pid: 9999, bundleID: "com.example.silent")
        let info: [String: Any] = [NSWorkspace.applicationUserInfoKey: app]
        center.post(
            Notification(
                name: NSWorkspace.didLaunchApplicationNotification,
                userInfo: info
            )
        )

        try? await Task.sleep(nanoseconds: 100_000_000)

        let launched = applicationLaunchedEvents(in: received)
        #expect(!launched.contains { $0.pid == 9999 })
    }
}

// MARK: - Test helpers

/// Extract every `.applicationLaunched` from a recorded stream.
private func applicationLaunchedEvents(in events: [WindowEvent]) -> [(pid: pid_t, bundleID: String?)] {
    events.compactMap { event in
        if case let .applicationLaunched(pid, bundleID) = event {
            return (pid, bundleID)
        }
        return nil
    }
}

/// Build an `NSRunningApplication` stub suitable for stuffing into
/// `userInfo[NSWorkspace.applicationUserInfoKey]`.
///
/// `NSRunningApplication` has no public initializer, so the test process
/// subclasses it. The subclass overrides only the read-only properties
/// used by `WorkspaceObserver.handleLaunch` (processIdentifier +
/// bundleIdentifier); everything else falls through to the parent's
/// default implementations.
private final class StubRunningApplication: NSRunningApplication {
    private let stubPid: pid_t
    private let stubBundleID: String?

    init(pid: pid_t, bundleID: String?) {
        self.stubPid = pid
        self.stubBundleID = bundleID
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used by tests")
    }

    override var processIdentifier: pid_t { stubPid }
    override var bundleIdentifier: String? { stubBundleID }
}

private func makeRunningApplication(pid: pid_t, bundleID: String) -> NSRunningApplication {
    StubRunningApplication(pid: pid, bundleID: bundleID)
}
