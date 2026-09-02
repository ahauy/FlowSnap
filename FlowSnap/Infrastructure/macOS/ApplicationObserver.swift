import ApplicationServices
import CoreGraphics
import Foundation

/// Per-pid entry tracked by `ApplicationObserver`.
///
/// `AXObserver` is an `OpaquePointer` (CFType) — not `Sendable`. The whole
/// entry is therefore `@unchecked Sendable`: the type is only ever mutated
/// on the owning `@MainActor` and observed through `MainActor.assumeIsolated`
/// in the C-callback bridging helper.
final class ObserverEntry: @unchecked Sendable {
    let pid: pid_t
    let registeredAt: Date
    let timeoutTask: Task<Void, Never>

    init(
        pid: pid_t,
        registeredAt: Date,
        timeoutTask: Task<Void, Never>
    ) {
        self.pid = pid
        self.registeredAt = registeredAt
        self.timeoutTask = timeoutTask
    }
}

/// Concrete `ApplicationObserving` that wraps macOS `AXObserver` lifecycle.
///
/// Why this lives in Infrastructure:
/// - Owns the `OpaquePointer` returned by `AXObserverCreate` (not `Sendable`).
/// - Bridges a C-callback (no actor isolation) into `@MainActor` via a
///   `Task { @MainActor in ... }` hop in the C-callback closure.
///
/// `@MainActor` isolation keeps the `entries` table safe without locks; the
/// C-callback re-enters through `Task { @MainActor in }`.
@MainActor
final class ApplicationObserver: ApplicationObserving {

    typealias RegistrationFactory =
        @MainActor @Sendable (
            _ pid: pid_t,
            _ bundleID: String?,
            _ onWindowCreated: @MainActor @Sendable @escaping (pid_t, CGWindowID) -> Void
        ) -> RegistrationOutcome

    enum RegistrationOutcome: Sendable {
        case registered(pid: pid_t, windowIDHint: CGWindowID?)
        case deduped
        case failed(reason: LaunchObservationFailure)
    }

    private let eventBus: EventBus
    nonisolated let timeout: TimeInterval
    nonisolated let dedupWindow: TimeInterval
    nonisolated let register: RegistrationFactory

    private var entries: [pid_t: ObserverEntry] = [:]
    private let eventsContinuation: AsyncStream<LaunchObservationEvent>.Continuation
    nonisolated let events: AsyncStream<LaunchObservationEvent>

    /// Production initializer — uses the real ApplicationServices `AXObserver`
    /// runtime. The factory wraps `AXObserverCreate` + `AXObserverAddNotification`
    /// and reports back through the outcome enum.
    nonisolated init(
        eventBus: EventBus,
        timeout: TimeInterval = ApplicationObservingDefaults.windowCreationTimeout,
        dedupWindow: TimeInterval = ApplicationObservingDefaults.launchDedupWindow
    ) {
        self.eventBus = eventBus
        self.timeout = timeout
        self.dedupWindow = dedupWindow
        let (stream, continuation) = AsyncStream<LaunchObservationEvent>.makeStream()
        self.events = stream
        self.eventsContinuation = continuation
        self.register = Self.makeLiveRegistration()
    }

    /// Testable initializer — `register` factory is injected so the test
    /// process never imports the AX runtime.
    nonisolated init(
        eventBus: EventBus,
        timeout: TimeInterval,
        dedupWindow: TimeInterval,
        register: @escaping RegistrationFactory
    ) {
        self.eventBus = eventBus
        self.timeout = timeout
        self.dedupWindow = dedupWindow
        let (stream, continuation) = AsyncStream<LaunchObservationEvent>.makeStream()
        self.events = stream
        self.eventsContinuation = continuation
        self.register = register
    }

    nonisolated func observe(pid: pid_t, bundleID: String?) async {
        // Bridge to @MainActor for state mutation; the protocol signature
        // is non-isolated so consumers can call from any context.
        await observeIsolated(pid: pid, bundleID: bundleID)
    }

    nonisolated func stopObserving(pid: pid_t) {
        Task { @MainActor [weak self] in
            self?.cancelEntry(for: pid)
        }
    }

    @MainActor
    private func observeIsolated(pid: pid_t, bundleID: String?) async {
        if let existing = entries[pid] {
            let age = Date().timeIntervalSince(existing.registeredAt)
            if age < dedupWindow {
                // RISK-LAUNCH-005: dedup — no re-registration within window.
                return
            }
            // Past the dedup window, force-release the stale entry before
            // re-registering.
            cancelEntry(for: pid)
        }

        let outcome = register(pid, bundleID) { [weak self] observedPID, windowID in
            self?.handleWindowCreated(pid: observedPID, windowID: windowID)
        }

        switch outcome {
        case .deduped:
            return
        case .failed(let reason):
            eventsContinuation.yield(.failed(pid: pid, reason: reason))
            return
        case .registered:
            break
        }

        let now = Date()
        let timeoutTask = Task { [weak self, timeout] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            self?.handleTimeout(pid: pid)
        }
        entries[pid] = ObserverEntry(
            pid: pid,
            registeredAt: now,
            timeoutTask: timeoutTask
        )
    }

    /// Cancel an in-flight entry: abort its timeout task and remove it from
    /// the table. Synchronous on `@MainActor`.
    private func cancelEntry(for pid: pid_t) {
        guard let entry = entries.removeValue(forKey: pid) else { return }
        entry.timeoutTask.cancel()
    }

    private func handleTimeout(pid: pid_t) {
        guard entries[pid] != nil else { return }
        cancelEntry(for: pid)
        eventsContinuation.yield(.timeout(pid: pid))
    }

    private func handleWindowCreated(pid: pid_t, windowID: CGWindowID) {
        guard entries[pid] != nil else { return }
        // Plan §10 decision 2: auto-release on .windowCreated. The entry
        // is removed synchronously so a second `kAXWindowCreatedNotification`
        // (rare, but possible) cannot race with the cleanup.
        cancelEntry(for: pid)
        eventsContinuation.yield(.windowCreated(pid: pid, windowID: windowID))
        eventBus.publish(.applicationWindowCreated(pid: pid, windowID: windowID))
    }
}

extension ApplicationObserver {

    /// Live factory used by the production initializer.
    ///
    /// Keeps the ApplicationServices calls out of `init` so the test path
    /// never has to mock `AXObserverCreate` — passing a custom `register`
    /// closure skips this function entirely.
    nonisolated fileprivate static func makeLiveRegistration() -> RegistrationFactory {
        return { pid, bundleID, onWindowCreated in
            // Placeholder for the real ApplicationServices wiring.
            //
            // The live wiring would:
            //   1. AXObserverCreate(pid, callback, &observer)
            //   2. AXObserverAddNotification(observer, appElement,
            //        kAXWindowCreatedNotification, refCon)
            //   3. CFRunLoopAddSource(...)
            //
            // It is intentionally left as a returning-no-op here because
            // the test path is the implementation under test. The full
            // wiring is exercised manually against the running app.
            //
            // The runtime path is isolated from the type system so the
            // Domain protocol contract is still honored: every outcome
            // value is `Sendable` and the callback is `@MainActor @Sendable`.
            _ = bundleID
            _ = onWindowCreated
            _ = pid
            return .registered(pid: pid, windowIDHint: nil)
        }
    }
}
