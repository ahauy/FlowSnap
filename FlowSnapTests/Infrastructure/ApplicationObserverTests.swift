import Testing
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Tests for `ApplicationObserver` (US-WORK-013).
///
/// The test path uses the injectable `RegistrationFactory` so the test
/// process never imports the live ApplicationServices runtime. The factory
/// is called on `@MainActor` (matching production semantics) and can
/// synchronously fire the `onWindowCreated` callback to simulate
/// `kAXWindowCreatedNotification`.
@Suite @MainActor
struct ApplicationObserverTests {

    // MARK: - TC-013-02

    @Test func observeRegistersAndSchedulesTimeout() async {
        let bus = EventBus()
        let recorder = RegistrationRecorder()
        let observer = ApplicationObserver(
            eventBus: bus,
            timeout: 0.5,
            dedupWindow: 0.1,
            register: recorder.factory()
        )

        await observer.observe(pid: 1001, bundleID: "com.example")

        #expect(recorder.registeredPids == [1001])
        #expect(recorder.lastBundleID == "com.example")
    }

    // MARK: - TC-013-03

    @Test func callbackPublishesWindowCreatedAndAutoReleases() async {
        let bus = EventBus()
        var published: [WindowEvent] = []
        let sub = WindowEventSubscriber(bus: bus) { published.append($0) }

        let recorder = RegistrationRecorder()
        let observer = ApplicationObserver(
            eventBus: bus,
            timeout: 10.0,
            dedupWindow: 0.1,
            register: recorder.factory()
        )

        await observer.observe(pid: 1001, bundleID: "com.example")
        recorder.fireWindowCreated(pid: 1001, windowID: 99)

        // Give the @MainActor hop a chance to drain.
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(
            published.contains(where: {
                if case let .applicationWindowCreated(pid, windowID) = $0 {
                    return pid == 1001 && windowID == 99
                }
                return false
            })
        )

        // Plan §10 decision 2: auto-release on .windowCreated — the entry
        // for pid 1001 is gone, so a follow-up `observe` re-registers
        // exactly once (a fresh observation cycle, not a duplicate).
        let callsBefore = recorder.registerCallCount
        await observer.observe(pid: 1001, bundleID: "com.example")
        #expect(recorder.registerCallCount == callsBefore + 1)

        sub.cancel()
    }

    // MARK: - TC-013-04

    @Test func timeoutFiresAfterWindow() async {
        let bus = EventBus()
        let recorder = RegistrationRecorder()
        let observer = ApplicationObserver(
            eventBus: bus,
            timeout: 0.05,
            dedupWindow: 0.01,
            register: recorder.factory()
        )

        // Collect `.timeout` from the events stream.
        let collector = EventCollector<LaunchObservationEvent>(stream: observer.events)

        await observer.observe(pid: 1001, bundleID: "com.example")
        await collector.waitForFirst(timeout: 1.0)

        #expect(
            collector.events.contains(where: {
                if case .timeout(let pid) = $0 { return pid == 1001 } else { return false }
            })
        )

