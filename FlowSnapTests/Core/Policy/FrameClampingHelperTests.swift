import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite
struct FrameClampingHelperTests {

    @Test func withinBoundsFrameRemainsUnchanged() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let frame = CGRect(x: 100, y: 100, width: 800, height: 600)

        let result = FrameClampingHelper.clamp(frame: frame, to: screen)
        #expect(result == frame)
    }

    @Test func offScreenRightClampsInsideScreen() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = CGRect(x: 2000, y: 100, width: 800, height: 600)

        let result = FrameClampingHelper.clamp(frame: frame, to: screen)
        #expect(result.maxX <= screen.maxX)
        #expect(result.minX >= screen.minX)
        #expect(result.width == 800)
        #expect(result.height == 600)
    }

    @Test func offScreenBottomClampsInsideScreen() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = CGRect(x: 100, y: 1200, width: 600, height: 500)

        let result = FrameClampingHelper.clamp(frame: frame, to: screen)
        #expect(result.maxY <= screen.maxY)
        #expect(result.minY >= screen.minY)
    }

    @Test func oversizedWindowClampsToScreenDimensions() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let frame = CGRect(x: -200, y: -200, width: 2560, height: 1440)

        let result = FrameClampingHelper.clamp(frame: frame, to: screen)
        #expect(result.width <= screen.width)
        #expect(result.height <= screen.height)
        #expect(result.minX >= screen.minX)
        #expect(result.minY >= screen.minY)
    }
}
