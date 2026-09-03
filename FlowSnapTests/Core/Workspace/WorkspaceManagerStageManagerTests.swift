import ApplicationServices
import CoreGraphics
import Foundation
import Testing

@testable import FlowSnap

/// Unit test suite for US-WORK-018 (Stage Manager Multi-Window Auto-Grouping).
///
/// Traces to: test-plan.md (TC-SMA-003, TC-SMA-004, TC-SMA-005, TC-SMA-006).
@MainActor
@Suite("WorkspaceManager Stage Manager Auto-Grouping Tests")
struct WorkspaceManagerStageManagerTests {

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
        windowManager: MockWindowManaging = MockWindowManaging(),
        stageManagerEnabled: Bool = false
    ) -> (WorkspaceManager, MockAccessibilityService) {
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = windows
        // Assign distinct mock elements so we can assert on raised elements
        for win in windows {
            let el = AXUIElementCreateSystemWide()
            accessibility.mockWindowElements[win.id] = el
        }

        let stageManagerDetector = MockStageManagerDetector(isStageManagerEnabled: stageManagerEnabled)
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: windowManager,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            stageManagerDetector: stageManagerDetector,
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        return (manager, accessibility)
    }

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapSMTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func workspace(_ placements: [WindowPlacement]) -> Workspace {
        Workspace(name: "Test", placements: placements)
    }

    @Test("TC-SMA-003: Multi-window restore with Stage Manager active reveals anchor, raises secondary, and locks focus on anchor")
    func stageManagerActiveRevealsOnlyAnchorAndRaisesSecondary() async throws {
        let win1 = WorkspaceTestFixtures.window(
            id: 101, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 800, height: 900)
        )
        let win2 = WorkspaceTestFixtures.window(
            id: 102, bundle: "com.browser", appKitFrame: CGRect(x: 800, y: 0, width: 640, height: 900)
        )

        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor", "com.browser"])
        let (manager, accessibility) = makeManager(
            windows: [win1, win2],
            launcher: launcher,
            stageManagerEnabled: true
        )

        let ws = workspace([
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightHalf, orderIndex: 1)
        ])

        let summary = try await manager.restore(workspace: ws, options: .default)

        #expect(summary.placedCount == 2)
        #expect(summary.skipped.isEmpty)

        // Anchor app (com.editor) was revealed (activated)
        #expect(launcher.revealAttempts == ["com.editor"])

        // Secondary app (com.browser) was NOT revealed via launcher
        #expect(!launcher.revealAttempts.contains("com.browser"))

        // Secondary window was raised via kAXRaiseAction on accessibility
        let el1 = accessibility.mockWindowElements[win1.id]
        let el2 = accessibility.mockWindowElements[win2.id]
        #expect(accessibility.raisedElements.contains(where: { $0 == el2 }))

        // Anchor window received final focus lock (was raised after secondary window)
        #expect(accessibility.raisedElements.last == el1)
    }

    @Test("TC-SMA-004: Multi-window restore with Stage Manager inactive reveals all placed applications")
    func stageManagerInactiveRevealsAllApps() async throws {
        let win1 = WorkspaceTestFixtures.window(
            id: 201, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 800, height: 900)
        )
        let win2 = WorkspaceTestFixtures.window(
            id: 202, bundle: "com.browser", appKitFrame: CGRect(x: 800, y: 0, width: 640, height: 900)
        )

        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor", "com.browser"])
        let (manager, _) = makeManager(
            windows: [win1, win2],
            launcher: launcher,
            stageManagerEnabled: false
        )

        let ws = workspace([
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightHalf, orderIndex: 1)
        ])

        let summary = try await manager.restore(workspace: ws, options: .default)

        #expect(summary.placedCount == 2)
        #expect(launcher.revealAttempts == ["com.editor", "com.browser"])
    }

    @Test("TC-SMA-005: Single-app workspace restore with Stage Manager active reveals the single app")
    func singleAppWorkspaceWithStageManagerActive() async throws {
        let win1 = WorkspaceTestFixtures.window(
            id: 301, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 1440, height: 900)
        )

        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor"])
        let (manager, _) = makeManager(
            windows: [win1],
            launcher: launcher,
            stageManagerEnabled: true
        )

        let ws = workspace([
            WindowPlacement(bundleIdentifier: "com.editor", zone: .maximize)
        ])

        let summary = try await manager.restore(workspace: ws, options: .default)

        #expect(summary.placedCount == 1)
        #expect(launcher.revealAttempts == ["com.editor"])
    }

    @Test("TC-SMA-006: Secondary app that is hidden has unhide called and is raised without reveal")
    func hiddenSecondaryAppIsUnhiddenAndRaised() async throws {
        let win1 = WorkspaceTestFixtures.window(
            id: 401, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 800, height: 900)
        )
        let win2 = WorkspaceTestFixtures.window(
            id: 402, bundle: "com.browser", appKitFrame: CGRect(x: 800, y: 0, width: 640, height: 900)
        )

        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor", "com.browser"])
        let (manager, accessibility) = makeManager(
            windows: [win1, win2],
            launcher: launcher,
            stageManagerEnabled: true
        )

        let ws = workspace([
            WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf, orderIndex: 0),
            WindowPlacement(bundleIdentifier: "com.browser", zone: .rightHalf, orderIndex: 1)
        ])

        let summary = try await manager.restore(workspace: ws, options: .default)

        #expect(summary.placedCount == 2)
        #expect(launcher.unhideAttempts.contains("com.browser"))
        #expect(!launcher.revealAttempts.contains("com.browser"))
        let el2 = accessibility.mockWindowElements[win2.id]
        #expect(accessibility.raisedElements.contains(where: { $0 == el2 }))
    }
}
