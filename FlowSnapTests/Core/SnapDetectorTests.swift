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

    // MARK: - TC-DRAG-004: Interior Deadzone / Non-Edge Position

    @Test func interiorDeadzoneReturnsNil() {
        // Point in the center of the display (x: 960, y: 540)
        let point = CGPoint(x: 960, y: 540)
        let result = detector.detectZone(at: point, on: primaryDisplay, adjacentDisplays: [])

        #expect(result == nil)
    }
}
