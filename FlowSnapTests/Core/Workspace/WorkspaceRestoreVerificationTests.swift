import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// P0 contract tests for deterministic restore proof and final focus selection.
@MainActor
@Suite("Workspace Restore Verification")
struct WorkspaceRestoreVerificationTests {

    private let display = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        scaleFactor: 2,
        isPrimary: true
    )

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapRestoreVerification-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeManager(
        windows: [ManagedWindow],
        accessibility: MockAccessibilityService,
        windowManager: any WindowManaging,
        launcher: MockApplicationLaunching
    ) -> WorkspaceManager {
        accessibility.mockVisibleWindows = windows
        accessibility.managedWindowsByPID = Dictionary(grouping: windows, by: \.pid)
        accessibility.mockElementByWindowID = Dictionary(uniqueKeysWithValues: windows.map {
            ($0.id, AXUIElementCreateApplication($0.pid))
        })
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: windowManager,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        // P0.5: the mock windows never appear in the real WindowServer list, so
        // the suite pins presentation with a scriptable checker defaulting to
        // `.presented` — every pre-P0.5 expectation stays intact.
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())
        return manager
    }

    private func placement(_ bundle: String, order: Int = 0) -> WindowPlacement {
        WindowPlacement(bundleIdentifier: bundle, zone: .leftHalf, orderIndex: order)
    }

    @Test("A successful setFrame with unchanged frame is unverifiable after three attempts")
    func silentFrameWriteIsNotSuccess() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", pid: 1001,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.setFrameUpdatesMockFrame = false
        let manager = makeManager(
            windows: [window], accessibility: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 1001])
        )

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 0)
        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .unverifiablePlacement)
        #expect(accessibility.setFrameCallCount == RestoreVerificationPolicy.maxAttempts)
    }

    @Test("A window that remains minimized never counts as placed")
    func minimizedVerificationFails() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 2, bundle: "com.editor", pid: 1002,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400), isMinimized: true
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        let manager = makeManager(
            windows: [window], accessibility: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 1002])
        )
        guard let element = accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        accessibility.mockMinimizedStates[element] = true
        accessibility.mockMinimizedReadValues[element] = [true, true, true, true]

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 0)
        #expect(summary.unverifiableCount == 1)
        #expect(accessibility.setFrameCallCount == RestoreVerificationPolicy.maxAttempts)
    }

    @Test("A missing AX element is unverifiable and never receives a frame write")
    func missingElementIsGuarded() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 3, bundle: "com.editor", pid: 1003,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        let manager = makeManager(
            windows: [window], accessibility: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 1003])
        )
        accessibility.mockElementByWindowID.removeAll()

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .unverifiablePlacement)
        #expect(accessibility.setFrameCallCount == 0)
    }

    @Test("Recoverable setFrame errors retry three times and become moveFailed")
    func moveErrorRetries() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 4, bundle: "com.editor", pid: 1004,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.setFrameError = AccessibilityError.cannotComplete
        let manager = makeManager(
            windows: [window], accessibility: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 1004])
        )

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.failedCount == 1)
        #expect(summary.failed.first?.reason == .moveFailed)
        #expect(accessibility.setFrameCallCount == RestoreVerificationPolicy.maxAttempts)
    }

    @Test("Fullscreen exit failure blocks placement entirely")
    func fullscreenExitThrowBlocksMove() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 5, bundle: "com.editor", pid: 1005,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.exitFullScreenError = AccessibilityError.cannotComplete
        let manager = makeManager(
            windows: [window], accessibility: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 1005])
        )
        guard let element = accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        accessibility.mockFullScreenStates[element] = true

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.failed.first?.reason == .fullscreenTransitionTimeout)
        #expect(accessibility.exitFullScreenCallCount == 1)
        #expect(accessibility.setFrameCallCount == 0)
    }

    @Test("Fullscreen transition timeout blocks frame writes after the two-second budget")
    func fullscreenTimeoutBlocksMove() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 6, bundle: "com.editor", pid: 1006,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.exitFullScreenUpdatesState = false
        let manager = makeManager(
            windows: [window], accessibility: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 1006])
        )
        guard let element = accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        accessibility.mockFullScreenStates[element] = true

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.failed.first?.reason == .fullscreenTransitionTimeout)
        #expect(accessibility.setFrameCallCount == 0)
    }

    @Test("Restore summary counters conserve the placement total")
    func summaryCountersConserveTotal() {
        let summary = RestoreSummary(
            placedCount: 2,
            totalPlacements: 5,
            failed: [RestoreIssue(bundleIdentifier: "com.failed", reason: .moveFailed)],
            unverifiable: [RestoreIssue(bundleIdentifier: "com.unknown", reason: .unverifiablePlacement)],
            skipped: [RestoreIssue(bundleIdentifier: "com.missing", reason: .noWindow)]
        )

        #expect(summary.placedCount + summary.failedCount
            + summary.unverifiableCount + summary.skippedCount == summary.totalPlacements)
    }

    @Test("Final focus targets only the lowest-order verified placement")
    func focusUsesLowestVerifiedOrder() async throws {
        let first = WorkspaceTestFixtures.window(
            id: 10, bundle: "com.first", pid: 1010,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let second = WorkspaceTestFixtures.window(
            id: 11, bundle: "com.second", pid: 1011,
            appKitFrame: CGRect(x: 200, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(processIdentifiers: ["com.first": 1010, "com.second": 1011])
        let manager = makeManager(
            windows: [first, second], accessibility: accessibility,
            windowManager: mover,
            launcher: launcher
        )
        mover.onMove = { _, frame, element in
            if let element { accessibility.mockFrames[element] = frame }
        }

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [
                placement("com.second", order: 1), placement("com.first", order: 0)
            ]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 2)
        #expect(mover.movedWindows.map(\.window.id) == [first.id, second.id])
        #expect(mover.focusCallCount == 1)
        #expect(mover.focusedWindows.first?.bundleIdentifier == "com.first")
        #expect(launcher.revealAttempts == ["com.first"])
    }
}
