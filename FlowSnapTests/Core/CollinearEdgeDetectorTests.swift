import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("CollinearEdgeDetector Tests")
struct CollinearEdgeDetectorTests {

    let detector = CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150)
    let displayBounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

    @Test("Detects vertical divider in standard 2-window split")
    func detectVerticalDividerTwoWindows() {
        let leftWindow = ManagedWindow(
            id: 101,
            pid: 1,
            title: "Left",
            frame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        let rightWindow = ManagedWindow(
            id: 102,
            pid: 2,
            title: "Right",
            frame: CGRect(x: 720, y: 0, width: 720, height: 900)
        )

        let dividers = detector.detectDividers(
            in: [leftWindow, rightWindow],
            containerFrame: displayBounds,
            gap: 0,
            tolerance: 6.0
        )

        #expect(dividers.count == 1)
        let divider = dividers.first!
        #expect(divider.orientation == .vertical)
        #expect(divider.coordinate == 720)
        #expect(divider.span == (0...900))
        #expect(divider.leadingWindowIDs == [101])
        #expect(divider.trailingWindowIDs == [102])
        #expect(divider.minCoordinate == 200)
        #expect(divider.maxCoordinate == 1240)
    }

    @Test("Detects horizontal divider in standard 2-window stacked split")
    func detectHorizontalDividerTwoWindows() {
        let bottomWindow = ManagedWindow(
            id: 201,
            pid: 1,
            title: "Bottom",
            frame: CGRect(x: 0, y: 0, width: 1440, height: 450)
        )
        let topWindow = ManagedWindow(
            id: 202,
            pid: 2,
            title: "Top",
            frame: CGRect(x: 0, y: 450, width: 1440, height: 450)
        )

        let dividers = detector.detectDividers(
            in: [bottomWindow, topWindow],
            containerFrame: displayBounds,
            gap: 0,
            tolerance: 6.0
        )

        #expect(dividers.count == 1)
        let divider = dividers.first!
        #expect(divider.orientation == .horizontal)
        #expect(divider.coordinate == 450)
        #expect(divider.span == (0...1440))
        #expect(divider.leadingWindowIDs == [201])
        #expect(divider.trailingWindowIDs == [202])
        #expect(divider.minCoordinate == 150)
        #expect(divider.maxCoordinate == 750)
    }

    @Test("Detects T-junction 3-window collinear vertical and horizontal dividers")
    func detectTJunctionThreeWindows() {
        // Window 1: Left column (full height)
        let w1 = ManagedWindow(
            id: 301,
            pid: 1,
            title: "VSCode",
            frame: CGRect(x: 0, y: 0, width: 720, height: 900)
        )
        // Window 2: Right top
        let w2 = ManagedWindow(
            id: 302,
            pid: 2,
            title: "Chrome",
            frame: CGRect(x: 720, y: 450, width: 720, height: 450)
        )
        // Window 3: Right bottom
        let w3 = ManagedWindow(
            id: 303,
            pid: 3,
            title: "Terminal",
            frame: CGRect(x: 720, y: 0, width: 720, height: 450)
        )

        let dividers = detector.detectDividers(
            in: [w1, w2, w3],
            containerFrame: displayBounds,
            gap: 0,
            tolerance: 6.0
        )

        #expect(dividers.count == 2)

        // 1. Full height vertical divider at X=720
        let vDivider = dividers.first { $0.orientation == .vertical }
        #expect(vDivider != nil)
        #expect(vDivider?.coordinate == 720)
        #expect(vDivider?.span == (0...900))
        #expect(vDivider?.leadingWindowIDs == [301])
        #expect(Set(vDivider?.trailingWindowIDs ?? []) == Set([302, 303]))

        // 2. Right-only horizontal divider at Y=450
        let hDivider = dividers.first { $0.orientation == .horizontal }
        #expect(hDivider != nil)
        #expect(hDivider?.coordinate == 450)
        #expect(hDivider?.span == (720...1440))
        #expect(hDivider?.leadingWindowIDs == [303])
        #expect(hDivider?.trailingWindowIDs == [302])
    }

    @Test("Detects 4-window 2x2 cross junction dividers")
    func detectFourWindowCrossJunction() {
        let bl = ManagedWindow(id: 1, pid: 1, title: "BL", frame: CGRect(x: 0, y: 0, width: 720, height: 450))
        let tl = ManagedWindow(id: 2, pid: 2, title: "TL", frame: CGRect(x: 0, y: 450, width: 720, height: 450))
        let br = ManagedWindow(id: 3, pid: 3, title: "BR", frame: CGRect(x: 720, y: 0, width: 720, height: 450))
        let tr = ManagedWindow(id: 4, pid: 4, title: "TR", frame: CGRect(x: 720, y: 450, width: 720, height: 450))

        let dividers = detector.detectDividers(
            in: [bl, tl, br, tr],
            containerFrame: displayBounds,
            gap: 0,
            tolerance: 6.0
        )

        #expect(dividers.count == 2)
        let vDivider = dividers.first { $0.orientation == .vertical }
        #expect(vDivider?.coordinate == 720)
        #expect(vDivider?.span == (0...900))
        #expect(Set(vDivider?.leadingWindowIDs ?? []) == Set([1, 2]))
        #expect(Set(vDivider?.trailingWindowIDs ?? []) == Set([3, 4]))

        let hDivider = dividers.first { $0.orientation == .horizontal }
        #expect(hDivider?.coordinate == 450)
        #expect(hDivider?.span == (0...1440))
        #expect(Set(hDivider?.leadingWindowIDs ?? []) == Set([1, 3]))
        #expect(Set(hDivider?.trailingWindowIDs ?? []) == Set([2, 4]))
    }

    @Test("Hit test divider with tolerance margin")
    func hitTestDividerWithTolerance() {
        let left = ManagedWindow(id: 1, pid: 1, title: "L", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let right = ManagedWindow(id: 2, pid: 2, title: "R", frame: CGRect(x: 720, y: 0, width: 720, height: 900))

        let dividers = detector.detectDividers(in: [left, right], containerFrame: displayBounds)

        // Within 6pt of X=720
        #expect(detector.hitTestDivider(at: CGPoint(x: 720, y: 400), in: dividers) != nil)
        #expect(detector.hitTestDivider(at: CGPoint(x: 724, y: 400), in: dividers) != nil)
        #expect(detector.hitTestDivider(at: CGPoint(x: 716, y: 400), in: dividers) != nil)

        // Outside tolerance
        #expect(detector.hitTestDivider(at: CGPoint(x: 730, y: 400), in: dividers) == nil)
        #expect(detector.hitTestDivider(at: CGPoint(x: 700, y: 400), in: dividers) == nil)

        // Outside Y span
        #expect(detector.hitTestDivider(at: CGPoint(x: 720, y: 950), in: dividers) == nil)
    }

    @Test("Compute resized frames for 3-window T-junction simultaneously adjusts all windows")
    func computeResizedFramesTJunction() {
        let w1 = ManagedWindow(id: 301, pid: 1, title: "VSCode", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 302, pid: 2, title: "Chrome", frame: CGRect(x: 720, y: 450, width: 720, height: 450))
        let w3 = ManagedWindow(id: 303, pid: 3, title: "Terminal", frame: CGRect(x: 720, y: 0, width: 720, height: 450))

        let dividers = detector.detectDividers(in: [w1, w2, w3], containerFrame: displayBounds)
        let vDivider = dividers.first { $0.orientation == .vertical }!

        // Drag vertical divider to X=820 (+100px)
        let resized = detector.computeResizedFrames(
            for: vDivider,
            targetCoordinate: 820,
            windows: [w1, w2, w3],
            containerFrame: displayBounds
        )

        #expect(resized[301] == CGRect(x: 0, y: 0, width: 820, height: 900))
        #expect(resized[302] == CGRect(x: 820, y: 450, width: 620, height: 450))
        #expect(resized[303] == CGRect(x: 820, y: 0, width: 620, height: 450))
    }

    @Test("Clamping to minSize prevents window collapse")
    func minSizeClampingPreventsCollapse() {
        let left = ManagedWindow(id: 1, pid: 1, title: "L", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let right = ManagedWindow(
            id: 2,
            pid: 2,
            title: "R",
            frame: CGRect(x: 720, y: 0, width: 720, height: 900),
            minSize: CGSize(width: 300, height: 200)
        )

        let dividers = detector.detectDividers(in: [left, right], containerFrame: displayBounds)
        let vDivider = dividers.first!

        // Attempt to drag divider all the way to X=1400 (which would give right window width of 40)
        let resized = detector.computeResizedFrames(
            for: vDivider,
            targetCoordinate: 1400,
            windows: [left, right],
            containerFrame: displayBounds
        )

        // Clamped at maxX (1440) - minSize (300) = 1140
        #expect(resized[1]?.width == 1140)
        #expect(resized[2]?.origin.x == 1140)
        #expect(resized[2]?.width == 300)

        // Attempt to drag divider all the way to X=50 (which would give left window width < minWidth)
        let resizedLeft = detector.computeResizedFrames(
            for: vDivider,
            targetCoordinate: 50,
            windows: [left, right],
            containerFrame: displayBounds
        )

        // Clamped at minX (0) + defaultMinWidth (200) = 200
        #expect(resizedLeft[1]?.width == 200)
        #expect(resizedLeft[2]?.origin.x == 200)
        #expect(resizedLeft[2]?.width == 1240)
        // Verify left window maxX meets right window minX with zero overlap
        #expect(resizedLeft[1]?.maxX == resizedLeft[2]?.minX)
    }

    @Test("Hard wall screen boundaries enforce strict minX and maxX walls with minWidth 300px")
    func hardWallScreenBoundariesWithZeroDrift() {
        let hardWallDetector = CollinearEdgeDetector(defaultMinWidth: 300, defaultMinHeight: 200)
        let display = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let left = ManagedWindow(id: 1, pid: 1, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let right = ManagedWindow(id: 2, pid: 2, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))

        let dividers = hardWallDetector.detectDividers(in: [left, right], containerFrame: display, gap: 16.0)
        #expect(dividers.count == 1)
        let divider = dividers.first!

        // 1. Extreme drag left past minimum width (e.g. target X = 50)
        let clampedMin = hardWallDetector.computeResizedFrames(
            for: divider,
            targetCoordinate: 50,
            windows: [left, right],
            containerFrame: display,
            gap: 16.0
        )
        // Leading window minWidth is 300; gap is 16; divider locked at 308 (leadingEdge = 300, trailingEdge = 316)
        let leftFrame = clampedMin[1]!
        let rightFrame = clampedMin[2]!
        #expect(leftFrame.origin.x == 0) // Strictly locked to container minX
        #expect(leftFrame.width == 300) // Hard-locked at minWidth 300px
        #expect(rightFrame.origin.x == 316) // trailingEdge = 308 + 8 = 316
        #expect(rightFrame.maxX == 1440) // Strictly locked to container maxX
        #expect(rightFrame.width == 1124) // 1440 - 316 = 1124
        #expect(rightFrame.origin.x - leftFrame.maxX == 16.0) // Gap preserved

        // 2. Extreme drag right past minimum width (e.g. target X = 1400)
        let clampedMax = hardWallDetector.computeResizedFrames(
            for: divider,
            targetCoordinate: 1400,
            windows: [left, right],
            containerFrame: display,
            gap: 16.0
        )
        // Trailing window minWidth is 300; divider locked at 1132 (leadingEdge = 1124, trailingEdge = 1140)
        let leftFrameMax = clampedMax[1]!
        let rightFrameMax = clampedMax[2]!
        #expect(leftFrameMax.origin.x == 0) // Strictly locked to container minX
        #expect(leftFrameMax.width == 1124) // 1124 - 0 = 1124
        #expect(rightFrameMax.origin.x == 1140) // trailingEdge = 1132 + 8 = 1140
        #expect(rightFrameMax.maxX == 1440) // Strictly locked to container maxX
        #expect(rightFrameMax.width == 300) // Hard-locked at minWidth 300px
        #expect(rightFrameMax.origin.x - leftFrameMax.maxX == 16.0) // Gap preserved
    }
}
