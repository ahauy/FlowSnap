import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("PresetResolver Layout & Resolution Tests")
struct PresetResolverTests {

    @MainActor
    private struct TestContext {
        let mockAX: MockAccessibilityService
        let mockWM: MockWindowManaging
        let mockDM: MockDisplayManager
        let layoutEngine: LayoutEngine
        let launcher: MockApplicationLaunching
        let prefs: PreferencesStore
        let groupManager: WindowGroupManager

        func makeResolver() -> PresetResolver {
            PresetResolver(
                accessibilityService: mockAX,
                windowManager: mockWM,
                displayManager: mockDM,
                layoutEngine: layoutEngine,
                launcher: launcher,
                preferencesStore: prefs,
                windowGroupManager: groupManager
            )
        }
    }

    @MainActor
    private func makeContext(
        isTrusted: Bool = true,
        display: Display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 875),
            scaleFactor: 2.0,
            isPrimary: true
        )
    ) -> TestContext {
        let mockAX = MockAccessibilityService(isTrusted: isTrusted)
        let mockWM = MockWindowManaging()
        let mockDM = MockDisplayManager(displays: [display])
        let layoutEngine = LayoutEngine()
        let launcher = MockApplicationLaunching()
        let prefs = PreferencesStore(defaults: UserDefaults(suiteName: "PresetResolver_\(UUID().uuidString)") ?? .standard)
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
    @Test("Accessibility denied throws PresetError.accessibilityDenied")
    func testAccessibilityDenied() async {
        let context = makeContext(isTrusted: false)
        let resolver = context.makeResolver()

        do {
            _ = try await resolver.restore(preset: BuiltinPresetFactory.codingPreset, on: nil)
            Issue.record("Expected PresetError.accessibilityDenied")
        } catch let error as PresetError {
            #expect(error == .accessibilityDenied)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @MainActor
    @Test("Coding preset places 3 running apps correctly in 60/25/15 layout")
    func testCodingPresetPlacement() async throws {
        let context = makeContext()

        let frame = CGRect(x: 10, y: 10, width: 400, height: 400)
        let win1 = ManagedWindow(id: 101, pid: 1001, bundleIdentifier: "com.microsoft.VSCode", title: "VSCode", frame: frame)
        let win2 = ManagedWindow(id: 102, pid: 1002, bundleIdentifier: "com.google.Chrome", title: "Chrome", frame: frame)
        let win3 = ManagedWindow(id: 103, pid: 1003, bundleIdentifier: "com.apple.Terminal", title: "Terminal", frame: frame)

        context.mockAX.mockVisibleWindows = [win1, win2, win3]
        context.launcher.processIdentifiers = [
            "com.microsoft.VSCode": 1001,
            "com.google.Chrome": 1002,
            "com.apple.Terminal": 1003
        ]

        let summary = try await context.makeResolver().restore(preset: BuiltinPresetFactory.codingPreset, on: nil)

        #expect(summary.placedCount == 3)
        #expect(summary.totalPlacements == 3)
        #expect(summary.skipped.isEmpty)
        #expect(context.mockWM.moveCallCount == 3)

        #expect(context.groupManager.activeGroups.count == 1)
        #expect(context.groupManager.activeGroups.first?.name == "Coding")
        #expect(context.groupManager.activeGroups.first?.windowIDs == [101, 102, 103])
    }

    @MainActor
    @Test("Writing preset applies 70/30 layout on Ultrawide 3440x1440 display")
    func testWritingPresetOnUltrawide() async throws {
        let ultrawide = Display(
            id: 2,
            frame: CGRect(x: 0, y: 0, width: 3440, height: 1440),
            visibleFrame: CGRect(x: 0, y: 0, width: 3440, height: 1400),
            scaleFactor: 1.0,
            isPrimary: true
        )
        let context = makeContext(display: ultrawide)

        let frame = CGRect(x: 50, y: 50, width: 500, height: 500)
        let pagesWin = ManagedWindow(id: 201, pid: 2001, bundleIdentifier: "com.apple.Pages", title: "Pages", frame: frame)
        let safariWin = ManagedWindow(id: 202, pid: 2002, bundleIdentifier: "com.apple.Safari", title: "Safari", frame: frame)

        context.mockAX.mockVisibleWindows = [pagesWin, safariWin]
        context.launcher.processIdentifiers = ["com.apple.Pages": 2001, "com.apple.Safari": 2002]

        let summary = try await context.makeResolver().restore(preset: BuiltinPresetFactory.writingPreset, on: ultrawide)

        #expect(summary.placedCount == 2)
        #expect(summary.totalPlacements == 2)
        #expect(context.mockWM.movedWindows.count == 2)

        let pagesMoved = context.mockWM.movedWindows.first(where: { $0.window.id == 201 })
        let safariMoved = context.mockWM.movedWindows.first(where: { $0.window.id == 202 })

        #expect(pagesMoved != nil && safariMoved != nil)
        if let pagesMoved, let safariMoved {
            #expect(pagesMoved.frame.width > 2300 && pagesMoved.frame.width < 2500)
            #expect(safariMoved.frame.width > 950 && safariMoved.frame.width < 1100)
        }
    }
}
