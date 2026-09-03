import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Unit tests for DisplayHotPlugObserver.
///
/// Traces to: US-DISP-016, REQ-DISP-001, REQ-DISP-002, BR-DISP-008, TC-016-03.
@MainActor
struct DisplayHotPlugObserverTests {

    @MainActor
    private final class DisplayBox {
        var displays: [Display]
        init(displays: [Display]) {
            self.displays = displays
        }
    }

    private func makeDisplay(
        id: CGDirectDisplayID,
        originX: CGFloat,
        width: CGFloat = 1920,
        height: CGFloat = 1080,
        isPrimary: Bool = false
    ) -> Display {
        Display(
            id: id,
            frame: CGRect(x: originX, y: 0, width: width, height: height),
            visibleFrame: CGRect(x: originX, y: 25, width: width, height: height - 25),
            scaleFactor: 2.0,
            isPrimary: isPrimary
        )
    }

    @Test func coalescingDebounceMultipleNotifications() async throws {
        let displayA = makeDisplay(id: 1, originX: 0, isPrimary: true)
        let displayB = makeDisplay(id: 2, originX: 1920)

        let box = DisplayBox(displays: [displayA])
        let observer = DisplayHotPlugObserver(
            debounceDuration: .milliseconds(50),
            displayProvider: { box.displays }
        )

        var eventCount = 0
        var receivedEvent: DisplayTopologyChangeEvent?
        observer.onTopologyChanged = { event in
            eventCount += 1
            receivedEvent = event
        }

        observer.startObserving()

        // Update displays to simulate plugging in display B
        box.displays = [displayA, displayB]

        // Fire 4 notifications in rapid succession (< 50ms)
        for _ in 0..<4 {
            NotificationCenter.default.post(
                name: NSApplication.didChangeScreenParametersNotification,
                object: nil
            )
            try await Task.sleep(for: .milliseconds(5))
        }

        // Before debounce window finishes: eventCount should still be 0
        #expect(eventCount == 0)

        // Wait for debounce to complete
        try await Task.sleep(for: .milliseconds(80))

        #expect(eventCount == 1)
        if case .hotPlugConnected(let newFp, let addedCount) = receivedEvent {
            #expect(addedCount == 1)
            #expect(newFp.displayCount == 2)
        } else {
            Issue.record("Expected .hotPlugConnected event, received \(String(describing: receivedEvent))")
        }

        observer.stopObserving()
    }

    @Test func hotUnplugEventDispatched() async throws {
        let displayA = makeDisplay(id: 1, originX: 0, isPrimary: true)
        let displayB = makeDisplay(id: 2, originX: 1920)

        let box = DisplayBox(displays: [displayA, displayB])
        let observer = DisplayHotPlugObserver(
            debounceDuration: .milliseconds(30),
            displayProvider: { box.displays }
        )

        var receivedEvent: DisplayTopologyChangeEvent?
        observer.onTopologyChanged = { event in
            receivedEvent = event
        }

        observer.startObserving()

        // Simulate unplugging display B
        box.displays = [displayA]

        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        try await Task.sleep(for: .milliseconds(60))

        if case .hotUnplugDisconnected(let newFp, let departingFp) = receivedEvent {
            #expect(newFp.displayCount == 1)
            #expect(departingFp.displayCount == 2)
        } else {
            Issue.record("Expected .hotUnplugDisconnected event, received \(String(describing: receivedEvent))")
        }

        observer.stopObserving()
    }

    @Test func stopObservingPreventsEvents() async throws {
        let displayA = makeDisplay(id: 1, originX: 0, isPrimary: true)
        let displayB = makeDisplay(id: 2, originX: 1920)

        let box = DisplayBox(displays: [displayA])
        let observer = DisplayHotPlugObserver(
            debounceDuration: .milliseconds(20),
            displayProvider: { box.displays }
        )

        var eventCount = 0
        observer.onTopologyChanged = { _ in
            eventCount += 1
        }

        observer.startObserving()
        observer.stopObserving()

        box.displays = [displayA, displayB]
        NotificationCenter.default.post(
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        try await Task.sleep(for: .milliseconds(50))
        #expect(eventCount == 0)
    }
}
