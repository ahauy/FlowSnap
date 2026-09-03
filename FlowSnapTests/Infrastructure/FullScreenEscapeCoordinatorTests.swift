@preconcurrency import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

private final class TestBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: T

    init(_ initial: T) {
        self._value = initial
    }

    var value: T {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

@Suite("FullScreenEscapeCoordinator Tests")
struct FullScreenEscapeCoordinatorTests {

    private func makeDummyAXElement() -> AXUIElement {
        AXUIElementCreateSystemWide()
    }

    @Test("TC-FSE-001: Tier 0 Fast Attribute Write Success")
    func testTier0AttributeWriteSuccess() async throws {
        let dummyElement = makeDummyAXElement()
        let mockPoster = MockCGEventPoster()
        let buttonFinderCalled = TestBox(false)
        let attributeKeysWritten = TestBox<[String]>([])

        let coordinator = FullScreenEscapeCoordinator(
            eventPoster: mockPoster,
            appActivator: { _ in true },
            attributeWriter: { _, key, _ in
                attributeKeysWritten.value.append(key)
                return .success
            },
            buttonFinder: { _ in
                buttonFinderCalled.value = true
                return nil
            },
            sleepFunction: { _ in }
        )

        let result = try await coordinator.exitFullScreen(
            for: dummyElement,
            pid: 1234,
            isFullScreenChecker: { false }
        )

        #expect(result.succeeded == true)
        #expect(result.tierUsed == .attributeWrite)
        #expect(attributeKeysWritten.value.contains("AXFullscreen"))
        #expect(buttonFinderCalled.value == false)
        #expect(mockPoster.postedKeystrokes.isEmpty)
    }

    @Test("TC-FSE-002: Tier 1 AX Button Press on Electron / Chromium Apps")
    func testTier1AXButtonPressSuccess() async throws {
        let dummyElement = makeDummyAXElement()
        let dummyButton = makeDummyAXElement()
        let mockPoster = MockCGEventPoster()
        let buttonPressed = TestBox(false)

        let coordinator = FullScreenEscapeCoordinator(
            eventPoster: mockPoster,
            appActivator: { _ in true },
            attributeWriter: { _, _, _ in .cannotComplete },
            buttonFinder: { _ in dummyButton },
            buttonPresser: { _ in
                buttonPressed.value = true
                return .success
            },
            sleepFunction: { _ in }
        )

        let result = try await coordinator.exitFullScreen(
            for: dummyElement,
            pid: 1234,
            isFullScreenChecker: { false }
        )

        #expect(result.succeeded == true)
        #expect(result.tierUsed == .axButtonPress)
        #expect(buttonPressed.value == true)
        #expect(mockPoster.postedKeystrokes.isEmpty)
    }

    @Test("TC-FSE-003: Tier 2 Fallback to Synthesized ⌃⌘F Keystroke")
    func testTier2CGEventFallbackSuccess() async throws {
        let dummyElement = makeDummyAXElement()
        let mockPoster = MockCGEventPoster()
        let activatedPid = TestBox<pid_t?>(nil)

        let coordinator = FullScreenEscapeCoordinator(
            eventPoster: mockPoster,
            appActivator: { pid in
                activatedPid.value = pid
                return true
            },
            attributeWriter: { _, _, _ in .cannotComplete },
            buttonFinder: { _ in nil },
            sleepFunction: { _ in }
        )

        let result = try await coordinator.exitFullScreen(
            for: dummyElement,
            pid: 5678,
            isFullScreenChecker: { false }
        )

        #expect(result.succeeded == true)
        #expect(result.tierUsed == .cgEventShortcut)
        #expect(activatedPid.value == 5678)
        #expect(mockPoster.postedKeystrokes.count == 1)
        #expect(mockPoster.postedKeystrokes.first?.pid == 5678)
        #expect(mockPoster.postedKeystrokes.first?.keyCode == FullScreenEscapeCoordinator.fKeyCode)
        #expect(mockPoster.postedKeystrokes.first?.flags.contains([.maskControl, .maskCommand]) == true)
    }

    @Test("TC-FSE-004: Adaptive Polling Loop Early Termination")
    func testAdaptivePollingEarlyTermination() async throws {
        let dummyElement = makeDummyAXElement()
        let checkCount = TestBox(0)
        let sleepCalls = TestBox<[UInt64]>([])

        let coordinator = FullScreenEscapeCoordinator(
            eventPoster: MockCGEventPoster(),
            appActivator: { _ in true },
            attributeWriter: { _, _, _ in .success },
            buttonFinder: { _ in nil },
            sleepFunction: { nanos in
                sleepCalls.value.append(nanos)
            }
        )

        let result = try await coordinator.exitFullScreen(
            for: dummyElement,
            pid: 1234,
            isFullScreenChecker: {
                checkCount.value += 1
                // Exit full screen at 2nd check
                return checkCount.value < 2
            }
        )

        #expect(result.succeeded == true)
        #expect(result.tierUsed == .attributeWrite)
        #expect(checkCount.value == 2)
        #expect(sleepCalls.value.count == 2) // 2 sleep intervals (100ms each) before early return
    }

    @Test("TC-FSE-005: Timeout Handling at 800ms Ceiling")
    func testTimeoutCeilingGracefulReturn() async throws {
        let dummyElement = makeDummyAXElement()
        let sleepCalls = TestBox<[UInt64]>([])

        let coordinator = FullScreenEscapeCoordinator(
            eventPoster: MockCGEventPoster(),
            appActivator: { _ in true },
            attributeWriter: { _, _, _ in .success },
            buttonFinder: { _ in nil },
            sleepFunction: { nanos in
                sleepCalls.value.append(nanos)
            }
        )

        // Always claims to still be in full screen
        let result = try await coordinator.exitFullScreen(
            for: dummyElement,
            pid: 1234,
            isFullScreenChecker: { true }
        )

        #expect(result.succeeded == true)
        #expect(result.tierUsed == .attributeWrite)
        #expect(sleepCalls.value.count == 8) // max 8 intervals of 100ms
    }

    @Test("Failure Case: All Tiers Fail Returns Failure")
    func testAllTiersFailReturnsFailure() async throws {
        let dummyElement = makeDummyAXElement()

        let coordinator = FullScreenEscapeCoordinator(
            eventPoster: MockCGEventPoster(),
            appActivator: { _ in true },
            attributeWriter: { _, _, _ in .cannotComplete },
            buttonFinder: { _ in nil },
            sleepFunction: { _ in }
        )

        // pid is nil so tier 2 cannot run
        let result = try await coordinator.exitFullScreen(
            for: dummyElement,
            pid: nil,
            isFullScreenChecker: { false }
        )

        #expect(result.succeeded == false)
        #expect(result.tierUsed == nil)
        #expect(result.error != nil)
    }
}
