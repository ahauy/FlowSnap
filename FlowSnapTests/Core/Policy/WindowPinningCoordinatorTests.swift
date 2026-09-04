import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite @MainActor
struct WindowPinningCoordinatorTests {

    private func makeWindow(id: CGWindowID, pid: pid_t, title: String, bundleID: String = "com.test.app") -> ManagedWindow {
        ManagedWindow(
            id: id,
            pid: pid,
            bundleIdentifier: bundleID,
            title: title,
            frame: CGRect(x: 100, y: 100, width: 400, height: 300),
            kind: .normal
        )
    }

    @Test func togglePinOnUnpinnedWindowAddsToPinnedAndRaises() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(accessibilityService: mockAX)
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")

        let isPinned = await coordinator.togglePin(window: windowA)

        #expect(isPinned == true)
        #expect(coordinator.isPinned(windowID: 101) == true)
        #expect(coordinator.pinnedWindows.count == 1)
        #expect(coordinator.pinnedWindows.first?.id == 101)
        #expect(coordinator.pinnedWindows.first?.title == "Notes")
        #expect(mockAX.raisedWindows.contains(where: { $0.id == 101 }))
    }

    @Test func togglePinOnAlreadyPinnedWindowRemovesIt() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(accessibilityService: mockAX)
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")

        _ = await coordinator.togglePin(window: windowA)
        #expect(coordinator.isPinned(windowID: 101) == true)

        let isPinnedSecond = await coordinator.togglePin(window: windowA)
        #expect(isPinnedSecond == false)
        #expect(coordinator.isPinned(windowID: 101) == false)
        #expect(coordinator.pinnedWindows.isEmpty)
    }

    @Test func lifoOrderingMultiplePinnedWindows() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(accessibilityService: mockAX)
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")
        let windowB = makeWindow(id: 102, pid: 600, title: "Calculator")

        _ = await coordinator.togglePin(window: windowA)
        _ = await coordinator.togglePin(window: windowB)

        // Newest pin is at the top of LIFO stack (index 0)
        #expect(coordinator.pinnedWindows.map(\.id) == [102, 101])

        // When Window A receives focus, it moves to the top of LIFO
        await coordinator.handleFocusChange(activeWindowID: 101, activePID: 500)
        #expect(coordinator.pinnedWindows.map(\.id) == [101, 102])
    }

    @Test func activeReassertionRaisesPinnedWindowsBottomToTopWhenUnpinnedWindowActive() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(accessibilityService: mockAX)
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")
        let windowB = makeWindow(id: 102, pid: 600, title: "Calculator")

        mockAX.mockVisibleWindows = [windowA, windowB]

        _ = await coordinator.togglePin(window: windowA)
        _ = await coordinator.togglePin(window: windowB)
        #expect(coordinator.pinnedWindows.map(\.id) == [102, 101])

        mockAX.raisedWindows.removeAll()

        // An unpinned window (Safari, ID: 201) receives focus
        await coordinator.handleFocusChange(activeWindowID: 201, activePID: 700)

        // Bottom-up raise: window 101 first, then window 102 so 102 remains on top
        #expect(mockAX.raisedWindows.map(\.id) == [101, 102])
    }

    @Test func systemModalExemptionSuspendsReassertion() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(
            accessibilityService: mockAX,
            systemModalBundleIDs: ["com.apple.SecurityAgent", "com.apple.CoreAuthUI"]
        )
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")
        mockAX.mockVisibleWindows = [windowA]

        _ = await coordinator.togglePin(window: windowA)
        mockAX.raisedWindows.removeAll()

        // System modal receives focus
        await coordinator.handleFocusChange(
            activeWindowID: 999,
            activePID: 88,
            activeBundleID: "com.apple.SecurityAgent"
        )

        // Re-assertion should be suspended
        #expect(mockAX.raisedWindows.isEmpty)
    }

    @Test func appTerminationCleansUpPinnedWindows() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(accessibilityService: mockAX)
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")
        let windowB = makeWindow(id: 102, pid: 600, title: "Calculator")

        _ = await coordinator.togglePin(window: windowA)
        _ = await coordinator.togglePin(window: windowB)
        #expect(coordinator.pinnedWindows.count == 2)

        // Process 500 terminates
        coordinator.handleApplicationTerminated(processIdentifier: 500)

        #expect(coordinator.pinnedWindows.map(\.id) == [102])
        #expect(coordinator.isPinned(windowID: 101) == false)
        #expect(coordinator.isPinned(windowID: 102) == true)
    }

    @Test func unpinAllClearsEverything() async {
        let mockAX = MockAccessibilityService()
        let coordinator = WindowPinningCoordinator(accessibilityService: mockAX)
        let windowA = makeWindow(id: 101, pid: 500, title: "Notes")
        let windowB = makeWindow(id: 102, pid: 600, title: "Calculator")

        _ = await coordinator.togglePin(window: windowA)
        _ = await coordinator.togglePin(window: windowB)
        #expect(coordinator.isPinningActive == true)

        coordinator.unpinAll()
        #expect(coordinator.isPinningActive == false)
        #expect(coordinator.pinnedWindows.isEmpty)
    }
}
