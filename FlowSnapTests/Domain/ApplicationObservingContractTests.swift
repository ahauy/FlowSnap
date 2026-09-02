import Testing
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Contract test for `ApplicationObserving` (US-WORK-013).
///
/// Verifies the protocol's surface area and Sendable conformance at compile
/// time. A test-only conformer (`RecordingApplicationObserver`) exercises
/// every member so that any accidental signature change produces a build
/// failure in the test target, not at production call sites.
struct ApplicationObservingContractTests {

    @Test func protocolExposesRequiredMembers() {
        // Compile-time check: this conformance must continue to compile
        // whenever the protocol surface changes. If a method is renamed or
        // its signature changes, this file fails to build.
        let observer: any ApplicationObserving = RecordingApplicationObserver()
        #expect(observer.events is AsyncStream<LaunchObservationEvent>)
    }

    @Test func protocolIsSendable() async {
        // Crossing a task boundary is a compile-time check that the protocol
        // is `Sendable`. A failure here means the protocol lost its
        // isolation contract.
        let observer: any ApplicationObserving = RecordingApplicationObserver()
        let captured = await Task { @Sendable in observer }.value
        #expect(captured.events is AsyncStream<LaunchObservationEvent>)
    }

    @Test func defaultsExposeExpectedValues() {
        #expect(ApplicationObservingDefaults.windowCreationTimeout == 10.0)
        #expect(ApplicationObservingDefaults.launchDedupWindow == 5.0)
    }
}

/// Minimal in-test conformer that captures the protocol surface without
/// adding anything to the public mocks folder (the richer
/// `MockApplicationObserver` lives in `FlowSnapTests/Mocks/`).
private final class RecordingApplicationObserver: ApplicationObserving, @unchecked Sendable {
    private let continuation: AsyncStream<LaunchObservationEvent>.Continuation
    let events: AsyncStream<LaunchObservationEvent>

    init() {
        var captured: AsyncStream<LaunchObservationEvent>.Continuation!
        self.events = AsyncStream { continuation in
            captured = continuation
        }
        self.continuation = captured
    }

    func observe(pid: pid_t, bundleID: String?) async {
        // Contract test only — body is intentionally trivial.
    }

    func stopObserving(pid: pid_t) {
        // Contract test only — body is intentionally trivial.
    }
}
