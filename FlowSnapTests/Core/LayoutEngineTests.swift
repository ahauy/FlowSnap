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

    // MARK: - US-SNAP-008: Asymmetric Ratios (60/40, 80/20, 25/50/25)

    @Test func sixtyFortySplit_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let left60 = engine.frame(for: .left60_40, in: bounds)
        let right40 = engine.frame(for: .right40_60, in: bounds)

        #expect(left60 == CGRect(x: 0, y: 0, width: 1152, height: 1080))
        #expect(right40 == CGRect(x: 1152, y: 0, width: 768, height: 1080))
        #expect(left60.width + right40.width == bounds.width)
    }

    @Test func eightyTwentySplit_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let left80 = engine.frame(for: .left80_20, in: bounds)
        let right20 = engine.frame(for: .right20_80, in: bounds)

        #expect(left80 == CGRect(x: 0, y: 0, width: 1536, height: 1080))
        #expect(right20 == CGRect(x: 1536, y: 0, width: 384, height: 1080))
        #expect(left80.width + right20.width == bounds.width)
    }

    @Test func threeColumn25_50_25Split_1920x1080() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let col1 = engine.frame(for: .left25, in: bounds)
        let col2 = engine.frame(for: .center50, in: bounds)
        let col3 = engine.frame(for: .right25, in: bounds)

        #expect(col1 == CGRect(x: 0, y: 0, width: 480, height: 1080))
        #expect(col2 == CGRect(x: 480, y: 0, width: 960, height: 1080))
        #expect(col3 == CGRect(x: 1440, y: 0, width: 480, height: 1080))
        #expect(col1.width + col2.width + col3.width == bounds.width)
    }

    @Test func seventyThirtySplit_UsesLeft70_30() {
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let left70 = engine.frame(for: .left70_30, in: bounds)
        let right30 = engine.frame(for: .rightOneThird, in: bounds)

        #expect(left70 == CGRect(x: 0, y: 0, width: 1344, height: 1080))
        #expect(right30 == CGRect(x: 1344, y: 0, width: 576, height: 1080))
        #expect(left70.width + right30.width == bounds.width)
    }

    // MARK: - US-SNAP-008: Uniform Gap (BR-CRW-003)

    @Test func uniformGap_InsetsBothOuterEdges() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

        let left = engine.frame(for: .leftHalf, in: bounds, gap: 8, uniform: true)
        let right = engine.frame(for: .rightHalf, in: bounds, gap: 8, uniform: true)

        // effectiveWidth = 1000 - 3*8 = 976; left = 488, right = 488
        // left minX = 8, maxX = 496; right minX = 8 + 488 + 8 = 504, maxX = 504 + 488 = 992 (bounds.maxX - 8)
        #expect(left.minX == 8)
        #expect(left.width == 488)
        #expect(right.maxX == bounds.maxX - 8)
        #expect(right.minX == CGFloat(8 + 488 + 8))
        #expect(left.width + right.width + CGFloat(3 * 8) == bounds.width)
    }

    @Test func legacyGap_OnlyInnerGutter() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

        let left = engine.frame(for: .leftHalf, in: bounds, gap: 8, uniform: false)
        let right = engine.frame(for: .rightHalf, in: bounds, gap: 8, uniform: false)

        // Legacy: outer edges flush, only inner gutter (BR-CRW-004)
        #expect(left.minX == 0)
        #expect(right.maxX == bounds.maxX)
        #expect(right.minX - left.maxX == 8)
    }

    @Test func uniformGap_ThreeColumn_InsetsOuterEdges() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

        let col1 = engine.frame(for: .left25, in: bounds, gap: 8, uniform: true)
        let col2 = engine.frame(for: .center50, in: bounds, gap: 8, uniform: true)
        let col3 = engine.frame(for: .right25, in: bounds, gap: 8, uniform: true)

        #expect(col1.minX == 8)
        #expect(col3.maxX == bounds.maxX - 8) // outer right edge inset by gap
        #expect(col2.minX - col1.maxX == 8)
        #expect(col3.minX - col2.maxX == 8)
    }

    @Test func uniformGap_ZeroGap_MatchesLegacy() {
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 800)

        let uniformZero = engine.frame(for: .leftHalf, in: bounds, gap: 0, uniform: true)
        let legacyZero = engine.frame(for: .leftHalf, in: bounds, gap: 0, uniform: false)

        #expect(uniformZero == legacyZero)
    }
}
