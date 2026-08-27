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
        #expect(top.origin.y == 0)
        #expect(bottom.origin.y == 450)

        // Invariants: Total width & height match exactly with zero gaps and zero overflow
        #expect(left.width + right.width == bounds.width)
        #expect(top.height + bottom.height == bounds.height)
        #expect(right.maxX == bounds.width)
        #expect(bottom.maxY == bounds.height)
    }

    @Test func oddPixelQuarters_1441x901() {
        let bounds = CGRect(x: 0, y: 0, width: 1441, height: 901)

        let tl = engine.frame(for: .topLeft, in: bounds)
        let tr = engine.frame(for: .topRight, in: bounds)
        let bl = engine.frame(for: .bottomLeft, in: bounds)
        let br = engine.frame(for: .bottomRight, in: bounds)

        #expect(tl == CGRect(x: 0, y: 0, width: 720, height: 450))
        #expect(tr == CGRect(x: 720, y: 0, width: 721, height: 450))
        #expect(bl == CGRect(x: 0, y: 450, width: 720, height: 451))
        #expect(br == CGRect(x: 720, y: 450, width: 721, height: 451))

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
}
