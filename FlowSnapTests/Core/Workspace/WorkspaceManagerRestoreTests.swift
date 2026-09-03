import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// T010 — restore orchestration (US-WORK-011 spec §2 J2, BR-WORK-003/004/007).
///
/// The restore pass is best-effort: per-app problems land in the `RestoreSummary`
/// and the loop continues (BR-WORK-004). These tests pin each skip reason to its
/// spec code (E4/E5/E10), the launch budget (BR-WORK-003), cascade clamping, and
/// the one thing a wrong coordinate system would break — the frame handed to
/// `WindowManaging.move`.
@MainActor
@Suite("WorkspaceManager Restore")
struct WorkspaceManagerRestoreTests {

    private let display = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        scaleFactor: 2.0,
        isPrimary: true
    )

    private func makeManager(
        windows: [ManagedWindow],
        launcher: any ApplicationLaunching,
        windowManager: MockWindowManaging,
        trusted: Bool = true
    ) -> WorkspaceManager {
        let accessibility = MockAccessibilityService(isTrusted: trusted)
        accessibility.mockVisibleWindows = windows
        let elements = Dictionary(uniqueKeysWithValues: windows.map {
            ($0.id, AXUIElementCreateApplication($0.pid))
        })
        accessibility.mockElementByWindowID = elements
        windowManager.onMove = { _, frame, element in
            if let element { accessibility.mockFrames[element] = frame }
        }
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
        // P0.5: scriptable presentation checker defaulting to `.presented`, so
        // mock windows count as presented exactly as before the observation.
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())
        return manager
    }

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapRestoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func workspace(_ placements: [WindowPlacement]) -> Workspace {
        Workspace(name: "Test", placements: placements)
    }

    // MARK: - Happy path (J2.3)

    @Test("A running app's window is moved into its zone")
    func placesRunningApp() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let mover = MockWindowManaging()
        let manager = makeManager(
            windows: [win],
            launcher: MockApplicationLaunching(),
            windowManager: mover
        )

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.placedCount == 1)
        #expect(summary.isFullSuccess)
        #expect(mover.moveCallCount == 1)
    }

    @Test("The frame handed to move is in AX coordinates, not AppKit")
    func moveUsesAXCoordinates() async throws {
        // Regression guard. Every other move call site in the app converts to AX
        // before moving (CommandDispatcher, AdaptiveDividerCoordinator); restore
        // must match, or windows land vertically mirrored on the display.
        let win = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let mover = MockWindowManaging()
        let manager = makeManager(
            windows: [win],
            launcher: MockApplicationLaunching(),
            windowManager: mover
        )

        _ = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .topLeft)]),
            options: .default
        )

        let expected = WorkspaceTestFixtures.expectedAXFrame(for: .topLeft, display: display)
        #expect(mover.movedWindows.first?.frame == expected)
    }

    // MARK: - Auto-launch (J2.2, BR-WORK-003)

    @Test("An offline app is launched, then placed once it draws a window")
    func launchesOfflineApp() async throws {
        // The honest version of this test: the app is genuinely absent from the
        // window list until it is launched. `restore` reads the list three times
        // for an offline app — once for the preflight snapshot, once per placement,
        // and once again after a successful launch — so the window must appear only
        // on the third read. Pre-seeding it would let the test pass without ever
        // exercising the launch path.
        let win = WorkspaceTestFixtures.window(
            id: 5, bundle: "com.editor", pid: 2000,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(
            installedBundleIDs: ["com.editor"],
            pidsAssignedOnLaunch: ["com.editor": 2000]
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        // The window exists only while the app is running, and it is not running
        // until the pass launches it.
        accessibility.visibleWindowsProvider = { launcher.launchAttempts.isEmpty ? [] : [win] }
        let element = AXUIElementCreateApplication(win.pid)
        accessibility.mockElementByWindowID = [win.id: element]
        mover.onMove = { _, frame, addressed in
            if let addressed { accessibility.mockFrames[addressed] = frame }
        }
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: mover,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        #expect(launcher.launchAttempts == ["com.editor"])
        #expect(launcher.waitAttempts == [2000])
        #expect(summary.placedCount == 1)
        #expect(mover.moveCallCount == 1)
    }

    @Test("An already-running app is placed without being relaunched")
    func runningAppIsNotRelaunched() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 6, bundle: "com.editor", pid: 2000,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor"])
        let manager = makeManager(windows: [win], launcher: launcher, windowManager: mover)

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.placedCount == 1)
        #expect(launcher.launchAttempts.isEmpty)
    }

    @Test("E4 — an app that cannot be launched is skipped as notInstalled")
    func notInstalledSkipped() async throws {
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(installedBundleIDs: [])
        let manager = makeManager(windows: [], launcher: launcher, windowManager: mover)

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.gone", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.placedCount == 0)
        #expect(summary.skipped.map(\.reason) == [.notInstalled])
        #expect(summary.skipped.first?.bundleIdentifier == "com.gone")
        #expect(mover.moveCallCount == 0)
    }

    @Test("E5 — an app that launches but never draws a window is skipped as launchTimeout")
    func launchTimeoutSkipped() async throws {
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(
            installedBundleIDs: ["com.slow"],
            hangingBundleIDs: ["com.slow"],
            processIdentifiers: ["com.slow": 3000]
        )
        let manager = makeManager(windows: [], launcher: launcher, windowManager: mover)

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.slow", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.skipped.map(\.reason) == [.launchTimeout])
        #expect(mover.moveCallCount == 0)
    }

    @Test("E10 — a running app with no window is skipped as noWindow, without launching")
    func noWindowSkipped() async throws {
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor"])
        let manager = makeManager(windows: [], launcher: launcher, windowManager: mover)

        // launchOfflineApps = false → the pass must not attempt a launch at all.
        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .positionOnly
        )

        #expect(summary.skipped.map(\.reason) == [.noWindow])
        #expect(launcher.launchAttempts.isEmpty)
    }

    // MARK: - Best-effort continuation (BR-WORK-004)

    @Test("One missing app does not abort the others")
    func continuesAfterFailure() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 7, bundle: "com.good", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(installedBundleIDs: [])
        let manager = makeManager(windows: [win], launcher: launcher, windowManager: mover)

        let summary = try await manager.restore(
            workspace: workspace([
                WindowPlacement(bundleIdentifier: "com.missing", zone: .rightHalf, orderIndex: 0),
                WindowPlacement(bundleIdentifier: "com.good", zone: .leftHalf, orderIndex: 1)
            ]),
            options: .default
        )

        #expect(summary.placedCount == 1)
        #expect(summary.totalPlacements == 2)
        #expect(summary.skipped.count == 1)
        #expect(mover.moveCallCount == 1)
    }

    @Test("E6 — a window that refuses to move is logged, not fatal")
    func moveFailureTolerated() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 8, bundle: "com.stuck", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let mover = MockWindowManaging()
        mover.moveError = AccessibilityError.cannotComplete
        let manager = makeManager(windows: [win], launcher: MockApplicationLaunching(), windowManager: mover)

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.stuck", zone: .leftHalf)]),
            options: .default
        )

        // The move was attempted three times but failed, so the placement is not
        // counted as placed — yet restore did not throw.
        #expect(mover.moveCallCount == RestoreVerificationPolicy.maxAttempts)
        #expect(summary.placedCount == 0)
        #expect(summary.failed.map(\.reason) == [.moveFailed])
    }

    // MARK: - Preflight (E11)

    @Test("Restore aborts before any move when Accessibility is denied")
    func deniedAbortsEarly() async {
        let mover = MockWindowManaging()
        let manager = makeManager(
            windows: [], launcher: MockApplicationLaunching(), windowManager: mover, trusted: false
        )
        await #expect(throws: RestoreError.accessibilityDenied) {
            _ = try await manager.restore(
                workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)])
            )
        }
        #expect(mover.moveCallCount == 0)
    }

    @Test("E8 — an empty workspace is a no-op, not an error")
    func emptyWorkspaceNoOp() async throws {
        let manager = makeManager(
            windows: [], launcher: MockApplicationLaunching(), windowManager: MockWindowManaging()
        )
        let summary = try await manager.restore(workspace: workspace([]))
        #expect(summary.isEmpty)
        #expect(summary.placedCount == 0)
    }

    // MARK: - Cascade (J2.4, E9)

    @Test("Extra windows cascade inside the zone and never leave it")
    func cascadeStaysInZone() {
        let base = CGRect(x: 0, y: 0, width: 480, height: 480)
        for step in 1...6 {
            let cascaded = WorkspaceManager.cascadeFrame(base: base, step: step)
            #expect(cascaded.minX >= base.minX)
            #expect(cascaded.maxX <= base.maxX + 0.5)
            #expect(cascaded.minY >= base.minY - 0.5)
            #expect(cascaded.maxY <= base.maxY + 0.5)
        }
    }

    @Test("Cascade moves the top-left corner down-and-right in AppKit space")
    func cascadeDirection() {
        // Classic cascade reveals each stacked window's title bar, which sits at
        // the TOP of the window (AppKit maxY). So the invariant is: the left edge
        // moves right and the top edge drops — while the bottom stays put, which
        // is what keeps the whole cascade inside the zone.
        let base = CGRect(x: 0, y: 0, width: 800, height: 800)
        let first = WorkspaceManager.cascadeFrame(base: base, step: 1)
        #expect(first.minX > base.minX)
        #expect(first.maxY < base.maxY)
        #expect(first.minY == base.minY)
    }

    @Test("A zero-size base returns unchanged (no division blow-up)")
    func cascadeZeroBase() {
        #expect(WorkspaceManager.cascadeFrame(base: .zero, step: 3) == .zero)
    }

    // MARK: - Timestamp (J2.6)

    @Test("A successful restore stamps lastRestoredAt")
    func stampsRestoreTime() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 9, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let dir = tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = WorkspaceStore(directoryURL: dir)
        let placement = WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)
        let saved = Workspace(name: "Coding", placements: [placement])
        try await store.upsert(saved)

        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = [win]
        let element = AXUIElementCreateApplication(win.pid)
        accessibility.mockElementByWindowID = [win.id: element]
        let mover = MockWindowManaging()
        mover.onMove = { _, frame, addressed in
            if let addressed { accessibility.mockFrames[addressed] = frame }
        }
        let manager = WorkspaceManager(
            store: store,
            accessibilityService: accessibility,
            windowManager: mover,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: MockApplicationLaunching(),
            preferences: WorkspaceTestFixtures.preferences(),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())
        // Load the store-backed workspace so restore can find it by id.
        await manager.reload()
        let target = try #require(manager.workspaces.first)

        _ = try await manager.restore(workspace: target)

        let reloaded = try await store.loadWorkspaces()
        #expect(reloaded.first?.lastRestoredAt != nil)
    }

    // MARK: - Proportional Custom Ratios (80/20, 70/30)

    @Test("Custom proportional normalizedRect (80/20) restores exact proportional width")
    func proportionalNormalizedRectRestoration() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 10, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 500, height: 500)
        )
        let mover = MockWindowManaging()
        let manager = makeManager(
            windows: [win],
            launcher: MockApplicationLaunching(),
            windowManager: mover
        )

        // Custom 80/20 ratio: x: 0, y: 0, width: 0.8, height: 1.0 (top-left normalized)
        let customPlacement = WindowPlacement(
            bundleIdentifier: "com.editor",
            zone: .leftHalf,
            expectedWindowCount: 1,
            orderIndex: 0,
            normalizedRect: CGRect(x: 0, y: 0, width: 0.8, height: 1.0)
        )

        let summary = try await manager.restore(workspace: workspace([customPlacement]))
        #expect(summary.placedCount == 1)
        #expect(mover.movedWindows.count == 1)

        // In 1440x900 display (visibleFrame width: 1440), 80% width is 1152
        let targetFrame = mover.movedWindows[0].frame
        #expect(targetFrame.width == 1152)
    }
}
