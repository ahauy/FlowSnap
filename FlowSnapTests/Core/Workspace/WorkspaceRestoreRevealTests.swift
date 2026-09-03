import ApplicationServices
import CoreGraphics
import Foundation
import Testing

@testable import FlowSnap

/// The "restored but invisible" half of the reported defect (T021): a restore can
/// place every window perfectly and still show the user nothing, because a hidden
/// app (Cmd+H) or one whose windows live on another Space keeps a fully
/// addressable AX window with a real frame — `matchingWindows` finds it, the move
/// succeeds, and the pass counts it `placed` without ever surfacing it.
///
/// These tests pin the contract of the post-move `reveal(bundleID:)` call:
/// it fires exactly when a window was placed, never when one wasn't, and its own
/// failure cannot downgrade a `placed` outcome.
@MainActor
@Suite("WorkspaceManager Restore Reveal")
struct WorkspaceRestoreRevealTests {

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
        windowManager: MockWindowManaging
    ) -> WorkspaceManager {
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = windows
        accessibility.mockElementByWindowID = Dictionary(uniqueKeysWithValues: windows.map {
            ($0.id, AXUIElementCreateApplication($0.pid))
        })
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
        // the reveal contract below is unchanged.
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())
        return manager
    }

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapRevealTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func workspace(_ placements: [WindowPlacement]) -> Workspace {
        Workspace(name: "Test", placements: placements)
    }

    @Test("A placed window reveals its app, so a hidden one reappears")
    func placedWindowRevealsItsApp() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 11, bundle: "com.editor", appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor"])
        let manager = makeManager(
            windows: [win], launcher: launcher, windowManager: MockWindowManaging()
        )

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.placedCount == 1)
        #expect(launcher.revealAttempts == ["com.editor"])
    }

    @Test("A placement that was never moved is never revealed — nothing to surface")
    func unplacedWindowIsNotRevealed() async throws {
        // E4: the app cannot be launched, so no window is placed and reveal must
        // not fire (revealing a not-installed app is meaningless).
        let launcher = MockApplicationLaunching(installedBundleIDs: [])
        let manager = makeManager(
            windows: [], launcher: launcher, windowManager: MockWindowManaging()
        )

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.gone", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.skipped.map(\.reason) == [.notInstalled])
        #expect(launcher.revealAttempts.isEmpty)
    }

    @Test("E6 — a window that refuses to move is not revealed")
    func failedMoveIsNotRevealed() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 12, bundle: "com.stuck", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let mover = MockWindowManaging()
        mover.moveError = AccessibilityError.cannotComplete
        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.stuck"])
        let manager = makeManager(windows: [win], launcher: launcher, windowManager: mover)

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.stuck", zone: .leftHalf)]),
            options: .default
        )

        // The move failed, so the placement is not counted as placed and the app is
        // left alone — surfacing an app whose window never moved would flash it at
        // its old position for no gain.
        #expect(summary.placedCount == 0)
        #expect(launcher.revealAttempts.isEmpty)
    }

    @Test("A refused reveal does not downgrade a placed window")
    func refusedRevealKeepsThePlacedOutcome() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 13, bundle: "com.editor", appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let launcher = MockApplicationLaunching(installedBundleIDs: ["com.editor"])
        launcher.unrevealableBundleIDs = ["com.editor"]
        let manager = makeManager(
            windows: [win], launcher: launcher, windowManager: MockWindowManaging()
        )

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        // Activation was refused, but the window is where it belongs — the outcome
        // stays `placed`; reveal is best-effort by contract.
        #expect(summary.placedCount == 1)
        #expect(summary.isFullSuccess)
        #expect(launcher.revealAttempts == ["com.editor"])
    }
}
