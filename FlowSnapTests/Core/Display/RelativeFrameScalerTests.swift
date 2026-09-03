import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("RelativeFrameScaler Tests")
struct RelativeFrameScalerTests {

    @Test("TC-015-04: Proportional relative frame scaling between FHD and 4K displays")
    func testProportionalScaling() {
        let sourceVisible = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let targetVisible = CGRect(x: 1920, y: 0, width: 3840, height: 2160)

        // Window at 10% X, 10% Y, 50% W, 50% H on source
        let window = CGRect(x: 192, y: 108, width: 960, height: 540)

        let scaled = RelativeFrameScaler.scale(
            frame: window,
            from: sourceVisible,
            to: targetVisible
        )

        #expect(abs(scaled.origin.x - 2304.0) < 0.1)
        #expect(abs(scaled.origin.y - 216.0) < 0.1)
        #expect(abs(scaled.width - 1920.0) < 0.1)
        #expect(abs(scaled.height - 1080.0) < 0.1)
    }

    @Test("TC-015-05: Enforces minimum dimensions of 200x200 pt")
    func testMinimumDimensionsEnforced() {
        let sourceVisible = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let targetVisible = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        // Very tiny window (50x50)
        let tinyWindow = CGRect(x: 100, y: 100, width: 50, height: 50)

        let scaled = RelativeFrameScaler.scale(
            frame: tinyWindow,
            from: sourceVisible,
            to: targetVisible,
            minSize: CGSize(width: 200, height: 200)
        )

        #expect(scaled.width >= 200)
        #expect(scaled.height >= 200)
    }

    @Test("TC-015-05: Clamps window within target visible bounds")
    func testClampingWithinTargetBounds() {
        let sourceVisible = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let targetVisible = CGRect(x: 1000, y: 100, width: 1440, height: 900)

        // Window near right edge of source
        let window = CGRect(x: 1800, y: 900, width: 800, height: 600)

        let scaled = RelativeFrameScaler.scale(
            frame: window,
            from: sourceVisible,
            to: targetVisible
        )

        #expect(scaled.minX >= targetVisible.minX)
        #expect(scaled.maxX <= targetVisible.maxX)
        #expect(scaled.minY >= targetVisible.minY)
        #expect(scaled.maxY <= targetVisible.maxY)
    }

    @Test("Handles empty source or target bounds gracefully")
    func testEmptyBoundsSafety() {
        let emptySource = CGRect.zero
        let validTarget = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let window = CGRect(x: 100, y: 100, width: 400, height: 400)

        let result = RelativeFrameScaler.scale(
            frame: window,
            from: emptySource,
            to: validTarget
        )

        #expect(result == validTarget)
    }
}
