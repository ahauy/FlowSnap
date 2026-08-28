import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for CoordinateTransformer pure mathematical involution and coordinate conversion.
///
/// Traces to US-SNAP-003, TC-DISP-001 through TC-DISP-004, BR-DISP-001, BR-DISP-003, BR-DISP-007.
struct CoordinateTransformerTests {

    // MARK: - TC-DISP-001: Standard AppKit to AX Rect Inversion

    @Test func standardAppKitToAXInversion() {
        let primaryHeight: CGFloat = 900
        // Top half in AppKit: y is from 450 to 900
        let appKitRect = CGRect(x: 0, y: 450, width: 720, height: 450)

        let axRect = CoordinateTransformer.toAX(rect: appKitRect, primaryScreenHeight: primaryHeight)

        // In AX coordinates, origin is top-left, so top half has y = 0
        #expect(axRect.origin.x == 0)
        #expect(axRect.origin.y == 0)
        #expect(axRect.width == 720)
        #expect(axRect.height == 450)
    }

    @Test func bottomHalfAppKitToAXInversion() {
        let primaryHeight: CGFloat = 900
        // Bottom half in AppKit: y is from 0 to 450
        let appKitRect = CGRect(x: 0, y: 0, width: 720, height: 450)

        let axRect = CoordinateTransformer.toAX(rect: appKitRect, primaryScreenHeight: primaryHeight)

        // In AX coordinates, bottom half has y = 900 - (0 + 450) = 450
        #expect(axRect.origin.x == 0)
        #expect(axRect.origin.y == 450)
        #expect(axRect.width == 720)
        #expect(axRect.height == 450)
    }

    // MARK: - TC-DISP-002: Exact Mathematical Involution

    @Test func exactMathematicalInvolution() {
        let primaryHeight: CGFloat = 1080
        let testRects = [
            CGRect(x: 0, y: 0, width: 1920, height: 1080),
            CGRect(x: 100, y: 200, width: 600, height: 400),
            CGRect(x: -500, y: 300, width: 500, height: 700),
            CGRect(x: 1920, y: -200, width: 1440, height: 900)
        ]

        for rect in testRects {
            let ax = CoordinateTransformer.toAX(rect: rect, primaryScreenHeight: primaryHeight)
            let roundTrip = CoordinateTransformer.toAppKit(rect: ax, primaryScreenHeight: primaryHeight)

            #expect(roundTrip == rect)
        }
    }

    @Test func pointInvolution() {
        let primaryHeight: CGFloat = 1080
        let testPoints = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 500, y: 1080),
            CGPoint(x: -200, y: 400),
            CGPoint(x: 2560, y: -100)
        ]

        for point in testPoints {
            let axPoint = CoordinateTransformer.toAX(point: point, primaryScreenHeight: primaryHeight)
            let roundTrip = CoordinateTransformer.toAppKit(point: axPoint, primaryScreenHeight: primaryHeight)

            #expect(roundTrip == point)
        }
    }

    // MARK: - TC-DISP-003: Negative Coordinate External Screen Inversion

    @Test func negativeCoordinateExternalScreen() {
        let primaryHeight: CGFloat = 1000
        // External screen positioned below the primary display: y = -800, height = 800
        let windowFrame = CGRect(x: 100, y: -800, width: 600, height: 400)

        // In AX coordinates: Y_AX = 1000 - (-800 + 400) = 1000 - (-400) = 1400
        let axRect = CoordinateTransformer.toAX(rect: windowFrame, primaryScreenHeight: primaryHeight)

        #expect(axRect == CGRect(x: 100, y: 1400, width: 600, height: 400))

        let roundTrip = CoordinateTransformer.toAppKit(rect: axRect, primaryScreenHeight: primaryHeight)
        #expect(roundTrip == windowFrame)
    }

    @Test func externalScreenPositionedLeftOfPrimary() {
        let primaryHeight: CGFloat = 900
        // External screen positioned left of primary: x = -1920, y = 0, width = 1920, height = 1080
        let windowFrame = CGRect(x: -1800, y: 100, width: 800, height: 600)

        let axRect = CoordinateTransformer.toAX(rect: windowFrame, primaryScreenHeight: primaryHeight)

        #expect(axRect.origin.x == -1800)
        #expect(axRect.origin.y == 200.0)
        #expect(axRect.width == 800)
        #expect(axRect.height == 600)
    }

    // MARK: - TC-DISP-004: Sub-pixel Float Precision

    @Test func subPixelFloatPrecision() {
        let primaryHeight: CGFloat = 1000.5
        let fractionalRect = CGRect(x: 100.25, y: 200.75, width: 600.333, height: 400.125)

        let axRect = CoordinateTransformer.toAX(rect: fractionalRect, primaryScreenHeight: primaryHeight)

        let expectedY = primaryHeight - (fractionalRect.origin.y + fractionalRect.height)
        #expect(axRect.origin.x == 100.25)
        #expect(axRect.origin.y == expectedY)
        #expect(axRect.width == 600.333)
        #expect(axRect.height == 400.125)

        let roundTrip = CoordinateTransformer.toAppKit(rect: axRect, primaryScreenHeight: primaryHeight)
        #expect(roundTrip == fractionalRect)
    }
}
