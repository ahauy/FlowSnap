import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for LayoutZone enum definitions and normalized bounds.
///
/// See spec §51 — unit tests focused on Domain Layout definitions.
struct LayoutZoneTests {

    @Test func allCasesCount() {
        #expect(LayoutZone.allCases.count == 9)
    }

    @Test func normalizedRectCoordinates() {
        #expect(LayoutZone.leftHalf.normalizedRect == CGRect(x: 0, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.rightHalf.normalizedRect == CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0))
        #expect(LayoutZone.topHalf.normalizedRect == CGRect(x: 0, y: 0, width: 1.0, height: 0.5))
        #expect(LayoutZone.bottomHalf.normalizedRect == CGRect(x: 0, y: 0.5, width: 1.0, height: 0.5))
        #expect(LayoutZone.topLeft.normalizedRect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        #expect(LayoutZone.topRight.normalizedRect == CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5))
        #expect(LayoutZone.bottomLeft.normalizedRect == CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5))
        #expect(LayoutZone.bottomRight.normalizedRect == CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
        #expect(LayoutZone.maximize.normalizedRect == CGRect(x: 0, y: 0, width: 1.0, height: 1.0))
    }

    @Test func codableSerialization() throws {
        for zone in LayoutZone.allCases {
            let data = try JSONEncoder().encode(zone)
            let decoded = try JSONDecoder().decode(LayoutZone.self, from: data)
            #expect(decoded == zone)
        }
    }
}
