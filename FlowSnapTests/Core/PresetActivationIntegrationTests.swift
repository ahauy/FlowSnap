import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("Preset Activation Integration Tests")
struct PresetActivationIntegrationTests {

    @MainActor
    private struct TestContext {
        let dispatcher: CommandDispatcher
        let mockAX: MockAccessibilityService
        let mockWM: MockWindowManaging
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
        let layout = LayoutEngine()
        let prefs = PreferencesStore(defaults: UserDefaults(suiteName: "IntegrationTests_\(UUID().uuidString)") ?? .standard)
        let groupManager = WindowGroupManager(accessibilityService: mockAX, windowManager: mockWM)

        let resolver = PresetResolver(
            accessibilityService: mockAX,
            windowManager: mockWM,
            displayManager: mockDM,
            layoutEngine: layout,
            launcher: MockApplicationLaunching(),
            preferencesStore: prefs,
            windowGroupManager: groupManager
        )

        let snapEngine = SnapEngine(layoutEngine: layout, windowRegistry: WindowRegistry(), preferencesStore: prefs)
        let dispatcher = CommandDispatcher(windowManager: mockWM, snapEngine: snapEngine, displayManager: mockDM, presetResolver: resolver)

        return TestContext(dispatcher: dispatcher, mockAX: mockAX, mockWM: mockWM, groupManager: groupManager)
    }

    @MainActor
    @Test("Dispatching .restorePreset routes through PresetResolver and sets lastRestoreSummary")
    func testDispatchRestorePreset() async throws {
        let context = makeContext()

        let vscodeWin = ManagedWindow(
            id: 501,
            pid: 5001,
            bundleIdentifier: "com.microsoft.VSCode",
            title: "VSCode",
            frame: CGRect(x: 10, y: 10, width: 300, height: 300)
        )
        let chromeWin = ManagedWindow(
            id: 502,
            pid: 5002,
            bundleIdentifier: "com.google.Chrome",
            title: "Chrome",
            frame: CGRect(x: 20, y: 20, width: 300, height: 300)
        )

        context.mockAX.mockVisibleWindows = [vscodeWin, chromeWin]

        try await context.dispatcher.dispatch(.restorePreset("builtin.coding"))

        #expect(context.dispatcher.lastExecutedCommand == .restorePreset("builtin.coding"))
        #expect(context.dispatcher.lastRestoreSummary != nil)
        #expect(context.dispatcher.lastRestoreSummary?.placedCount == 2)
        #expect(context.mockWM.movedWindows.count == 2)
        #expect(context.groupManager.activeGroups.count == 1)
    }

    @MainActor
    @Test("Debouncing rapid consecutive preset dispatches executes latest wins")
    func testRapidPresetDebouncing() async throws {
        let context = makeContext()

        let vscodeWin = ManagedWindow(
            id: 501,
            pid: 5001,
            bundleIdentifier: "com.microsoft.VSCode",
            title: "VSCode",
            frame: CGRect(x: 10, y: 10, width: 300, height: 300)
        )
        let safariWin = ManagedWindow(
            id: 503,
            pid: 5003,
            bundleIdentifier: "com.apple.Safari",
            title: "Safari",
            frame: CGRect(x: 30, y: 30, width: 300, height: 300)
        )

        context.mockAX.mockVisibleWindows = [vscodeWin, safariWin]

        // Fire coding preset and immediately fire research preset
        async let firstTask: Void = context.dispatcher.dispatch(.restorePreset("builtin.coding"))
        async let secondTask: Void = context.dispatcher.dispatch(.restorePreset("builtin.research"))

        _ = try await (firstTask, secondTask)

        #expect(context.dispatcher.lastExecutedCommand == .restorePreset("builtin.research"))
    }
}
