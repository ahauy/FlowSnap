import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("DisplayNavigator Tests")
struct DisplayNavigatorTests {

    private let navigator = DisplayNavigator()

    private func makeDisplay(id: CGDirectDisplayID, x: CGFloat, y: CGFloat, width: CGFloat = 1920, height: CGFloat = 1080) -> Display {
        Display(
            id: id,
            frame: CGRect(x: x, y: y, width: width, height: height),
            visibleFrame: CGRect(x: x, y: y + 25, width: width, height: height - 25),
            scaleFactor: 2.0,
            isPrimary: x == 0 && y == 0
        )
    }

    @Test("TC-015-02: Sorts displays spatially from left to right with Y tie-break")
    func testSpatialSorting() {
        let d1 = makeDisplay(id: 1, x: 1920, y: 0)
        let d2 = makeDisplay(id: 2, x: -1440, y: 0)
        let d3 = makeDisplay(id: 3, x: 0, y: 0)
        let d4 = makeDisplay(id: 4, x: 0, y: -1080)

        let sorted = navigator.sortedDisplays(from: [d1, d2, d3, d4])
        let sortedIDs = sorted.map(\.id)

        #expect(sortedIDs == [2, 4, 3, 1])
    }

    @Test("TC-015-03: Cyclic modulo nextDisplay navigation")
    func testNextDisplayCyclic() {
        let left = makeDisplay(id: 10, x: -1440, y: 0)
        let mid = makeDisplay(id: 20, x: 0, y: 0)
        let right = makeDisplay(id: 30, x: 1920, y: 0)
        let displays = [left, mid, right]

        #expect(navigator.nextDisplay(after: left, in: displays)?.id == 20)
        #expect(navigator.nextDisplay(after: mid, in: displays)?.id == 30)
        #expect(navigator.nextDisplay(after: right, in: displays)?.id == 10) // Wrap-around
    }

    @Test("TC-015-03: Cyclic modulo previousDisplay navigation")
    func testPreviousDisplayCyclic() {
        let left = makeDisplay(id: 10, x: -1440, y: 0)
        let mid = makeDisplay(id: 20, x: 0, y: 0)
        let right = makeDisplay(id: 30, x: 1920, y: 0)
        let displays = [left, mid, right]

        #expect(navigator.previousDisplay(before: left, in: displays)?.id == 30) // Wrap-around
        #expect(navigator.previousDisplay(before: right, in: displays)?.id == 20)
        #expect(navigator.previousDisplay(before: mid, in: displays)?.id == 10)
    }

    @Test("TC-015-06: Single display safe degradation returns nil")
    func testSingleDisplayReturnsNil() {
        let single = makeDisplay(id: 1, x: 0, y: 0)
        #expect(navigator.nextDisplay(after: single, in: [single]) == nil)
        #expect(navigator.previousDisplay(before: single, in: [single]) == nil)
    }

    @Test("Empty displays list returns nil")
    func testEmptyDisplays() {
        let dummy = makeDisplay(id: 1, x: 0, y: 0)
        #expect(navigator.nextDisplay(after: dummy, in: []) == nil)
        #expect(navigator.previousDisplay(before: dummy, in: []) == nil)
    }
}
