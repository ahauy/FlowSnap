import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for LayoutZone enum definitions and normalized bounds.
///
/// See spec §51 — unit tests focused on Domain Layout definitions.
struct LayoutZoneTests {

    @Test func allCasesCount() {
        // 14 legacy + 7 asymmetric/ratio zones + 2 explicit 50/50 zones (left50_50, right50_50).
        // Deprecated leftTwoThirds is excluded from allCases.
        #expect(LayoutZone.allCases.count == 23)
        #expect(LayoutZone.allCases.contains(.left60_40))
        #expect(LayoutZone.allCases.contains(.right25))
        #expect(LayoutZone.allCases.contains(.left50_50))
        #expect(LayoutZone.allCases.contains(.right50_50))
    }

    @Test func normalizedRectCoordinates() {
        #expect(LayoutZone.leftHalf.normalizedRect == CGRect(x: 0, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.rightHalf.normalizedRect == CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.left50_50.normalizedRect == CGRect(x: 0, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.right50_50.normalizedRect == CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.topHalf.normalizedRect == CGRect(x: 0, y: 0, width: 1.0, height: 0.5))
        #expect(LayoutZone.bottomHalf.normalizedRect == CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5))
        #expect(LayoutZone.topLeft.normalizedRect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        #expect(LayoutZone.topRight.normalizedRect == CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5))
        #expect(LayoutZone.bottomLeft.normalizedRect == CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5))
        #expect(LayoutZone.bottomRight.normalizedRect == CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
        #expect(LayoutZone.maximize.normalizedRect == CGRect(x: 0, y: 0, width: 1.0, height: 1.0))
        #expect(LayoutZone.leftTwoThirds.normalizedRect == CGRect(x: 0, y: 0, width: 0.7, height: 1.0))
        #expect(LayoutZone.rightOneThird.normalizedRect == CGRect(x: 0.7, y: 0, width: 0.3, height: 1.0))
        #expect(LayoutZone.leftThird.normalizedRect.width == 1.0 / 3.0)
        #expect(LayoutZone.centerThird.normalizedRect.minX == 1.0 / 3.0)
        #expect(LayoutZone.rightThird.normalizedRect.minX == 2.0 / 3.0)

        // US-SNAP-008 asymmetric ratios
        #expect(LayoutZone.left60_40.normalizedRect == CGRect(x: 0, y: 0, width: 0.6, height: 1.0))
        #expect(LayoutZone.right40_60.normalizedRect == CGRect(x: 0.6, y: 0, width: 0.4, height: 1.0))
        #expect(LayoutZone.left80_20.normalizedRect == CGRect(x: 0, y: 0, width: 0.8, height: 1.0))
        #expect(LayoutZone.right20_80.normalizedRect == CGRect(x: 0.8, y: 0, width: 0.2, height: 1.0))
        #expect(LayoutZone.left25.normalizedRect == CGRect(x: 0, y: 0, width: 0.25, height: 1.0))
        #expect(LayoutZone.center50.normalizedRect == CGRect(x: 0.25, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.right25.normalizedRect == CGRect(x: 0.75, y: 0, width: 0.25, height: 1.0))
        #expect(LayoutZone.left70_30.normalizedRect == CGRect(x: 0, y: 0, width: 0.7, height: 1.0))
    }

    @Test func codableSerialization() throws {
        for zone in LayoutZone.allCases {
            let data = try JSONEncoder().encode(zone)
            let decoded = try JSONDecoder().decode(LayoutZone.self, from: data)
            #expect(decoded == zone)
        }
    }
}