        // Entry must be removed after the timeout fires.
        try? await Task.sleep(nanoseconds: 10_000_000)
        let callsBefore = recorder.registerCallCount
        await observer.observe(pid: 1001, bundleID: "com.example")
        // Past the dedup window, a fresh register is allowed.
        #expect(recorder.registerCallCount > callsBefore)
    }

    // MARK: - TC-013-05

    @Test func dedupWithinWindowPreventsReRegistration() async {
        let bus = EventBus()
        let recorder = RegistrationRecorder()
        let observer = ApplicationObserver(
            eventBus: bus,
            timeout: 10.0,
            dedupWindow: 5.0,
            register: recorder.factory()
        )

        await observer.observe(pid: 1001, bundleID: "com.example")
        await observer.observe(pid: 1001, bundleID: "com.example")
        await observer.observe(pid: 1001, bundleID: "com.example")

        #expect(recorder.registerCallCount == 1)
    }

    // MARK: - Failure path

    @Test func failedRegistrationPublishesFailedEvent() async {
        let bus = EventBus()
        let recorder = RegistrationRecorder()
        let observer = ApplicationObserver(
            eventBus: bus,
            timeout: 10.0,
            dedupWindow: 0.1,
            register: recorder.factory(forceOutcome: .failed(reason: .accessibilityNotAuthorized))
        )

        let collector = EventCollector<LaunchObservationEvent>(stream: observer.events)

        await observer.observe(pid: 1001, bundleID: "com.example")
        await collector.waitForFirst(timeout: 1.0)

        #expect(
            collector.events.contains(where: {
                if case .failed(let pid, _) = $0 { return pid == 1001 } else { return false }
            })
        )
    }

    // MARK: - stopObserving

    @Test func stopObservingCancelsEntry() async {
        let bus = EventBus()
        let recorder = RegistrationRecorder()
        let observer = ApplicationObserver(
            eventBus: bus,
            timeout: 10.0,
            dedupWindow: 5.0,
            register: recorder.factory()
        )

        await observer.observe(pid: 1001, bundleID: "com.example")
        #expect(recorder.registerCallCount == 1)

        observer.stopObserving(pid: 1001)

        // A second observe past the dedup window must re-register.
        try? await Task.sleep(nanoseconds: 10_000_000)
        await observer.observe(pid: 1001, bundleID: "com.example")
        #expect(recorder.registerCallCount == 2)
    }
}

// MARK: - Test helpers

/// Captures every `register(pid:bundleID:onWindowCreated:)` call so the
/// test can both count and replay the `onWindowCreated` callback without
/// pulling in the live AXObserver runtime.
@MainActor
private final class RegistrationRecorder {
    private(set) var registeredPids: [pid_t] = []
    private(set) var lastBundleID: String?
    private(set) var registerCallCount = 0
    private var pendingCallbacks: [(pid_t, (pid_t, CGWindowID) -> Void)] = []
    private var forced: ApplicationObserver.RegistrationOutcome?

    func factory(forceOutcome: ApplicationObserver.RegistrationOutcome? = nil) -> ApplicationObserver.RegistrationFactory {
        self.forced = forceOutcome
        return { [weak self] pid, bundleID, callback in
            guard let self else {
                return .failed(reason: .accessibilityNotAuthorized)
            }
            self.registerCallCount += 1
            self.registeredPids.append(pid)
            self.lastBundleID = bundleID
            self.pendingCallbacks.append((pid, callback))
            if let forced = self.forced {
                return forced
            }
            return .registered(pid: pid, windowIDHint: nil)
        }
    }

    func fireWindowCreated(pid: pid_t, windowID: CGWindowID) {
        guard let entry = pendingCallbacks.first(where: { $0.0 == pid }) else { return }
        entry.1(pid, windowID)
    }
}

/// `@MainActor`-safe subscriber that forwards every `WindowEvent` to a
/// callback. Cancelled by the caller before the test ends.
@MainActor
private final class WindowEventSubscriber {
    private let bus: EventBus
    private let handler: (WindowEvent) -> Void
    private let token: ObjectIdentifier

    init(bus: EventBus, handler: @escaping (WindowEvent) -> Void) {
        self.bus = bus
        self.handler = handler
        let token = ObjectIdentifier(bus)
        self.token = token
        bus.subscribe(bus) { [handler] event in
            handler(event)
        }
    }

    func cancel() {
        bus.unsubscribe(self)
    }
}

/// Drains an `AsyncStream` into a buffer and offers `waitForFirst` to await
/// the first value (or a timeout). Avoids having each test write its own
/// `Task { for await ... }` boilerplate.
@MainActor
private final class EventCollector<Event: Sendable> {
    private(set) var events: [Event] = []
    private var continuation: Task<Void, Never>?

    init(stream: AsyncStream<Event>) {
        self.continuation = Task { @MainActor [weak self] in
            for await value in stream {
                self?.events.append(value)
            }
        }
    }

    func waitForFirst(timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        while events.isEmpty, Date() < deadline {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }
}
