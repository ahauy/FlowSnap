import Testing
import CoreGraphics
@testable import FlowSnap

/// Tests for LayoutEngine frame calculations.
///
/// These are the most important unit tests in FlowSnap.
/// See spec §51.
struct LayoutEngineTests {

    let engine = LayoutEngine()

    // MARK: - 50/50 Split

    @Test func fiftyFiftySplit_1440x900() {
        // TODO: Test that 50/50 layout on 1440×900 produces
        //       two 720×900 frames
    }

    // TODO: Test 60/40 split
    // TODO: Test 70/30 split
    // TODO: Test four corners (25% each)
    // TODO: Test with gaps
    // TODO: Test 4K display (2560×1440)
    // TODO: Test Retina scaling
    // TODO: Test portrait display
    // TODO: Test multiple displays
}
