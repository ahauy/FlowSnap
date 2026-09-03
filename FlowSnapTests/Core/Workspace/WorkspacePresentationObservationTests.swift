import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import FlowSnap

/// P0.5 — workspace presentation observation test matrix (spec Phase 7, T1–T14).
///
/// The restore pipeline already proves geometry and AX state (ADR-0008). These
/// tests pin the *presentation* axis: after a move is verified, a one-shot
/// on-screen observation decides whether the window is actually presented on
/// the user's current screen, and the summary reports it honestly — never a
/// false green, never a false orange.
///
/// Observation is scripted through `MockCurrentScreenVisibilityChecker`,
/// installed on the harness manager's own instance via the per-instance test
/// seam (`injectPresentationChecker`) — the spec's §12/§13 file lists forbid
/// touching `WorkspaceManager.swift`, so there is no constructor injection.
@MainActor
@Suite("Workspace Presentation Observation")
struct WorkspacePresentationObservationTests {

    private let display = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        scaleFactor: 2.0,
        isPrimary: true
    )

    // MARK: - Fixtures

    private func tempDir() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("FlowSnapPresentationTests-\(UUID().uuidString)", isDirectory: true)
    }

    /// `FlowSnap.`-qualified because the macOS SDK's SwiftUI also exports a
    /// `WindowPlacement`, which makes the bare name ambiguous next to
    /// `import SwiftUI`.
    private func placement(_ bundle: String, order: Int = 0) -> FlowSnap.WindowPlacement {
        FlowSnap.WindowPlacement(bundleIdentifier: bundle, zone: .leftHalf, orderIndex: order)
    }

    /// Type of the tuple `makeHarness` returns, spelled out so the cleanup
    /// helper can take it without a giant generic signature.
    typealias Harness = (
        manager: WorkspaceManager,
        accessibility: MockAccessibilityService,
        mover: MockWindowManaging,
        launcher: MockApplicationLaunching,
        checker: MockCurrentScreenVisibilityChecker
    )

    /// Everything a presentation test needs, wired together.
    ///
    /// The mock checker is installed on the returned manager's own instance and
    /// defaults every observation to `.presented`, so presentation-agnostic
    /// scenarios keep their pre-P0.5 expectations. The accessibility double
    /// knows each window's initial frame — that is the pre-move read the
    /// fullscreen re-resolve (§4.5) consumes.
    private func makeHarness(
        windows: [ManagedWindow],
        checker: MockCurrentScreenVisibilityChecker = MockCurrentScreenVisibilityChecker()
    ) -> Harness {
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = windows
        accessibility.managedWindowsByPID = Dictionary(grouping: windows, by: \.pid)
        let elements = Dictionary(uniqueKeysWithValues: windows.map {
            ($0.id, AXUIElementCreateApplication($0.pid))
        })
        accessibility.mockElementByWindowID = elements
        for window in windows {
            if let element = elements[window.id] {
                accessibility.mockFrames[element] = window.frame
            }
        }

        let mover = MockWindowManaging()
        mover.onMove = { _, frame, element in
            if let element { accessibility.mockFrames[element] = frame }
        }
        let launcher = MockApplicationLaunching(
            processIdentifiers: Dictionary(
                windows.map { ($0.bundleIdentifier ?? "", $0.pid) },
                uniquingKeysWith: { first, _ in first }
            )
        )

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
        manager.injectPresentationChecker(checker)
        return (manager, accessibility, mover, launcher, checker)
    }

    /// Removes the harness manager's checker override so the per-instance
    /// registry never leaks entries across tests.
    private func cleanup(_ harness: Harness) {
        harness.manager.injectPresentationChecker(nil)
    }

    // MARK: - T1 — same-Space: placed

    @Test("T1 — a moved window found on screen counts placed and stays green")
    func movedAndPresentedCountsPlaced() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 1, bundle: "com.editor", pid: 1001,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 1)
        #expect(summary.movedButNotPresentedCount == 0)
        #expect(summary.isFullSuccess)
        #expect(harness.mover.moveCallCount == 1)
        #expect(harness.checker.isOnCurrentScreenCallCount == 1)
        #expect(harness.checker.isOnCurrentScreenCalls == [1])
    }

    // MARK: - T2 — cross-Space: movedButNotPresented (core test)

    @Test("T2 — a moved window absent from the screen is movedButNotPresented, not placed")
    func movedButNotPresentedIsReportedHonestly() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 2, bundle: "com.editor", pid: 1002,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        harness.checker.observationResults[2] = .notPresented

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 0)
        #expect(summary.movedButNotPresentedCount == 1)
        #expect(summary.failed.isEmpty)
        #expect(summary.unverifiable.isEmpty)
        #expect(!summary.isFullSuccess)
        #expect(summary.headline.contains("was positioned but is not on the current screen"))
    }

    // MARK: - T3 — setFrame fails

    @Test("T3 — a move failure after the allowed attempts never reaches the observation")
    func moveFailureSkipsObservation() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 3, bundle: "com.stuck", pid: 1003,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = [window]
        accessibility.mockElementByWindowID = [window.id: AXUIElementCreateApplication(window.pid)]
        // The running pid must be registered so the AX path is taken; without it
        // `matchingWindows` falls back to the WindowServer list (nil element) and
        // the P0 guard reports unverifiable before any move is attempted.
        // cannotComplete is recoverable, so the pass burns all three attempts.
        accessibility.setFrameError = AccessibilityError.cannotComplete
        let checker = MockCurrentScreenVisibilityChecker()
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: WindowManager(accessibilityService: accessibility),
            displayManager: MockDisplayManager(displays: [display]),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.stuck": 1003]),
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        manager.injectPresentationChecker(checker)
        defer { manager.injectPresentationChecker(nil) }

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.stuck")]),
            options: .positionOnly
        )

        #expect(summary.failedCount == 1)
        #expect(summary.failed.first?.reason == .moveFailed)
        #expect(summary.movedButNotPresentedCount == 0)
        #expect(checker.isOnCurrentScreenCallCount == 0)
        #expect(accessibility.setFrameCallCount == RestoreVerificationPolicy.maxAttempts)
    }

    // MARK: - T4 — AX element nil (WindowServer fallback)

    @Test("T4 — an element-less fallback window is unverifiable before any observation")
    func missingElementIsUnverifiableWithoutObservation() async throws {
        // The window's pid differs from the running pid so the AX path finds
        // nothing and the WindowServer fallback (no element) is the only source.
        let window = WorkspaceTestFixtures.window(
            id: 7, bundle: "com.editor", pid: 9999,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let accessibility = MockAccessibilityService(isTrusted: true)
        accessibility.mockVisibleWindows = [window]
        let checker = MockCurrentScreenVisibilityChecker()
        let manager = WorkspaceManager(
            store: WorkspaceStore(directoryURL: tempDir()),
            accessibilityService: accessibility,
            windowManager: MockWindowManaging(),
            displayManager: MockDisplayManager(displays: [display]),
            launcher: MockApplicationLaunching(processIdentifiers: ["com.editor": 2400]),
            preferences: WorkspaceTestFixtures.preferences(gap: 0),
            ownBundleIdentifier: "com.flowsnap.app",
            loadAtInit: false
        )
        manager.injectPresentationChecker(checker)
        defer { manager.injectPresentationChecker(nil) }

        let summary = try await manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .default
        )

        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .unverifiablePlacement)
        #expect(summary.movedButNotPresentedCount == 0)
        #expect(accessibility.setFrameCallCount == 0)
        #expect(checker.isOnCurrentScreenCallCount == 0)
    }

    // MARK: - T5 — observation unverifiable

    @Test("T5 — an unobservable presentation is unverifiable, never movedButNotPresented")
    func unverifiableObservationStaysUnverifiable() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 5, bundle: "com.editor", pid: 1005,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        harness.checker.observationResults[5] = .unverifiable(reason: .cgWindowListUnavailable)

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .presentationUnverifiable)
        #expect(summary.movedButNotPresentedCount == 0)
        #expect(summary.placedCount == 0)
        #expect(harness.checker.isOnCurrentScreenCallCount == 1)
    }

    // MARK: - T6 — FlowSnap own windows in the WindowServer list

    @Test("T6 (unit) — an own-PID observation flows through as unverifiable, not notPresented")
    func ownPIDScriptedResultFlowsThrough() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 6, bundle: "com.editor", pid: 1006,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        harness.checker.observationResults[6] = .unverifiable(reason: .identityNotResolved)

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .presentationUnverifiable)
        #expect(summary.movedButNotPresentedCount == 0)
    }

    @Test("T6 (integration) — the production checker never reports a FlowSnap-owned window as presented")
    func productionCheckerFiltersOwnPIDWindows() {
        let probe = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        probe.title = "FlowSnap presentation probe"
        probe.orderFrontRegardless()
        let windowNumber = CGWindowID(probe.windowNumber)
        guard windowNumber != 0 else {
            // Headless environment: no WindowServer surface to observe.
            return
        }
        defer { probe.orderOut(nil) }

        let checker = CGWindowListCurrentScreenVisibilityChecker()
        // Invariant: a FlowSnap-owned window is never reported `presented`.
        // Whether the probe appears in the on-screen list depends on the WindowServer
        // environment — absent ⇒ `.notPresented` (honest: not on screen), present
        // ⇒ `.unverifiable(.identityNotResolved)` (own-PID guard) — both are safe.
        let result = checker.isOnCurrentScreen(windowID: windowNumber)
        #expect(result != .presented)
    }

    @Test("T6 (integration) — an id absent from the on-screen list is not presented")
    func productionCheckerReportsAbsentIDAsNotPresented() {
        let checker = CGWindowListCurrentScreenVisibilityChecker()
        // An id no live window carries. For a window that was just moved and
        // AX-verified, absence from the on-screen list is the not-presented
        // signature (other Space / hidden), not an unknown state.
        #expect(checker.isOnCurrentScreen(windowID: CGWindowID.max) == .notPresented)
    }

    @Test("T6 (integration) — re-resolution returns nil when no pid window sits at the frame")
    func productionReResolveReturnsNilWithoutMatch() {
        let checker = CGWindowListCurrentScreenVisibilityChecker()
        let result = checker.reResolveWindowID(
            pid: pid_t.max,
            frame: CGRect(x: 11_111, y: 22_222, width: 300, height: 200)
        )
        #expect(result == nil)
    }

    // MARK: - T7 — multiple windows of the same app

    @Test("T7 — only the primary window's observation produces a placement result")
    func onlyPrimaryWindowIsCounted() async throws {
        let primary = WorkspaceTestFixtures.window(
            id: 10, bundle: "com.editor", pid: 1010,
            appKitFrame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let extra = WorkspaceTestFixtures.window(
            id: 11, bundle: "com.editor", pid: 1010,
            appKitFrame: CGRect(x: 720, y: 0, width: 600, height: 800)
        )
        let harness = makeHarness(windows: [primary, extra])
        defer { cleanup(harness) }
        harness.checker.observationResults[10] = .notPresented
        harness.checker.observationResults[11] = .notPresented

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: RestoreOptions(launchOfflineApps: true, cascadeExtraWindows: true)
        )

        // The extra window is moved and logged but never adds a result, so two
        // not-presented windows still report exactly one placement issue.
        #expect(summary.movedButNotPresentedCount == 1)
        #expect(summary.placedCount == 0)
        #expect(harness.checker.isOnCurrentScreenCalls == [10])
    }

    // MARK: - T8 — minimized window

    @Test("T8 — a minimized window is unminimized, moved, then observed")
    func minimizedWindowIsRestoredThenObserved() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 12, bundle: "com.editor", pid: 1012,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        guard let element = harness.accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        harness.accessibility.mockMinimizedStates[element] = true

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 1)
        #expect(harness.accessibility.unminimizeCallCount == 1)
        #expect(harness.checker.isOnCurrentScreenCallCount == 1)
    }

    // MARK: - T9 — fullscreen window

    @Test("T9 — a fullscreen window exits, moves, and is observed after the exit")
    func fullscreenWindowIsRestoredThenObserved() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 13, bundle: "com.editor", pid: 1013,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        guard let element = harness.accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        harness.accessibility.mockFullScreenStates[element] = true
        // Identity survives the mock's fullscreen exit, so re-resolution finds
        // the same window id.
        harness.checker.reResolvedIDs[window.pid] = window.id

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 1)
        #expect(harness.accessibility.exitFullScreenCallCount == 1)
        #expect(harness.checker.reResolveWindowIDCallCount == 1)
        #expect(harness.checker.isOnCurrentScreenCalls == [window.id])
    }

    // MARK: - T10 — observation never retries

    @Test("T10 — the observation is one-shot: exactly one call per placement")
    func observationIsOneShot() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 14, bundle: "com.editor", pid: 1014,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        harness.checker.observationResults[14] = .notPresented

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(summary.movedButNotPresentedCount == 1)
        #expect(summary.placedCount == 0)
        #expect(!summary.isFullSuccess)
        #expect(harness.checker.isOnCurrentScreenCallCount == 1)
    }

    // MARK: - T11 — final reveal still fires only for placed

    @Test("T11 — the final reveal targets only the placed placement, not the not-presented one")
    func revealFiresOnlyForPlaced() async throws {
        let alpha = WorkspaceTestFixtures.window(
            id: 20, bundle: "com.alpha", pid: 1020,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let beta = WorkspaceTestFixtures.window(
            id: 21, bundle: "com.beta", pid: 1021,
            appKitFrame: CGRect(x: 200, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [alpha, beta])
        defer { cleanup(harness) }
        harness.checker.observationResults[20] = .presented
        harness.checker.observationResults[21] = .notPresented

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [
                placement("com.beta", order: 1), placement("com.alpha", order: 0)
            ]),
            options: .positionOnly
        )

        #expect(summary.placedCount == 1)
        #expect(summary.movedButNotPresentedCount == 1)
        #expect(harness.launcher.revealAttempts == ["com.alpha"])
        #expect(harness.mover.focusedWindows.first?.bundleIdentifier == "com.alpha")
    }

    // MARK: - T12 — banner renders all five buckets

    @Test("T12 — the banner model and rendering reflect all five buckets")
    func bannerRendersFiveBuckets() throws {
        let summary = RestoreSummary(
            placedCount: 2,
            totalPlacements: 6,
            failed: [RestoreIssue(bundleIdentifier: "com.failed", orderIndex: 1, reason: .moveFailed)],
            unverifiable: [RestoreIssue(bundleIdentifier: "com.unknown", orderIndex: 2, reason: .presentationUnverifiable)],
            skipped: [RestoreIssue(bundleIdentifier: "com.missing", orderIndex: 3, reason: .noWindow)],
            movedButNotPresented: [RestoreIssue(
                bundleIdentifier: "com.editor", orderIndex: 0, reason: .notPresentedOnCurrentScreen
            )]
        )

        // Model contract behind the banner: conservation across all five buckets
        // and an honest headline and success flag.
        #expect(summary.placedCount + summary.failedCount + summary.unverifiableCount
            + summary.skippedCount + summary.movedButNotPresentedCount == summary.totalPlacements)
        #expect(!summary.isFullSuccess)
        #expect(summary.headline.contains("was positioned but is not on the current screen"))
        #expect(summary.details.contains { $0.contains("com.editor") })

        // Render contract: both modes rasterize without crashing.
        #expect(Self.renderPNG(RestoreSummaryBanner(summary: summary, isCompact: false)) != nil)
        #expect(Self.renderPNG(RestoreSummaryBanner(summary: summary, isCompact: true)) != nil)
    }

    private static func renderPNG(_ view: some View) -> Data? {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: 320, height: 140))
        hostingView.layoutSubtreeIfNeeded()
        guard let rep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    // MARK: - T13 — isFullSuccess is strict

    @Test("T13 — one moved-but-not-presented placement breaks full success")
    func movedButNotPresentedBreaksFullSuccess() {
        let summary = RestoreSummary(
            placedCount: 0,
            totalPlacements: 1,
            movedButNotPresented: [RestoreIssue(
                bundleIdentifier: "com.editor", reason: .notPresentedOnCurrentScreen
            )]
        )
        #expect(summary.movedButNotPresentedCount == 1)
        #expect(!summary.isFullSuccess)
    }

    @Test("T13 — a fully presented pass keeps the pre-P0.5 full-success contract")
    func presentedPassKeepsFullSuccess() {
        #expect(RestoreSummary(placedCount: 1, totalPlacements: 1).isFullSuccess)
    }

    // MARK: - T14 — fullscreen exit invalidates the CGWindowID

    @Test("T14 — after a fullscreen exit the observation uses the re-resolved window id")
    func fullscreenExitReResolvesWindowID() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 100, bundle: "com.editor", pid: 1100,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        guard let element = harness.accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        harness.accessibility.mockFullScreenStates[element] = true
        // Chromium-style exit: the app tore the window down and rebuilt it, so
        // the captured id 100 is dead and the live window is id 200.
        harness.checker.reResolvedIDs[window.pid] = 200
        harness.checker.observationResults[200] = .notPresented
        // If the pipeline ever observed the stale id instead, fail loudly.
        harness.checker.observationResults[100] = .presented

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(harness.checker.reResolveWindowIDCallCount == 1)
        #expect(harness.checker.reResolveCalls.first?.pid == window.pid)
        #expect(harness.checker.isOnCurrentScreenCalls == [200])
        #expect(summary.movedButNotPresentedCount == 1)
        #expect(summary.placedCount == 0)
        #expect(!summary.isFullSuccess)
    }

    @Test("T14-fail — an unresolved identity after a fullscreen exit is unverifiable, nothing observed")
    func failedReResolveIsUnverifiableWithoutObservation() async throws {
        let window = WorkspaceTestFixtures.window(
            id: 101, bundle: "com.editor", pid: 1101,
            appKitFrame: CGRect(x: 100, y: 100, width: 500, height: 400)
        )
        let harness = makeHarness(windows: [window])
        defer { cleanup(harness) }
        guard let element = harness.accessibility.mockElementByWindowID[window.id] else {
            Issue.record("missing test AX element")
            return
        }
        harness.accessibility.mockFullScreenStates[element] = true
        // No on-screen entry matches (pid, frame): identity is unrecoverable.
        harness.checker.pidsReResolvingToNil = [window.pid]
        // Must never be consulted — absence of identity is not absence on screen.
        harness.checker.observationResults[101] = .presented

        let summary = try await harness.manager.restore(
            workspace: Workspace(name: "Test", placements: [placement("com.editor")]),
            options: .positionOnly
        )

        #expect(harness.checker.reResolveWindowIDCallCount == 1)
        #expect(harness.checker.isOnCurrentScreenCallCount == 0)
        #expect(harness.mover.moveCallCount == 0)
        #expect(summary.unverifiableCount == 1)
        #expect(summary.unverifiable.first?.reason == .presentationUnverifiable)
        #expect(summary.movedButNotPresentedCount == 0)
    }
}
