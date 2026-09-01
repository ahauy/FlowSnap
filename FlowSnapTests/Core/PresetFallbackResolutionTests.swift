import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("Preset Fallback Resolution & Auto-Launch Tests")
struct PresetFallbackResolutionTests {

    @MainActor
    private struct TestContext {
        let mockAX: MockAccessibilityService
        let mockWM: MockWindowManaging
        let mockDM: MockDisplayManager
        let layoutEngine: LayoutEngine
        let launcher: MockApplicationLaunching
        let prefs: PreferencesStore
        let groupManager: WindowGroupManager
    }

    @MainActor
    private func makeContext() -> TestContext {
        let mockAX = MockAccessibilityService(isTrusted: true)
        let mockWM = MockWindowManaging()
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let layoutEngine = LayoutEngine()
        let launcher = MockApplicationLaunching()
        let prefs = PreferencesStore(defaults: UserDefaults(suiteName: "FallbackTests_\(UUID().uuidString)") ?? .standard)
        let groupManager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        return TestContext(
            mockAX: mockAX,
            mockWM: mockWM,
            mockDM: mockDM,
            layoutEngine: layoutEngine,
            launcher: launcher,
            prefs: prefs,
            groupManager: groupManager
        )
    }

    @MainActor
    @Test("Running fallback candidate is chosen when primary is not running")
    func testRunningFallbackCandidateSelected() async throws {
        let context = makeContext()

        // Coding preset prefers: VSCode -> Xcode -> Nova -> TextEdit
        let xcodeWin = ManagedWindow(
            id: 301,
            pid: 3001,
            bundleIdentifier: "com.apple.dt.Xcode",
            title: "Xcode",
            frame: CGRect(x: 0, y: 0, width: 600, height: 600)
        )
        context.mockAX.mockVisibleWindows = [xcodeWin]
        context.launcher.processIdentifiers = ["com.apple.dt.Xcode": 3001]

        let resolver = PresetResolver(
            accessibilityService: context.mockAX,
            windowManager: context.mockWM,
            displayManager: context.mockDM,
            layoutEngine: context.layoutEngine,
            launcher: context.launcher,
            preferencesStore: context.prefs,
            windowGroupManager: context.groupManager
        )

        let summary = try await resolver.restore(preset: BuiltinPresetFactory.codingPreset, on: nil)

        #expect(context.mockWM.movedWindows.contains { $0.window.id == 301 })
        #expect(!context.launcher.launchAttempts.contains("com.microsoft.VSCode"))
        #expect(summary.placedCount == 1)
    }

    @MainActor
    @Test("Installed secondary candidate is launched when primary is uninstalled")
    func testInstalledSecondaryCandidateLaunched() async throws {
        let context = makeContext()

        context.launcher.installedBundleIDs = ["com.apple.dt.Xcode"]
        context.launcher.pidsAssignedOnLaunch = ["com.apple.dt.Xcode": 3002]

        let xcodeWin = ManagedWindow(
            id: 302,
            pid: 3002,
            bundleIdentifier: "com.apple.dt.Xcode",
            title: "Xcode",
            frame: CGRect(x: 0, y: 0, width: 700, height: 700)
        )
        context.mockAX.visibleWindowsProvider = {
            context.launcher.processIdentifiers["com.apple.dt.Xcode"] == 3002 ? [xcodeWin] : []
        }

        let resolver = PresetResolver(
            accessibilityService: context.mockAX,
            windowManager: context.mockWM,
            displayManager: context.mockDM,
            layoutEngine: context.layoutEngine,
            launcher: context.launcher,
            preferencesStore: context.prefs,
            windowGroupManager: context.groupManager
        )

        let summary = try await resolver.restore(preset: BuiltinPresetFactory.codingPreset, on: nil)

        #expect(context.launcher.launchAttempts.contains("com.apple.dt.Xcode"))
        #expect(context.mockWM.movedWindows.contains { $0.window.id == 302 })
        #expect(summary.placedCount >= 1)
    }

    @MainActor
    @Test("Uninstalled candidates are skipped with reason notInstalled")
    func testUninstalledCandidatesSkippedGracefully() async throws {
        let context = makeContext()

        context.launcher.installedBundleIDs = []
        context.mockAX.mockVisibleWindows = []

        let resolver = PresetResolver(
            accessibilityService: context.mockAX,
            windowManager: context.mockWM,
            displayManager: context.mockDM,
            layoutEngine: context.layoutEngine,
            launcher: context.launcher,
            preferencesStore: context.prefs,
            windowGroupManager: context.groupManager
        )

        let summary = try await resolver.restore(preset: BuiltinPresetFactory.designPreset, on: nil)

        #expect(summary.placedCount == 0)
        #expect(summary.totalPlacements == 2)
        #expect(summary.skipped.count == 2)
        #expect(summary.skipped.allSatisfy { $0.reason == .notInstalled })
    }

    @MainActor
    @Test("Hanging launch candidate times out and skips with launchTimeout")
    func testHangingLaunchCandidateTimesOut() async throws {
        let context = makeContext()

        context.launcher.installedBundleIDs = ["com.figma.Desktop"]
        context.launcher.hangingBundleIDs = ["com.figma.Desktop"]
        context.launcher.pidsAssignedOnLaunch = ["com.figma.Desktop": 4001]

        let resolver = PresetResolver(
            accessibilityService: context.mockAX,
            windowManager: context.mockWM,
            displayManager: context.mockDM,
            layoutEngine: context.layoutEngine,
            launcher: context.launcher,
            preferencesStore: context.prefs,
            windowGroupManager: context.groupManager,
            launchTimeout: 0.1
        )

        let summary = try await resolver.restore(preset: BuiltinPresetFactory.designPreset, on: nil)

        #expect(summary.skipped.contains { $0.bundleIdentifier == "com.figma.Desktop" && $0.reason == .launchTimeout })
    }
}
