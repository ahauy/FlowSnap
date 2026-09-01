import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Locks the coordinate convention that `ZoneInference` depends on, using
/// hand-computed rectangles only — no Accessibility, AppKit or display service.
///
/// This suite exists because the capture path once carried three mutually
/// cancelling coordinate errors (a double `toAppKit` flip in `appKitFrame`, a
/// second in `visibleFrame`, and a y-up/y-down mismatch against
/// `LayoutZone.normalizedRect`). Each was invisible on a single origin-(0,0)
/// display, so the end-to-end tests stayed green while the convention was wrong.
/// Testing the pure math directly means a future re-flip fails here loudly
/// instead of silently mis-restoring windows on a vertically stacked monitor.
@Suite("ZoneInference")
struct ZoneInferenceTests {

    /// A 1000x1000 display at the origin, so normalized coordinates equal the
    /// frame's own pixels divided by 1000 — trivially checkable by hand.
    private let display = CGRect(x: 0, y: 0, width: 1000, height: 1000)

    // MARK: - normalizedRect is y-down (matches LayoutZone.normalizedRect)

    @Test("A window filling the display normalizes to the whole unit square")
    func fullDisplay() {
        let rect = ZoneInference.normalizedRect(of: display, within: display)
        #expect(rect == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    @Test("A window in the AppKit top-left normalizes to y-down top-left")
    func topLeftIsYDown() {
        // AppKit y-up: the top-left quadrant is x [0,500], y [500,1000].
        let appKit = CGRect(x: 0, y: 500, width: 500, height: 500)
        let rect = ZoneInference.normalizedRect(of: appKit, within: display)
        // y-down: the top edge is at y=0, not y=0.5.
        #expect(rect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
    }

    @Test("A window in the AppKit bottom-right normalizes to y-down bottom-right")
    func bottomRightIsYDown() {
        // AppKit y-up: the bottom-right quadrant is x [500,1000], y [0,500].
        let appKit = CGRect(x: 500, y: 0, width: 500, height: 500)
        let rect = ZoneInference.normalizedRect(of: appKit, within: display)
        #expect(rect == CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
    }

    @Test("A window on a display with a non-zero origin normalizes relative to it")
    func offsetDisplay() {
        // A secondary display at x=1000; the window sits in its left half.
        let visible = CGRect(x: 1000, y: 0, width: 1000, height: 1000)
        let appKit = CGRect(x: 1000, y: 0, width: 500, height: 1000)
        let rect = ZoneInference.normalizedRect(of: appKit, within: visible)
        #expect(rect == CGRect(x: 0, y: 0, width: 0.5, height: 1))
    }

    @Test("A window hanging off the top edge clamps to the unit square")
    func clampsOverflow() {
        // Extends 200pt above the display; maxY must clamp to 1.
        let appKit = CGRect(x: 0, y: 800, width: 500, height: 400)
        let rect = ZoneInference.normalizedRect(of: appKit, within: display)
        #expect(rect.maxY <= 1.0 + 0.0001)
        #expect(rect.minX >= 0)
    }

    @Test("A zero-size display yields the whole square rather than dividing by zero")
    func degenerateDisplay() {
        let rect = ZoneInference.normalizedRect(of: display, within: .zero)
        #expect(rect == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    // MARK: - inferZone round-trips every zone's own rectangle

    @Test("Each zone inferred from its own rect yields an equivalent rect")
    func everyZoneRoundTrips() {
        // The invariant is "same rectangle", not "same case": LayoutZone contains
        // deliberate aliases (leftTwoThirds and left70_30 are both 0...0.7, as are
        // rightOneThird and right30_70), so IoU is exactly 1 for both and the
        // tie-break can only pick one. Either choice restores identically.
        for zone in LayoutZone.allCases {
            let inferred = ZoneInference.inferZone(forNormalized: zone.normalizedRect)
            #expect(
                inferred.normalizedRect == zone.normalizedRect,
                "\(zone.rawValue) inferred as \(inferred.rawValue) with a different rect"
            )
        }
    }

    @Test("A left-half window infers to .leftHalf")
    func leftHalf() {
        let appKit = CGRect(x: 0, y: 0, width: 500, height: 1000)
        let rect = ZoneInference.normalizedRect(of: appKit, within: display)
        #expect(ZoneInference.inferZone(forNormalized: rect) == .leftHalf)
    }

    @Test("A top-half window infers to .topHalf, not .bottomHalf")
    func topHalf() {
        // AppKit y-up top half: y [500,1000].
        let appKit = CGRect(x: 0, y: 500, width: 1000, height: 500)
        let rect = ZoneInference.normalizedRect(of: appKit, within: display)
        #expect(ZoneInference.inferZone(forNormalized: rect) == .topHalf)
    }

    @Test("A bottom-half window infers to .bottomHalf")
    func bottomHalf() {
        let appKit = CGRect(x: 0, y: 0, width: 1000, height: 500)
        let rect = ZoneInference.normalizedRect(of: appKit, within: display)
        #expect(ZoneInference.inferZone(forNormalized: rect) == .bottomHalf)
    }

    // MARK: - IoU helper

    @Test("IoU of identical rects is 1")
    func iouIdentical() {
        #expect(ZoneInference.intersectionOverUnion(display, display) == 1)
    }

    @Test("IoU of disjoint rects is 0")
    func iouDisjoint() {
        let rectA = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rectB = CGRect(x: 200, y: 200, width: 100, height: 100)
        #expect(ZoneInference.intersectionOverUnion(rectA, rectB) == 0)
    }

    @Test("IoU of a half-overlap is 1/3")
    func iouHalfOverlap() {
        let rectA = CGRect(x: 0, y: 0, width: 100, height: 100)
        let rectB = CGRect(x: 50, y: 0, width: 100, height: 100)
        // intersection 5000, union 15000 → 1/3.
        #expect(abs(ZoneInference.intersectionOverUnion(rectA, rectB) - 1.0 / 3.0) < 0.0001)
    }

    @Test("IoU with an empty rect is 0")
    func iouEmpty() {
        #expect(ZoneInference.intersectionOverUnion(display, .zero) == 0)
    }
}
