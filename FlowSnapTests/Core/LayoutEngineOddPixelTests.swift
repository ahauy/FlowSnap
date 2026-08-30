import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests specifically validating the flooring policy (BR-LAYOUT-002) for odd-pixel dimensions.
///
/// Traces to US-SNAP-002, TC-003.
struct LayoutEngineOddPixelTests {

    let engine = LayoutEngine()

    @Test func oddPixelWidthAndHeight_1441x901() {
        let bounds = CGRect(x: 0, y: 0, width: 1441, height: 901)

        let left = engine.frame(for: .leftHalf, in: bounds)
        let right = engine.frame(for: .rightHalf, in: bounds)
        let top = engine.frame(for: .topHalf, in: bounds)
        let bottom = engine.frame(for: .bottomHalf, in: bounds)

        // Flooring policy: Left/Top gets floor(dim/2), Right/Bottom gets dim - floor(dim/2)
        #expect(left.width == 720)
        #expect(right.width == 721)
        #expect(left.origin.x == 0)
        #expect(right.origin.x == 720)

        #expect(top.height == 450)
        #expect(bottom.height == 451)
        #expect(top.origin.y == 451)
        #expect(bottom.origin.y == 0)

        // Invariants: Total width & height match exactly with zero gaps and zero overflow
        #expect(left.width + right.width == bounds.width)
        #expect(top.height + bottom.height == bounds.height)
        #expect(right.maxX == bounds.width)
        #expect(top.maxY == bounds.height)
    }

    @Test func oddPixelQuarters_1441x901() {
        let bounds = CGRect(x: 0, y: 0, width: 1441, height: 901)

        let tl = engine.frame(for: .topLeft, in: bounds)
        let tr = engine.frame(for: .topRight, in: bounds)
        let bl = engine.frame(for: .bottomLeft, in: bounds)
        let br = engine.frame(for: .bottomRight, in: bounds)

        #expect(tl == CGRect(x: 0, y: 451, width: 720, height: 450))
        #expect(tr == CGRect(x: 720, y: 451, width: 721, height: 450))
        #expect(bl == CGRect(x: 0, y: 0, width: 720, height: 451))
        #expect(br == CGRect(x: 720, y: 0, width: 721, height: 451))

        #expect(tl.width + tr.width == bounds.width)
        #expect(bl.width + br.width == bounds.width)
        #expect(tl.height + bl.height == bounds.height)
        #expect(tr.height + br.height == bounds.height)
    }

    @Test func oddPixelWithOffsetOrigin() {
        let bounds = CGRect(x: 15, y: 35, width: 1501, height: 951)

        let left = engine.frame(for: .leftHalf, in: bounds)
        let right = engine.frame(for: .rightHalf, in: bounds)

        #expect(left.origin.x == 15)
        #expect(left.width == 750)
        #expect(right.origin.x == 765) // 15 + 750
        #expect(right.width == 751)
        #expect(right.maxX == bounds.maxX)
    }

    // MARK: - US-SNAP-008: Odd Pixel Asymmetric Ratios (BR-CRW-001)

    @Test func oddPixelLeft60_40_999px() {
        let bounds = CGRect(x: 0, y: 0, width: 999, height: 800)
        let left60 = engine.frame(for: .left60_40, in: bounds)
        let right40 = engine.frame(for: .right40_60, in: bounds)

        // effectiveWidth = 999; left60 = floor(999*0.6) = 599; right40 = 400
        #expect(left60.width == 599)
        #expect(right40.width == 400)
        #expect(left60.width + right40.width == bounds.width)
    }

    @Test func oddPixelLeft80_20_999px() {
        let bounds = CGRect(x: 0, y: 0, width: 999, height: 800)
        let left80 = engine.frame(for: .left80_20, in: bounds)
        let right20 = engine.frame(for: .right20_80, in: bounds)

        // left80 = floor(999*0.8) = 799; right20 = 200
        #expect(left80.width == 799)
        #expect(right20.width == 200)
        #expect(left80.width + right20.width == bounds.width)
    }

    @Test func oddPixel25_50_25_999px() {
        let bounds = CGRect(x: 0, y: 0, width: 999, height: 800)
        let col1 = engine.frame(for: .left25, in: bounds)
        let col2 = engine.frame(for: .center50, in: bounds)
        let col3 = engine.frame(for: .right25, in: bounds)

        // q25 = floor(999*0.25) = 249; half = floor(999*0.5) = 499; remainder = 251
        #expect(col1.width == 249)
        #expect(col2.width == 499)
        #expect(col3.width == 251)
        #expect(col1.width + col2.width + col3.width == bounds.width)
    }

    @Test func oddPixelLeft70_30_999px() {
        let bounds = CGRect(x: 0, y: 0, width: 999, height: 800)
        let left70 = engine.frame(for: .left70_30, in: bounds)
        let right30 = engine.frame(for: .rightOneThird, in: bounds)

        // left70 = floor(999*0.7) = 699; right30 = 300
        #expect(left70.width == 699)
        #expect(right30.width == 300)
        #expect(left70.width + right30.width == bounds.width)
    }

    @Test func oddPixelUniformGap_999px() {
        let bounds = CGRect(x: 0, y: 0, width: 999, height: 800)

        let left = engine.frame(for: .leftHalf, in: bounds, gap: 8, uniform: true)
        let right = engine.frame(for: .rightHalf, in: bounds, gap: 8, uniform: true)

        // effectiveWidth = 999 - 24 = 975; left = floor(975/2) = 487; right = 488
        #expect(left.minX == 8)
        #expect(left.width == 487)
        #expect(right.width == 488)
        #expect(right.maxX == bounds.maxX - 8)
        #expect(left.width + right.width + 24 == bounds.width)
    }
}
