import Testing
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Tests for the `LaunchObservationEvent` value type (US-WORK-013).
///
/// All cases must be `Sendable` and `Hashable` so the AsyncStream consumer
/// can cross actor boundaries without unsafe hops.
struct LaunchObservationEventTests {

    @Test func windowCreatedIsHashableAndSendable() {
        let a = LaunchObservationEvent.windowCreated(pid: 1001, windowID: 99)
        let b = LaunchObservationEvent.windowCreated(pid: 1001, windowID: 99)
        let c = LaunchObservationEvent.windowCreated(pid: 1001, windowID: 100)

        #expect(a == b)
        #expect(a != c)
    }

    @Test func timeoutIsHashableAndSendable() {
        let a = LaunchObservationEvent.timeout(pid: 42)
        let b = LaunchObservationEvent.timeout(pid: 42)
        let c = LaunchObservationEvent.timeout(pid: 43)

        #expect(a == b)
        #expect(a != c)
    }

    @Test func failedIsHashableAndSendable() {
        let a = LaunchObservationEvent.failed(
            pid: 7,
            reason: .observerCreationFailed(code: AXErrorCode(rawValue: -1))
        )
        let b = LaunchObservationEvent.failed(
            pid: 7,
            reason: .observerCreationFailed(code: AXErrorCode(rawValue: -1))
        )
        let c = LaunchObservationEvent.failed(
            pid: 7,
            reason: .addNotificationFailed(code: AXErrorCode(rawValue: -2))
        )

        #expect(a == b)
        #expect(a != c)
    }

    @Test func failureReasonsAreDistinguished() {
        let auth: LaunchObservationFailure = .accessibilityNotAuthorized
        let create: LaunchObservationFailure = .observerCreationFailed(code: AXErrorCode(rawValue: 0))
        let add: LaunchObservationFailure = .addNotificationFailed(code: AXErrorCode(rawValue: 0))

        #expect(auth != create)
        #expect(create != add)
        #expect(auth != add)
    }

    @Test func axErrorCodeRawValueRoundTrips() {
        let code = AXErrorCode(rawValue: -25200) // kAXErrorAPIDisabled
        #expect(code.rawValue == -25200)
    }
}
