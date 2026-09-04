import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite @MainActor
struct StageManagerLaunchCoordinatorTests {

    private func makeWindow(id: CGWindowID, pid: pid_t, title: String) -> ManagedWindow {
        ManagedWindow(
            id: id,
            pid: pid,
            bundleIdentifier: nil,
            title: title,
            frame: CGRect(x: 100, y: 100, width: 600, height: 400),
            kind: .normal
        )
    }

    @Test func launchWithStageManagerAndCoexistenceEnabledMultiRaisesOldStage() async {
        let mockDetector = MockStageManagerDetector()
        mockDetector.isStageManagerEnabled = true

        let mockAX = MockAccessibilityService()
        let window1 = makeWindow(id: 101, pid: 400, title: "VS Code")
        let window2 = makeWindow(id: 102, pid: 500, title: "Chrome")
        mockAX.mockVisibleWindows = [window1, window2]

        let mockObserver = MockApplicationObserver()
        mockObserver.autoCompleteBundleIDs = ["com.apple.Terminal"]

        let coordinator = StageManagerLaunchCoordinator(
            stageManagerDetector: mockDetector,
            accessibilityService: mockAX,
            applicationObserver: mockObserver
        )
        coordinator.isCoexistenceEnabled = true

        await coordinator.handleApplicationLaunched(processIdentifier: 700, bundleIdentifier: "com.apple.Terminal")

        // Old stage windows should both be raised
        #expect(mockAX.raisedWindows.contains(where: { $0.id == 101 }))
        #expect(mockAX.raisedWindows.contains(where: { $0.id == 102 }))
    }

    @Test func launchWhenStageManagerDisabledDoesNotRaise() async {
        let mockDetector = MockStageManagerDetector()
        mockDetector.isStageManagerEnabled = false

        let mockAX = MockAccessibilityService()
        let window1 = makeWindow(id: 101, pid: 400, title: "VS Code")
        mockAX.mockVisibleWindows = [window1]

        let mockObserver = MockApplicationObserver()
        mockObserver.autoCompleteBundleIDs = ["com.apple.Terminal"]

        let coordinator = StageManagerLaunchCoordinator(
            stageManagerDetector: mockDetector,
            accessibilityService: mockAX,
            applicationObserver: mockObserver
        )
        coordinator.isCoexistenceEnabled = true

        await coordinator.handleApplicationLaunched(processIdentifier: 700, bundleIdentifier: "com.apple.Terminal")

        #expect(mockAX.raisedWindows.isEmpty)
    }

    @Test func launchWhenCoexistenceDisabledDoesNotRaise() async {
        let mockDetector = MockStageManagerDetector()
        mockDetector.isStageManagerEnabled = true

        let mockAX = MockAccessibilityService()
        let window1 = makeWindow(id: 101, pid: 400, title: "VS Code")
        mockAX.mockVisibleWindows = [window1]

        let mockObserver = MockApplicationObserver()
        mockObserver.autoCompleteBundleIDs = ["com.apple.Terminal"]

        let coordinator = StageManagerLaunchCoordinator(
            stageManagerDetector: mockDetector,
            accessibilityService: mockAX,
            applicationObserver: mockObserver
        )
        coordinator.isCoexistenceEnabled = false

        await coordinator.handleApplicationLaunched(processIdentifier: 700, bundleIdentifier: "com.apple.Terminal")

        #expect(mockAX.raisedWindows.isEmpty)
    }
}
