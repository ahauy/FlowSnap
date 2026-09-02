import Testing
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Tests for the new `applicationLaunched(pid, bundleID:)` and
/// `applicationWindowCreated(pid, windowID:)` cases added in US-WORK-013.
///
/// Compile-time: both cases must remain `Sendable` + `Hashable`. A failure
/// to build here means the `WindowEvent` enum lost its isolation contract.
struct WindowEventLaunchTests {

    @Test func applicationLaunchedCarriesBundleID() {
        let event = WindowEvent.applicationLaunched(1001, bundleID: "com.apple.Safari")
        if case let .applicationLaunched(pid, bundleID) = event {
            #expect(pid == 1001)
            #expect(bundleID == "com.apple.Safari")
        } else {
            Issue.record("Expected .applicationLaunched case")
        }
    }

    @Test func applicationLaunchedAcceptsNilBundleID() {
        let event = WindowEvent.applicationLaunched(42, bundleID: nil)
        if case let .applicationLaunched(pid, bundleID) = event {
            #expect(pid == 42)
            #expect(bundleID == nil)
        } else {
            Issue.record("Expected .applicationLaunched case")
        }
    }

    @Test func applicationWindowCreatedCarriesWindowID() {
        let event = WindowEvent.applicationWindowCreated(pid: 1001, windowID: 99)
        if case let .applicationWindowCreated(pid, windowID) = event {
            #expect(pid == 1001)
            #expect(windowID == 99)
        } else {
            Issue.record("Expected .applicationWindowCreated case")
        }
    }

    @Test func windowEventStaysHashableWithAssociatedBundleID() {
        let a = WindowEvent.applicationLaunched(1001, bundleID: "com.apple.Safari")
        let b = WindowEvent.applicationLaunched(1001, bundleID: "com.apple.Safari")
        let c = WindowEvent.applicationLaunched(1001, bundleID: "com.apple.Terminal")

        #expect(a == b)
        #expect(a != c)
    }
}
