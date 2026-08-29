import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for LayoutEngine frame calculations across standard screen resolutions.
///
/// Traces to US-SNAP-002, TC-001, TC-002, TC-004, TC-005.
struct LayoutEngineTests {

    let engine = LayoutEngine()

    // MARK: - TC-001: 50/50 Split on Even Resolutions

    @Test func fiftyFiftySplit_1440x900() {
        let bounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

        let left = engine.frame(for: .leftHalf, in: bounds)
        let right = engine.frame(for: .rightHalf, in: bounds)
        let top = engine.frame(for: .topHalf, in: bounds)
        let bottom = engine.frame(for: .bottomHalf, in: bounds)

        #expect(left == CGRect(x: 0, y: 0, width: 720, height: 900))
        #expect(right == CGRect(x: 720, y: 0, width: 720, height: 900))
        #expect(top == CGRect(x: 0, y: 450, width: 1440, height: 450))
        #expect(bottom == CGRect(x: 0, y: 0, width: 1440, height: 450))

        #expect(left.width + right.width == bounds.width)
        #expect(top.height + bottom.height == bounds.height)
    }

    @Test func fiftyFiftySplit_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let left = engine.frame(for: .leftHalf, in: bounds)
        let right = engine.frame(for: .rightHalf, in: bounds)

        #expect(left == CGRect(x: 0, y: 0, width: 960, height: 1080))
        #expect(right == CGRect(x: 960, y: 0, width: 960, height: 1080))
    }

    // MARK: - TC-002: Four Corners (25% Each)

    @Test func fourCorners_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let tl = engine.frame(for: .topLeft, in: bounds)
        let tr = engine.frame(for: .topRight, in: bounds)
        let bl = engine.frame(for: .bottomLeft, in: bounds)
        let br = engine.frame(for: .bottomRight, in: bounds)

        #expect(tl == CGRect(x: 0, y: 540, width: 960, height: 540))
        #expect(tr == CGRect(x: 960, y: 540, width: 960, height: 540))
        #expect(bl == CGRect(x: 0, y: 0, width: 960, height: 540))
        #expect(br == CGRect(x: 960, y: 0, width: 960, height: 540))
    }

    // MARK: - TC-004: Maximize with Visible Frame Offsets

    @Test func maximize_withDockAndMenuBarOffsets() {
        let bounds = CGRect(x: 0, y: 25, width: 1440, height: 875)

        let maxFrame = engine.frame(for: .maximize, in: bounds)

        #expect(maxFrame == CGRect(x: 0, y: 25, width: 1440, height: 875))
    }

    // MARK: - TC-005: Multi-Resolution Determinism

    @Test func multiResolutionCoverage() {
        let resolutions: [CGSize] = [
            CGSize(width: 2560, height: 1440), // 2K Display
            CGSize(width: 3840, height: 2160), // 4K Display
            CGSize(width: 1080, height: 1920)  // Portrait Display
        ]

        for size in resolutions {
            let bounds = CGRect(origin: .zero, size: size)
            let left = engine.frame(for: .leftHalf, in: bounds)
            let right = engine.frame(for: .rightHalf, in: bounds)
            let top = engine.frame(for: .topHalf, in: bounds)
            let bottom = engine.frame(for: .bottomHalf, in: bounds)

            #expect(left.width + right.width == bounds.width)
            #expect(top.height + bottom.height == bounds.height)
            #expect(left.minX == 0)
            #expect(right.maxX == bounds.width)
            #expect(bottom.minY == 0)
            #expect(top.maxY == bounds.height)
        }
    }

    // MARK: - Multi-Window Layout Mapping

    @Test func multipleWindowsLayoutMapping() {
        let bounds = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let layout = Layout(
            name: "Two Columns",
            zones: [.leftHalf, .rightHalf]
        )

        let win1 = ManagedWindow(id: 1, pid: 101, title: "Win 1", frame: .zero)
        let win2 = ManagedWindow(id: 2, pid: 102, title: "Win 2", frame: .zero)

        let frames = engine.frames(for: [win1, win2], in: bounds, layout: layout)

        #expect(frames[1] == CGRect(x: 0, y: 0, width: 720, height: 900))
        #expect(frames[2] == CGRect(x: 720, y: 0, width: 720, height: 900))
    }

    // MARK: - TC-TOP-001: 70/30 Asymmetric & 3-Column Splits

    @Test func asymmetricSeventyThirtySplit_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let left70 = engine.frame(for: .leftTwoThirds, in: bounds)
        let right30 = engine.frame(for: .rightOneThird, in: bounds)

        #expect(left70 == CGRect(x: 0, y: 0, width: 1344, height: 1080))
        #expect(right30 == CGRect(x: 1344, y: 0, width: 576, height: 1080))
        #expect(left70.width + right30.width == bounds.width)
    }

    @Test func threeColumnEqualSplit_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let col1 = engine.frame(for: .leftThird, in: bounds)
        let col2 = engine.frame(for: .centerThird, in: bounds)
        let col3 = engine.frame(for: .rightThird, in: bounds)

        #expect(col1 == CGRect(x: 0, y: 0, width: 640, height: 1080))
        #expect(col2 == CGRect(x: 640, y: 0, width: 640, height: 1080))
        #expect(col3 == CGRect(x: 1280, y: 0, width: 640, height: 1080))
        #expect(col1.width + col2.width + col3.width == bounds.width)
    }
}
