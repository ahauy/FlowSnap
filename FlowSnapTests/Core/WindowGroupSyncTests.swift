import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("WindowGroup Synchronization Engine Tests")
struct WindowGroupSyncTests {

    @MainActor
    private struct TestContext {
        let manager: WindowGroupManager
        let mockAX: MockAccessibilityService
        let mockWM: MockWindowManaging
    }

    @MainActor
    private func makeContext() -> TestContext {
        let mockAX = MockAccessibilityService(isTrusted: true)
        let mockWM = MockWindowManaging()
        let manager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)
        return TestContext(manager: manager, mockAX: mockAX, mockWM: mockWM)
    }

    @MainActor
    @Test("handleWindowMinimize minimizes fellow group members simultaneously")
    func testSimultaneousMinimize() async throws {
        let context = makeContext()

        let win1 = ManagedWindow(
            id: 601,
            pid: 6001,
            bundleIdentifier: "com.app.one",
            title: "One",
            frame: CGRect(x: 0, y: 0, width: 400, height: 400),
            isMinimized: false
        )
        let win2 = ManagedWindow(
            id: 602,
            pid: 6002,
            bundleIdentifier: "com.app.two",
            title: "Two",
            frame: CGRect(x: 400, y: 0, width: 400, height: 400),
            isMinimized: false
        )
        let win3 = ManagedWindow(
            id: 603,
            pid: 6003,
            bundleIdentifier: "com.app.three",
            title: "Three",
            frame: CGRect(x: 800, y: 0, width: 400, height: 400),
            isMinimized: false
        )

        context.mockAX.mockVisibleWindows = [win1, win2, win3]

        // Group contains win1 and win2 only
        context.manager.createGroup(name: "Pair", windowIDs: [601, 602], syncOptions: [.minimizeTogether])

        // Trigger minimize on win1
        try await context.manager.handleWindowMinimize(triggerWindowID: 601)

        #expect(context.mockWM.minimizeCallCount == 1)
        #expect(context.mockWM.minimizedWindows.contains { $0.id == 602 })
        #expect(!context.mockWM.minimizedWindows.contains { $0.id == 603 })
    }

    @MainActor
    @Test("handleWindowRestore unminimizes fellow group members")
    func testSimultaneousRestore() async throws {
        let context = makeContext()

        let win1 = ManagedWindow(
            id: 601,
            pid: 6001,
            bundleIdentifier: "com.app.one",
            title: "One",
            frame: CGRect(x: 0, y: 0, width: 400, height: 400),
            isMinimized: false
        )
        let win2 = ManagedWindow(
            id: 602,
            pid: 6002,
            bundleIdentifier: "com.app.two",
            title: "Two",
            frame: CGRect(x: 400, y: 0, width: 400, height: 400),
            isMinimized: true
        )

        context.mockAX.mockVisibleWindows = [win1, win2]

        context.manager.createGroup(name: "Pair", windowIDs: [601, 602], syncOptions: [.minimizeTogether])

        try await context.manager.handleWindowRestore(triggerWindowID: 601)

        #expect(context.mockWM.unminimizeCallCount == 1)
        #expect(context.mockWM.unminimizedWindows.contains { $0.id == 602 })
    }

    @MainActor
    @Test("handleWindowFocus raises fellow members first and trigger window last to preserve Z-order")
    func testFocusWithZOrderPreservation() async throws {
        let context = makeContext()

        let win1 = ManagedWindow(
            id: 701,
            pid: 7001,
            bundleIdentifier: "com.app.one",
            title: "One",
            frame: CGRect(x: 0, y: 0, width: 400, height: 400)
        )
        let win2 = ManagedWindow(
            id: 702,
            pid: 7002,
            bundleIdentifier: "com.app.two",
            title: "Two",
            frame: CGRect(x: 100, y: 0, width: 400, height: 400)
        )
        let win3 = ManagedWindow(
            id: 703,
            pid: 7003,
            bundleIdentifier: "com.app.three",
            title: "Three",
            frame: CGRect(x: 200, y: 0, width: 400, height: 400)
        )

        context.mockAX.mockVisibleWindows = [win1, win2, win3]

        context.manager.createGroup(name: "Trio", windowIDs: [701, 702, 703], syncOptions: [.focusTogether])

        // User focuses win2
        try await context.manager.handleWindowFocus(triggerWindowID: 702)

        #expect(context.mockWM.focusCallCount == 3)
        // Background members (701, 703) raised first, 702 raised last
        #expect(context.mockWM.focusedWindows.last?.id == 702)
    }

    @MainActor
    @Test("handleWindowMove offsets each member from its live AX position")
    func testMoveDeltaSynchronization() async throws {
        let context = makeContext()

        // Snapshots are AppKit (y-up); the AX tree reports y-down. Giving the two
        // different values is what lets a test tell a correct move from a mirrored
        // one — if both were equal the bug would be invisible.
        let win1 = ManagedWindow(
            id: 801,
            pid: 8001,
            bundleIdentifier: "com.app.one",
            title: "One",
            frame: CGRect(x: 0, y: 500, width: 300, height: 300)
        )
        let win2 = ManagedWindow(
            id: 802,
            pid: 8002,
            bundleIdentifier: "com.app.two",
            title: "Two",
            frame: CGRect(x: 300, y: 500, width: 300, height: 300)
        )

        context.mockAX.mockVisibleWindows = [win1, win2]

        let element2 = AXUIElementCreateApplication(8002)
        context.mockAX.mockWindowElements[802] = element2
        // Where win2 actually sits right now, in AX space.
        let liveAXFrame = CGRect(x: 300, y: 100, width: 300, height: 300)
        context.mockAX.mockFrames[element2] = liveAXFrame

        context.manager.createGroup(name: "Pair", windowIDs: [801, 802], syncOptions: [.moveTogether])

        let delta = CGPoint(x: 50, y: 100)
        try await context.manager.handleWindowMove(triggerWindowID: 801, delta: delta)

        #expect(context.mockWM.movedWindows.count == 1)
        let moved = context.mockWM.movedWindows.first(where: { $0.window.id == 802 })
        #expect(moved != nil)

        // The expectation is the live AX frame plus the delta. Had the code applied
        // the delta to the AppKit snapshot instead, it would have produced
        // (350, 600) — a vertically mirrored placement.
        #expect(moved?.frame == CGRect(x: 350, y: 200, width: 300, height: 300))

        let element = try #require(context.mockWM.movedElements.first)
        #expect(CFEqual(element, element2))
    }

    @MainActor
    @Test("handleWindowMove leaves a member alone when its AX frame cannot be read")
    func testMoveSkipsMemberWithoutLiveFrame() async throws {
        let context = makeContext()

        let win1 = ManagedWindow(
            id: 811, pid: 8011, bundleIdentifier: "com.app.one", title: "One",
            frame: CGRect(x: 0, y: 500, width: 300, height: 300)
        )
        let win2 = ManagedWindow(
            id: 812, pid: 8012, bundleIdentifier: "com.app.two", title: "Two",
            frame: CGRect(x: 300, y: 500, width: 300, height: 300)
        )
        context.mockAX.mockVisibleWindows = [win1, win2]
        let element2 = AXUIElementCreateApplication(8012)
        context.mockAX.mockWindowElements[812] = element2
        // Deliberately no mockFrames entry: the element reports no position.

        context.manager.createGroup(name: "Pair", windowIDs: [811, 812], syncOptions: [.moveTogether])
        try await context.manager.handleWindowMove(triggerWindowID: 811, delta: CGPoint(x: 50, y: 100))

        // Moving from the stale snapshot would teleport the window, so nothing moves.
        #expect(context.mockWM.moveCallCount == 0)
    }

    @MainActor
    @Test("Re-entrancy guard prevents recursive loops")
    func testReentrancyGuard() async throws {
        let context = makeContext()

        let win1 = ManagedWindow(
            id: 901,
            pid: 9001,
            bundleIdentifier: "com.app.one",
            title: "One",
            frame: CGRect(x: 0, y: 0, width: 400, height: 400)
        )
        let win2 = ManagedWindow(
            id: 902,
            pid: 9002,
            bundleIdentifier: "com.app.two",
            title: "Two",
            frame: CGRect(x: 400, y: 0, width: 400, height: 400)
        )

        context.mockAX.mockVisibleWindows = [win1, win2]

        context.manager.createGroup(name: "Pair", windowIDs: [901, 902], syncOptions: [.minimizeTogether])

        #expect(context.manager.isSynchronizing == false)
        #expect(context.manager.syncGeneration == 0)

        try await context.manager.handleWindowMinimize(triggerWindowID: 901)

        #expect(context.manager.isSynchronizing == false)
        #expect(context.manager.syncGeneration == 1)
    }
}
