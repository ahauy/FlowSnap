import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// T011 — cross-display restoration (US-WORK-011 spec §5 E8, BR-WORK-007,
/// RISK-WORK-001).
///
/// The mandatory case for this feature: a workspace saved on one display geometry
/// must restore correctly on another. It is "correct" only if the stored value is
/// a *zone intent* and geometry is recomputed from the live topology — so the test
/// asserts the restored frame is a fraction of the NEW display, and explicitly not
/// the pixel rectangle that was on screen at save time.
@MainActor
@Suite("Workspace Cross-Display")
struct WorkspaceCrossDisplayTests {

    /// 1440×900 laptop panel.
    private let laptop = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        scaleFactor: 2.0,
        isPrimary: true
    )

    /// 2560×1440 external panel, taller and wider — the shape change that would
    /// expose a stored-pixels implementation.
    private let external = Display(
        id: 2,
        frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        visibleFrame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
        scaleFactor: 1.0,
        isPrimary: true
    )

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapCrossTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func makeManager(
        displays: [Display],
        windows: [ManagedWindow],
        windowManager: MockWindowManaging
    ) -> WorkspaceManager {
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = windows
        return WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: windowManager,
            displayManager: MockDisplayManager(displays: displays),
            launcher: MockApplicationLaunching(),
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
    }

    @Test("Saving on a 1440x900 panel stores a zone, not pixels")
    func saveStoresIntent() async throws {
        let editor = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let manager = makeManager(displays: [laptop], windows: [editor], windowManager: MockWindowManaging())

        let placements = try await manager.capture(
            from: [WindowGroupSnapshot(window: editor)].compactMap { $0 }
        )
        #expect(placements.first?.zone == .leftHalf)

        // The intent survives serialization: nothing resolution-specific is on disk.
        let encoded = try JSONEncoder().encode(placements)
        let decoded = try JSONDecoder().decode([WindowPlacement].self, from: encoded)
        #expect(decoded == placements)
    }

    @Test("E8: a leftHalf saved on 1440x900 restores to 1280 wide on 2560x1440")
    func restoresToNewGeometry() async throws {
        let editor = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let saveManager = makeManager(
            displays: [laptop], windows: [editor], windowManager: MockWindowManaging()
        )
        let placements = try await saveManager.capture(
            from: [WindowGroupSnapshot(window: editor)].compactMap { $0 }
        )
        let saved = Workspace(name: "Coding", placements: placements)

        // Monitor swap: the editor's window is now wherever the user left it, and
        // the only display is the 2560x1440 panel.
        let movedWindow = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 1800, y: 300, width: 600, height: 400)
        )
        let mover = MockWindowManaging()
        let restoreManager = makeManager(
            displays: [external], windows: [movedWindow], windowManager: mover
        )

        let summary = try await restoreManager.restore(workspace: saved, options: .positionOnly)
        #expect(summary.placedCount == 1)

        let frame = try #require(mover.movedWindows.first).frame
        let expectedAppKit = WorkspaceTestFixtures.expectedAXFrame(
            for: .leftHalf, display: external
        )

        // Recomputed against the new display — half of 2560, full height of 1440.
        #expect(frame == expectedAppKit)
        #expect(abs(frame.width - 1280) < 1)
        #expect(abs(frame.height - 1440) < 1)

        // And explicitly NOT the pixels from save time (720x900), which is the
        // failure mode BR-WORK-007 exists to prevent.
        #expect(frame.width != 720)
        #expect(frame.height != 900)
    }

    @Test("E8: a window on the secondary display keeps its zone on that display")
    func resolvesDisplayPerWindow() async throws {
        // Dual-monitor: primary 1440x900 at x=0, secondary 2560x1440 at x=1440.
        let secondary = Display(
            id: 2,
            frame: CGRect(x: 1440, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 1440, y: 0, width: 2560, height: 1440),
            scaleFactor: 1.0,
            isPrimary: false
        )
        // AppKit space: the right half of the secondary panel.
        let onSecondary = WorkspaceTestFixtures.window(
            id: 3, bundle: "com.mail",
            appKitFrame: CGRect(x: 1440 + 1280, y: 0, width: 1280, height: 1440)
        )
        let mover = MockWindowManaging()
        let manager = makeManager(
            displays: [laptop, secondary], windows: [onSecondary], windowManager: mover
        )

        let summary = try await manager.restore(
            workspace: Workspace(name: "Mail", placements: [
                WindowPlacement(bundleIdentifier: "com.mail", zone: .rightHalf)
            ]),
            options: .positionOnly
        )
        #expect(summary.placedCount == 1)

        let frame = try #require(mover.movedWindows.first).frame
        // The zone must resolve on the display the window is actually on, so the
        // frame's right edge lands at the secondary panel's right edge (x=4000).
        let appKit = CoordinateTransformer.toAppKit(rect: frame, primaryScreenHeight: laptop.frame.height)
        #expect(abs(appKit.maxX - 4000) < 1)
        #expect(abs(appKit.width - 1280) < 1)
    }

    @Test("E8: a resolution change with the same topology still recomputes")
    func resolutionChange() async throws {
        // Same physical monitor, different resolution — 1440x900 → 1920x1200.
        let resized = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1200),
            visibleFrame: CGRect(x: 0, y: 0, width: 1920, height: 1200),
            scaleFactor: 1.0,
            isPrimary: true
        )
        let win = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", appKitFrame: CGRect(x: 0, y: 600, width: 960, height: 600)
        )
        let mover = MockWindowManaging()
        let manager = makeManager(displays: [resized], windows: [win], windowManager: mover)

        _ = try await manager.restore(
            workspace: Workspace(name: "Coding", placements: [
                WindowPlacement(bundleIdentifier: "com.editor", zone: .topLeft)
            ]),
            options: .positionOnly
        )

        let frame = try #require(mover.movedWindows.first).frame
        let expected = WorkspaceTestFixtures.expectedAXFrame(for: .topLeft, display: resized)
        #expect(frame == expected)
    }

    @Test("E8: a window on a display stacked above the primary resolves to that display")
    func verticallyStackedDisplay() async throws {
        // Regression guard for the coordinate convention in `visibleFrame(of:)`.
        // Displays are laid out in AppKit space (y-up), so a monitor physically
        // ABOVE the primary has a frame with a positive y-origin. A window there
        // must resolve to that monitor, not fall back to the primary — the failure
        // mode that silently restores a window onto the wrong screen.
        let upper = Display(
            id: 2,
            frame: CGRect(x: 0, y: 900, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 900, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: false
        )
        // AppKit space: the left half of the upper monitor (y in [900,1800]).
        let onUpper = WorkspaceTestFixtures.window(
            id: 4, bundle: "com.mail",
            appKitFrame: CGRect(x: 0, y: 900, width: 720, height: 900)
        )
        let mover = MockWindowManaging()
        let manager = makeManager(
            displays: [laptop, upper], windows: [onUpper], windowManager: mover
        )

        _ = try await manager.restore(
            workspace: Workspace(name: "Mail", placements: [
                WindowPlacement(bundleIdentifier: "com.mail", zone: .leftHalf)
            ]),
            options: .positionOnly
        )

        let axFrame = try #require(mover.movedWindows.first).frame
        let appKit = CoordinateTransformer.toAppKit(rect: axFrame, primaryScreenHeight: laptop.frame.height)
        // The zone must land on the upper monitor: its bottom edge at y=900, and
        // half of 1440 wide. If it wrongly resolved to the primary, maxY would be
        // 900 (the primary's top) instead of 1800 (the upper monitor's top).
        #expect(abs(appKit.minY - 900) < 1)
        #expect(abs(appKit.maxY - 1800) < 1)
        #expect(abs(appKit.width - 720) < 1)
    }
}
