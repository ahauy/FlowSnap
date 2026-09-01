import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests validating stateful coordination, pre-snap preservation, and restore lifecycle in SnapEngine.
///
/// Traces to US-SNAP-002, TC-006, TC-007.
struct SnapEngineTests {

    let display = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
        scaleFactor: 2.0
    )

    @Test func consecutiveSnapsPreserveInitialPreSnapFrame() async throws {
        let registry = WindowRegistry()
        let engine = SnapEngine(windowRegistry: registry)

        let initialFrame = CGRect(x: 200, y: 150, width: 800, height: 600)
        let window = ManagedWindow(id: 10, pid: 1001, title: "Test Window", frame: initialFrame)

        // 1. First snap to Left Half
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        let unwrappedLeft = try #require(leftFrame)

        // Verify registry recorded the initial frame
        let storedPreSnap = await registry.preSnapFrame(for: 10)
        #expect(storedPreSnap == initialFrame)

        // 2. Second snap to Right Half (window's current frame has changed to leftFrame)
        var windowAfterLeft = window
        windowAfterLeft.frame = unwrappedLeft
        let rightFrame = await engine.frame(for: .right, window: windowAfterLeft, on: display)
        let unwrappedRight = try #require(rightFrame)

        // Verify registry STILL retains the original pre-snap frame, NOT leftFrame
        let retainedPreSnap = await registry.preSnapFrame(for: 10)
        #expect(retainedPreSnap == initialFrame)

        // 3. Third snap to Maximize
        var windowAfterRight = windowAfterLeft
        windowAfterRight.frame = unwrappedRight
        let maxFrame = await engine.frame(for: .maximize, window: windowAfterRight, on: display)
        let unwrappedMax = try #require(maxFrame)

        // Still retained
        let stillRetained = await registry.preSnapFrame(for: 10)
        #expect(stillRetained == initialFrame)

        // 4. Trigger Restore
        var windowAfterMax = windowAfterRight
        windowAfterMax.frame = unwrappedMax
        let restoredFrame = await engine.frame(for: .restore, window: windowAfterMax, on: display)

        #expect(restoredFrame == initialFrame)

        // Pre-snap frame is consumed and cleared
        let afterRestore = await registry.preSnapFrame(for: 10)
        #expect(afterRestore == nil)
    }

    @Test func restoreWithoutPriorSnapIsSafeNoOp() async {
        let registry = WindowRegistry()
        let engine = SnapEngine(windowRegistry: registry)

        let window = ManagedWindow(id: 99, pid: 1002, title: "Freeform Window", frame: CGRect(x: 50, y: 50, width: 500, height: 400))

        let restored = await engine.frame(for: .restore, window: window, on: display)

        #expect(restored == nil)
    }

    @Test func minSizeConstraintAnchorsToOuterEdges() async {
        let registry = WindowRegistry()
        let engine = SnapEngine(windowRegistry: registry)

        // Window with minSize 600x500
        let minSize = CGSize(width: 600, height: 500)
        let window = ManagedWindow(
            id: 20,
            pid: 1003,
            title: "Min Size Window",
            frame: CGRect(x: 100, y: 100, width: 600, height: 500),
            minSize: minSize
        )

        // Available area is 800x600 (quarter would normally be 400x300)
        let smallArea = CGRect(x: 0, y: 0, width: 800, height: 600)

        // Snap to Bottom-Right quarter: normal quarter is (400, 300, 400, 300)
        // With minSize 600x500, clamped size is 600x500, anchored to bottom-right (x = 800 - 600 = 200, y = 0)
        let brFrame = await engine.calculateFrame(for: .bottomRight, window: window, availableFrame: smallArea)
        #expect(brFrame == CGRect(x: 200, y: 0, width: 600, height: 500))

        // Right-anchoring must work across all right-aligned zones (F-04)
        let rightZones: [LayoutZone] = [
            .rightHalf, .topRight, .bottomRight, .rightOneThird,
            .rightThird, .right40_60, .right20_80, .right25
        ]
        for zone in rightZones {
            let frame = await engine.calculateFrame(for: .zone(zone), window: window, availableFrame: smallArea)
            #expect(frame != nil)
            #expect(frame?.maxX == smallArea.maxX)
            #expect(frame?.width == 600)
        }
    }
}

