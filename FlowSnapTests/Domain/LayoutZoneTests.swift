import Testing
import CoreGraphics
@testable import FlowSnap

/// Tests for LayoutZone normalized coordinate calculations.
///
/// See spec §51 — unit tests focused on Layout Engine.
struct LayoutZoneTests {

    @Test func zoneCoversFullScreen() {
        let zone = LayoutZone(x: 0, y: 0, width: 1, height: 1)
        #expect(zone.width == 1.0)
        #expect(zone.height == 1.0)
    }

    @Test func zoneCoversLeftHalf() {
        let zone = LayoutZone(x: 0, y: 0, width: 0.5, height: 1)
        #expect(zone.x == 0)
        #expect(zone.width == 0.5)
    }

    // TODO: Test 60/40, 70/30, four corners, gaps
    // TODO: Test Retina, 4K, portrait displays
}
