import ApplicationServices
import CoreGraphics
import Foundation
import Testing

@testable import FlowSnap

/// The "restored onto the wrong window" half of the reported defect (T022).
///
/// A restore used to measure one window and then, at write time, re-resolve a
/// target from its frame. For Chromium-family apps the AX window list leads with
/// small hidden helper surfaces (tab search, extension popups, picture-in-picture)
/// that carry a real, addressable frame, so the re-resolution could land on one of
/// those: the write succeeded, the summary counted the placement `placed`, and the
/// user's actual document window never moved.
///
/// The fix carries the measured element through to the write. These tests pin that
/// the element handed to `move` is the exact element the snapshot was read from, so
/// there is no second guess left to get wrong.
@MainActor
@Suite("WorkspaceManager Restore Target")
struct WorkspaceRestoreTargetTests {

    private let display = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        scaleFactor: 2.0,
        isPrimary: true
    )

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapRestoreTargetTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func workspace(_ placements: [WindowPlacement]) -> Workspace {
        Workspace(name: "Test", placements: placements)
    }

    /// A distinct, real AXUIElement handle. `AXUIElementCreateApplication` returns a
    /// valid opaque object for any pid, which is all we need to assert identity —
    /// the restore path never messages it, the mock `move` just records it.
    private func element(pid: pid_t) -> AXUIElement {
        AXUIElementCreateApplication(pid)
    }

    @Test("The move is addressed to the exact element the window was measured from")
    func carriesMeasuredElement() async throws {
        let win = WorkspaceTestFixtures.window(
            id: 42, bundle: "com.editor", pid: 2200,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let measured = element(pid: 2200)

        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.managedWindowsByPID = [2200: [win]]
        accessibility.mockElementByWindowID = [win.id: measured]

        let mover = MockWindowManaging()
        mover.onMove = { _, frame, addressed in
            if let addressed { accessibility.mockFrames[addressed] = frame }
        }
        let launcher = MockApplicationLaunching(processIdentifiers: ["com.editor": 2200])
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: mover,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        // P0.5: the mock window never appears in the real WindowServer list, so
        // pin presentation with a checker that reports it presented.
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.placedCount == 1)
        #expect(mover.moveCallCount == 1)
        // The whole point: the write targets the element we read, not a re-resolution.
        let addressed: AXUIElement? = try #require(mover.movedElements.first)
        #expect(addressed === measured)
    }

    @Test("The primary window is the largest, so a helper surface cascades behind it")
    func largestWindowTakesTheZone() async throws {
        // A big document window and a small helper surface, both restorable. The
        // document window must be the one that lands on the zone (index 0 of the
        // move list), because a restore that hands the zone to a 200×200 panel is
        // indistinguishable from "restore lost my window".
        let document = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", pid: 2300,
            appKitFrame: CGRect(x: 100, y: 100, width: 900, height: 700)
        )
        let helper = WorkspaceTestFixtures.window(
            id: 2, bundle: "com.editor", pid: 2300,
            appKitFrame: CGRect(x: 120, y: 120, width: 200, height: 160)
        )

        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.managedWindowsByPID = [2300: [helper, document]] // helper listed first
        accessibility.mockElementByWindowID = [
            document.id: element(pid: 11),
            helper.id: element(pid: 12)
        ]

        let mover = MockWindowManaging()
        mover.onMove = { _, frame, addressed in
            if let addressed { accessibility.mockFrames[addressed] = frame }
        }
        let launcher = MockApplicationLaunching(processIdentifiers: ["com.editor": 2300])
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: mover,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        // P0.5: scriptable presentation checker defaulting to `.presented`.
        manager.injectPresentationChecker(MockCurrentScreenVisibilityChecker())

        _ = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: RestoreOptions(launchOfflineApps: true, cascadeExtraWindows: true)
        )

        // Two windows, both moved; the first (the one that got the zone) is the
        // document window regardless of the order the app listed them in.
        #expect(mover.moveCallCount == 2)
        #expect(mover.movedWindows.first?.window.id == document.id)
    }

    @Test("A WindowServer-fallback window carries no element and is unverifiable")
    func fallbackWindowHasNilElement() async throws {
        // When the app exposes nothing addressable through AX, restore falls back to
        // the on-screen list, which cannot supply an element. P0 refuses to guess:
        // no move is attempted and the placement is explicitly unverifiable.
        //
        // The window's pid deliberately differs from the running pid so the AX path
        // finds nothing and the fallback is the only way this placement can succeed.
        let win = WorkspaceTestFixtures.window(
            id: 7, bundle: "com.editor", pid: 9999,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = [win]

        let mover = MockWindowManaging()
        let launcher = MockApplicationLaunching(processIdentifiers: ["com.editor": 2400])
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: mover,
            displayManager: MockDisplayManager(displays: [display]),
            launcher: launcher,
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )

        let summary = try await manager.restore(
            workspace: workspace([WindowPlacement(bundleIdentifier: "com.editor", zone: .leftHalf)]),
            options: .default
        )

        #expect(summary.placedCount == 0)
        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .unverifiablePlacement)
        #expect(mover.moveCallCount == 0)
    }
}
