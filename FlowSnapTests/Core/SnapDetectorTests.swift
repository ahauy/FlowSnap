import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for SnapDetector zone evaluation, edge thresholds, and multi-monitor adjacency.
///
/// Traces to US-SNAP-006, TC-DRAG-001 through TC-DRAG-004.
struct SnapDetectorTests {

    let detector = SnapDetector(edgeThreshold: 20, cornerRatio: 0.20)
    let layoutEngine = LayoutEngine()

    let primaryDisplay = Display(
        id: 1,
        frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 0, y: 25, width: 1920, height: 1055),
        scaleFactor: 2.0,
        isPrimary: true
    )

    // MARK: - TC-DRAG-001: 4 Halves & Maximize Detection

    @Test func detectLeftHalf() {
        // Cursor at x: 2 (<= 4), y: 540 (middle 60% of height)
        let point = CGPoint(x: 2, y: 540)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .left)
        #expect(result?.displayID == 1)
        #expect(result?.isAdjacentEdge == false)
        #expect(result?.previewFrame == layoutEngine.frame(for: .leftHalf, in: primaryDisplay.visibleFrame))
    }

    @Test func detectRightHalf() {
        // Cursor at x: 1918 (>= 1920 - 4), y: 540
        let point = CGPoint(x: 1918, y: 540)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .right)
        #expect(result?.displayID == 1)
        #expect(result?.isAdjacentEdge == false)
        #expect(result?.previewFrame == layoutEngine.frame(for: .rightHalf, in: primaryDisplay.visibleFrame))
    }

    @Test func detectMaximizeOnTopEdge() {
        // Cursor at top edge y: 1078 (>= 1080 - 4), x: 960 (middle 60% of width)
        let point = CGPoint(x: 960, y: 1078)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .maximize)
        #expect(result?.displayID == 1)
        #expect(result?.isAdjacentEdge == false)
        #expect(result?.previewFrame == layoutEngine.frame(for: .maximize, in: primaryDisplay.visibleFrame))
    }

    @Test func detectBottomHalf() {
        // Cursor at bottom edge y: 2 (<= 4), x: 960
        let point = CGPoint(x: 960, y: 2)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .bottom)
        #expect(result?.displayID == 1)
        #expect(result?.isAdjacentEdge == false)
        #expect(result?.previewFrame == layoutEngine.frame(for: .bottomHalf, in: primaryDisplay.visibleFrame))
    }

    // MARK: - TC-DRAG-002: 4 Corners Zone Detection

    @Test func detectTopLeftCorner() {
        // Left edge within top 20%
        let point = CGPoint(x: 2, y: 1000)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .topLeft)
        #expect(result?.previewFrame == layoutEngine.frame(for: .topLeft, in: primaryDisplay.visibleFrame))
    }

    @Test func detectTopRightCorner() {
        // Right edge within top 20%
        let point = CGPoint(x: 1918, y: 1000)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .topRight)
        #expect(result?.previewFrame == layoutEngine.frame(for: .topRight, in: primaryDisplay.visibleFrame))
    }

    @Test func detectBottomLeftCorner() {
        // Left edge within bottom 20%
        let point = CGPoint(x: 2, y: 100)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .bottomLeft)
        #expect(result?.previewFrame == layoutEngine.frame(for: .bottomLeft, in: primaryDisplay.visibleFrame))
    }

    @Test func detectBottomRightCorner() {
        // Right edge within bottom 20%
        let point = CGPoint(x: 1918, y: 100)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .bottomRight)
        #expect(result?.previewFrame == layoutEngine.frame(for: .bottomRight, in: primaryDisplay.visibleFrame))
    }

    // MARK: - TC-DRAG-003: Multi-Monitor Adjacent Edge Detection

    @Test func detectAdjacentDisplayOnRight() {
        let secondaryDisplay = Display(
            id: 2,
            frame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1080),
            scaleFactor: 2.0,
            isPrimary: false
        )

        // Point at right edge of Primary (x: 1918)
        let point = CGPoint(x: 1918, y: 540)
        let result = detector.detectZone(
            at: point,
            on: primaryDisplay,
            adjacentDisplays: [secondaryDisplay]
        )

        #expect(result != nil)
        #expect(result?.target == .right)
        #expect(result?.isAdjacentEdge == true) // Identified as shared internal border!

        // Point at left edge of Primary (x: 2) -> No monitor on left -> outer boundary
        let outerPoint = CGPoint(x: 2, y: 540)
        let outerResult = detector.detectZone(
            at: outerPoint,
            on: primaryDisplay,
            adjacentDisplays: [secondaryDisplay]
        )

        #expect(outerResult != nil)
        #expect(outerResult?.target == .left)
        #expect(outerResult?.isAdjacentEdge == false)
    }

    // MARK: - TC-TOP-002: Top-Center Zone (Layout Picker Summon) Detection

    @Test func detectTopCenterZoneTrigger() {
        // Point in top-center region (middle 40% of width: x: 960, top edge y: 1078)
        let centerTopPoint = CGPoint(x: 960, y: 1078)
        let result = detector.detectZone(at: centerTopPoint, on: primaryDisplay, adjacentDisplays: [])

        #expect(result != nil)
        #expect(result?.target == .maximize)
        #expect(result?.isTopCenterZone == true)
        #expect(detector.isTopCenterZone(at: centerTopPoint, on: primaryDisplay) == true)

        // Point outside top-center (top edge x: 400 is < 30% of width 1920 which is 576)
        let cornerTopPoint = CGPoint(x: 400, y: 1078)
        let cornerResult = detector.detectZone(at: cornerTopPoint, on: primaryDisplay, adjacentDisplays: [])

        #expect(cornerResult != nil)
        #expect(cornerResult?.isTopCenterZone == false)
        #expect(detector.isTopCenterZone(at: cornerTopPoint, on: primaryDisplay) == false)
    }

    // MARK: - US-SNAP-008: Default Ratio & Window Gap Preview Resolution

    @Test func detectZoneWithSixtyFortyRatio() {
        let leftPoint = CGPoint(x: 2, y: 540)
        let leftResult = detector.detectZone(
            at: leftPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .sixtyForty,
            windowGap: 0
        )
        #expect(leftResult != nil)
        #expect(leftResult?.target == .left)
        #expect(leftResult?.previewFrame == layoutEngine.frame(for: .left60_40, in: primaryDisplay.visibleFrame))
        #expect(leftResult?.previewFrame.width == 1920 * 0.6)

        let rightPoint = CGPoint(x: 1918, y: 540)
        let rightResult = detector.detectZone(
            at: rightPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .sixtyForty,
            windowGap: 0
        )
        #expect(rightResult != nil)
        #expect(rightResult?.target == .right)
        #expect(rightResult?.previewFrame == layoutEngine.frame(for: .right40_60, in: primaryDisplay.visibleFrame))
        #expect(rightResult?.previewFrame.width == 1920 * 0.4)
        #expect(rightResult?.previewFrame.minX == 1920 * 0.6)
    }

    @Test func detectZoneWithSeventyThirtyRatio() {
        let leftPoint = CGPoint(x: 2, y: 540)
        let leftResult = detector.detectZone(
            at: leftPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .seventyThirty,
            windowGap: 0
        )
        #expect(leftResult != nil)
        #expect(leftResult?.previewFrame == layoutEngine.frame(for: .left70_30, in: primaryDisplay.visibleFrame))

        let rightPoint = CGPoint(x: 1918, y: 540)
        let rightResult = detector.detectZone(
            at: rightPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .seventyThirty,
            windowGap: 0
        )
        #expect(rightResult != nil)
        #expect(rightResult?.previewFrame == layoutEngine.frame(for: .rightOneThird, in: primaryDisplay.visibleFrame))
    }

    @Test func detectZoneWithEightyTwentyRatio() {
        let leftPoint = CGPoint(x: 2, y: 540)
        let leftResult = detector.detectZone(
            at: leftPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .eightyTwenty,
            windowGap: 0
        )
        #expect(leftResult != nil)
        #expect(leftResult?.previewFrame == layoutEngine.frame(for: .left80_20, in: primaryDisplay.visibleFrame))

        let rightPoint = CGPoint(x: 1918, y: 540)
        let rightResult = detector.detectZone(
            at: rightPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .eightyTwenty,
            windowGap: 0
        )
        #expect(rightResult != nil)
        #expect(rightResult?.previewFrame == layoutEngine.frame(for: .right20_80, in: primaryDisplay.visibleFrame))
    }

    @Test func detectZoneWithThreeColumnRatio() {
        let leftPoint = CGPoint(x: 2, y: 540)
        let leftResult = detector.detectZone(
            at: leftPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .threeColumn25_50_25,
            windowGap: 0
        )
        #expect(leftResult != nil)
        #expect(leftResult?.previewFrame == layoutEngine.frame(for: .left25, in: primaryDisplay.visibleFrame))

        let rightPoint = CGPoint(x: 1918, y: 540)
        let rightResult = detector.detectZone(
            at: rightPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .threeColumn25_50_25,
            windowGap: 0
        )
        #expect(rightResult != nil)
        #expect(rightResult?.previewFrame == layoutEngine.frame(for: .right25, in: primaryDisplay.visibleFrame))
    }

    @Test func detectZoneWithWindowGapAndDefaultRatio() {
        let leftPoint = CGPoint(x: 2, y: 540)
        let leftResult = detector.detectZone(
            at: leftPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .sixtyForty,
            windowGap: 8
        )
        #expect(leftResult != nil)
        let expectedLeft = layoutEngine.frame(for: .left60_40, in: primaryDisplay.visibleFrame, gap: 8, uniform: true)
        #expect(leftResult?.previewFrame == expectedLeft)

        let rightPoint = CGPoint(x: 1918, y: 540)
        let rightResult = detector.detectZone(
            at: rightPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .sixtyForty,
            windowGap: 8
        )
        #expect(rightResult != nil)
        let expectedRight = layoutEngine.frame(for: .right40_60, in: primaryDisplay.visibleFrame, gap: 8, uniform: true)
        #expect(rightResult?.previewFrame == expectedRight)
    }

    @Test func detectZoneWithWindowGapForNonHalfTargets() {
        // Maximize with gap
        let maxPoint = CGPoint(x: 400, y: 1078)
        let maxResult = detector.detectZone(
            at: maxPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .eightyTwenty,
            windowGap: 8
        )
        #expect(maxResult != nil)
        #expect(maxResult?.target == .maximize)
        let expectedMax = layoutEngine.frame(for: .maximize, in: primaryDisplay.visibleFrame, gap: 8, uniform: true)
        #expect(maxResult?.previewFrame == expectedMax)

        // Corner with gap
        let cornerPoint = CGPoint(x: 2, y: 1000)
        let cornerResult = detector.detectZone(
            at: cornerPoint,
            on: primaryDisplay,
            adjacentDisplays: [],
            defaultRatio: .sixtyForty,
            windowGap: 8
        )
        #expect(cornerResult != nil)
        #expect(cornerResult?.target == .topLeft)
        let expectedTopLeft = layoutEngine.frame(for: .topLeft, in: primaryDisplay.visibleFrame, gap: 8, uniform: true)
        #expect(cornerResult?.previewFrame == expectedTopLeft)
    }
}
