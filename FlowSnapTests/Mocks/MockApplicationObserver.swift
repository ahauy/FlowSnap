import CoreGraphics
import Foundation
@testable import FlowSnap

/// Scriptable test double for `ApplicationObserving` (US-WORK-013).
///
/// Mirrors the design of `MockApplicationLaunching` and other `FlowSnapTests/Mocks/`
/// doubles: deterministic, `@unchecked Sendable`, fully programmable from the test
/// side so spec scenarios (happy / timeout / failed / dedup) can be driven
/// without the live `AXObserver` runtime.
///
/// This is a SKELETON — concrete test assertions are authored in Phase 5 by the
/// test-authoring subagent using this seam. The skeleton exists now so the
/// implementation-orchestrator can wire it into the test target without
/// blocking on a parallel scaffolding effort.
public final class MockApplicationObserver: ApplicationObserving, @unchecked Sendable {

    /// Bundle ids whose launch should be auto-completed with a synthetic window.
    /// When a `pid` arrives for one of these bundle ids, the mock enqueues a
    /// `.windowCreated` event into `events` after `simulatedLatency`.
    public var autoCompleteBundleIDs: Set<String> = []

    /// Bundle ids whose launch should auto-fail with a `.failed` event.
    public var failingBundleIDs: Set<String> = []

    /// Bundle ids whose launch should hang forever, exercising the timeout path.
    /// Tests then assert the timeout event arrives and `stopObserving(pid:)`
    /// releases the entry.
    public var hangingBundleIDs: Set<String> = []

    /// How long the mock should wait before publishing the synthetic
    /// `.windowCreated` for an auto-completed launch. Default `0` so the
    /// happy-path test is synchronous.
    public var simulatedLatency: TimeInterval = 0

    /// Monotonically increasing window id assigned to each auto-completed
    /// `.windowCreated` event. Lets a test assert the order of arrivals.
    private var windowIDSeed: UInt32 = 0

    /// All `observe(pid:bundleID:)` calls, in order — for assertion in tests.
    public private(set) var observeCalls: [(pid: pid_t, bundleID: String?)] = []

    /// All `stopObserving(pid:)` calls, in order.
    public private(set) var stopObservingCalls: [pid_t] = []

    /// Backing stream continuation. `events` reads from here.
    private let continuation: AsyncStream<LaunchObservationEvent>.Continuation
    public let events: AsyncStream<LaunchObservationEvent>

    public init() {
        var capturedContinuation: AsyncStream<LaunchObservationEvent>.Continuation!
        self.events = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation
    }

    public func observe(pid: pid_t, bundleID: String?) async {
        observeCalls.append((pid, bundleID))

        if let bundleID, failingBundleIDs.contains(bundleID) {
            continuation.yield(.failed(pid: pid, reason: .accessibilityNotAuthorized))
            return
        }

        if let bundleID, hangingBundleIDs.contains(bundleID) {
            // Intentionally do not publish — the consumer side is expected to
            // invoke `stopObserving(pid:)` (or rely on the real `ApplicationObserver`
            // timeout path) to drain this entry.
            return
        }

        if let bundleID, autoCompleteBundleIDs.contains(bundleID) {
            if simulatedLatency > 0 {
                let delay = simulatedLatency
                let capturedContinuation = continuation
                Task.detached {
                    try? await Task.sleep(for: .seconds(delay))
                    capturedContinuation.yield(
                        .windowCreated(pid: pid, windowID: self.nextWindowID())
                    )
                }
            } else {
                continuation.yield(.windowCreated(pid: pid, windowID: nextWindowID()))
            }
        }
    }

    public func stopObserving(pid: pid_t) {
        stopObservingCalls.append(pid)
    }

    /// Drains and finishes `events`. Call at the end of each test so the
    /// AsyncStream consumer's `for await` loop exits cleanly.
    public func finish() {
        continuation.finish()
    }

    private func nextWindowID() -> CGWindowID {
        windowIDSeed &+= 1
        return CGWindowID(windowIDSeed)
    }
}
