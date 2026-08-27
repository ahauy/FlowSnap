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

    @Test func consecutiveSnapsPreserveInitialPreSnapFrame() async {
        let registry = WindowRegistry()
        let engine = SnapEngine(windowRegistry: registry)

        let initialFrame = CGRect(x: 200, y: 150, width: 800, height: 600)
        let window = ManagedWindow(id: 10, pid: 1001, title: "Test Window", frame: initialFrame)

        // 1. First snap to Left Half
        let leftFrame = await engine.frame(for: .left, window: window, on: display)
        #expect(leftFrame != nil)

        // Verify registry recorded the initial frame
        let storedPreSnap = await registry.preSnapFrame(for: 10)
        #expect(storedPreSnap == initialFrame)

        // 2. Second snap to Right Half (window's current frame has changed to leftFrame)
        var windowAfterLeft = window
        windowAfterLeft.frame = leftFrame!
        let rightFrame = await engine.frame(for: .right, window: windowAfterLeft, on: display)
        #expect(rightFrame != nil)

        // Verify registry STILL retains the original pre-snap frame, NOT leftFrame
        let retainedPreSnap = await registry.preSnapFrame(for: 10)
        #expect(retainedPreSnap == initialFrame)

        // 3. Third snap to Maximize
        var windowAfterRight = windowAfterLeft
        windowAfterRight.frame = rightFrame!
        let maxFrame = await engine.frame(for: .maximize, window: windowAfterRight, on: display)
        #expect(maxFrame != nil)

        // Still retained
        let stillRetained = await registry.preSnapFrame(for: 10)
        #expect(stillRetained == initialFrame)

        // 4. Trigger Restore
        var windowAfterMax = windowAfterRight
        windowAfterMax.frame = maxFrame!
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
        // With minSize 600x500, clamped size is 600x500, anchored to bottom-right (x = 800 - 600 = 200, y = 600 - 500 = 100)
        let brFrame = await engine.calculateFrame(for: .bottomRight, window: window, availableFrame: smallArea)

        #expect(brFrame == CGRect(x: 200, y: 100, width: 600, height: 500))
    }
}