/// US-SNAP-008: SnapEngine gap fallback (contracts.md §5.2).
///
/// Priority: explicit `gap` > `preferencesStore.windowGap` > `0`.
@MainActor
extension SnapEngineTests {

    @Test func gapFallsBackToPreferencesStoreWhenNotProvided() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(8)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 99, pid: 2001, title: "Gap Window", frame: .zero)

        // No explicit gap → resolves to store.windowGap (8), uniform gap insets outer edges (F-03).
        let leftFrame = await engine.frame(for: .left, window: window, on: display)

        #expect(leftFrame != nil)
        // Uniform 2-col: effective width = 1440 - 3*8 = 1416, left = 708, minX = 8
        #expect(leftFrame?.minX == 8)
        #expect(leftFrame?.width == 708)

        let rightFrame = await engine.frame(for: .right, window: window, on: display)
        #expect(rightFrame != nil)
        #expect(rightFrame?.maxX == display.visibleFrame.maxX - 8)
        #expect(rightFrame?.width == 708)
    }

    @Test func explicitGapOverridesPreferencesStore() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-explicit-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(8)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 100, pid: 2002, title: "Explicit Gap Window", frame: .zero)

        // Explicit gap 0 wins over store's 8 → full width halves without insets.
        let leftFrame = await engine.frame(for: .left, window: window, on: display, gap: 0)

        #expect(leftFrame != nil)
        #expect(leftFrame?.minX == 0)
        #expect(leftFrame?.width == 720) // 1440 / 2
    }

    // MARK: - US-SNAP-008: Default Ratio Resolution in SnapEngine

    @Test func defaultRatioSixtyFortyResolvesLeftAndRightHalves() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-6040-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(0)
        store.setDefaultRatio(.sixtyForty)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 101, pid: 3001, title: "60/40 Window", frame: .zero)

        // Left Half should resolve to .left60_40 (60% width = 1440 * 0.6 = 864)
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        #expect(leftFrame != nil)
        #expect(leftFrame == CGRect(x: 0, y: 25, width: 864, height: 875))

        // Right Half should resolve to .right40_60 (40% width = 1440 * 0.4 = 576, minX = 864)
        let rightFrame = await engine.frame(for: .right, window: window, on: display)
        #expect(rightFrame != nil)
        #expect(rightFrame == CGRect(x: 864, y: 25, width: 576, height: 875))
    }

    @Test func defaultRatioSeventyThirtyResolvesLeftAndRightHalves() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-7030-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(0)
        store.setDefaultRatio(.seventyThirty)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 102, pid: 3002, title: "70/30 Window", frame: .zero)

        // Left Half -> .left70_30
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        #expect(leftFrame != nil)
        #expect(leftFrame == LayoutEngine().frame(for: .left70_30, in: display.visibleFrame))

        // Right Half -> .rightOneThird
        let rightFrame = await engine.frame(for: .right, window: window, on: display)
        #expect(rightFrame != nil)
        #expect(rightFrame == LayoutEngine().frame(for: .rightOneThird, in: display.visibleFrame))
    }

    @Test func defaultRatioEightyTwentyResolvesLeftAndRightHalves() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-8020-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(0)
        store.setDefaultRatio(.eightyTwenty)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 103, pid: 3003, title: "80/20 Window", frame: .zero)

        // Left Half -> .left80_20 (80% width = 1440 * 0.8 = 1152)
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        #expect(leftFrame != nil)
        #expect(leftFrame == CGRect(x: 0, y: 25, width: 1152, height: 875))

        // Right Half -> .right20_80 (20% width = 1440 * 0.2 = 288, minX = 1152)
        let rightFrame = await engine.frame(for: .right, window: window, on: display)
        #expect(rightFrame != nil)
        #expect(rightFrame == CGRect(x: 1152, y: 25, width: 288, height: 875))
    }

    @Test func defaultRatioThreeColumnResolvesLeftAndRightHalves() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-3col-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(0)
        store.setDefaultRatio(.threeColumn25_50_25)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 104, pid: 3004, title: "3Col Window", frame: .zero)

        // Left Half -> .left25 (25% width = 1440 * 0.25 = 360)
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        #expect(leftFrame != nil)
        #expect(leftFrame == CGRect(x: 0, y: 25, width: 360, height: 875))

        // Right Half -> .right25 (25% width = 1440 * 0.25 = 360, minX = 1080)
        let rightFrame = await engine.frame(for: .right, window: window, on: display)
        #expect(rightFrame != nil)
        #expect(rightFrame == CGRect(x: 1080, y: 25, width: 360, height: 875))
    }

    @Test func defaultRatioDoesNotAlterNonHalfSnapTargets() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-nonhalf-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(0)
        store.setDefaultRatio(.eightyTwenty)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 105, pid: 3005, title: "NonHalf Window", frame: .zero)

        // Maximize remains full screen
        let maxFrame = await engine.frame(for: .maximize, window: window, on: display)
        #expect(maxFrame == display.visibleFrame)

        // Top-Left quarter remains top-left quarter
        let topLeftFrame = await engine.frame(for: .topLeft, window: window, on: display)
        #expect(topLeftFrame == LayoutEngine().frame(for: .topLeft, in: display.visibleFrame))

        // Bottom Half remains bottom half
        let bottomFrame = await engine.frame(for: .bottomHalf, window: window, on: display)
        #expect(bottomFrame == LayoutEngine().frame(for: .bottomHalf, in: display.visibleFrame))

        // Explicit .left60_40 target is not overridden by defaultRatio .eightyTwenty
        let explicit60Frame = await engine.frame(for: .zone(.left60_40), window: window, on: display)
        #expect(explicit60Frame == LayoutEngine().frame(for: .left60_40, in: display.visibleFrame))

        // Explicit .left50_50 / .right50_50 from Layout Picker are NOT overridden by defaultRatio .eightyTwenty
        let fiftyFiftyLeftFrame = await engine.frame(for: .left50_50, window: window, on: display)
        #expect(fiftyFiftyLeftFrame == LayoutEngine().frame(for: .left50_50, in: display.visibleFrame))
        #expect(fiftyFiftyLeftFrame == CGRect(x: 0, y: 25, width: 720, height: 875))

        let fiftyFiftyRightFrame = await engine.frame(for: .right50_50, window: window, on: display)
        #expect(fiftyFiftyRightFrame == LayoutEngine().frame(for: .right50_50, in: display.visibleFrame))
        #expect(fiftyFiftyRightFrame == CGRect(x: 720, y: 25, width: 720, height: 875))
    }

    @Test func defaultRatioCombinedWithWindowGap() async {
        let defaults = UserDefaults(suiteName: "test-snapengine-ratio-gap-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(8)
        store.setDefaultRatio(.sixtyForty)

        let engine = SnapEngine(
            windowRegistry: WindowRegistry(),
            preferencesStore: store
        )

        let window = ManagedWindow(id: 106, pid: 3006, title: "Ratio+Gap Window", frame: .zero)

        // LayoutEngine math for .left60_40 with gap=8, uniform=true:
        // effectiveWidth = 1440 - 24 = 1416.
        // left60 = floor(1416 * 0.6) = 849. minX = 8.
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        #expect(leftFrame != nil)
        #expect(leftFrame?.minX == 8)
        #expect(leftFrame?.width == 849)

        // right40 = 1416 - 849 = 567. minX = 8 + 849 + 8 = 865. maxX = 865 + 567 = 1432 = 1440 - 8.
        let rightFrame = await engine.frame(for: .right, window: window, on: display)
        #expect(rightFrame != nil)
        #expect(rightFrame?.minX == 865)
        #expect(rightFrame?.width == 567)
        #expect(rightFrame?.maxX == display.visibleFrame.maxX - 8)
    }
}
