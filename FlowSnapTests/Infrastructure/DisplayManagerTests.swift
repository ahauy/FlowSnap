import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for DisplayManager spatial queries, multi-monitor overlap, and cyclic navigation.
///
/// Traces to US-SNAP-003, TC-DISP-005 through TC-DISP-010, BR-DISP-001, BR-DISP-002, BR-DISP-004, BR-DISP-006.
@MainActor
struct DisplayManagerTests {

    // Helper to generate simulated multi-display setups
    static func createSimulatedDualMonitors() -> [Display] {
        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let secondary = Display(
            id: 2,
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            visibleFrame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            scaleFactor: 1.0,
            isPrimary: false
        )
        return [primary, secondary]
    }

    // MARK: - TC-DISP-005: Straddling Window Resolved to Maximum Overlap

    @Test func straddlingWindowResolvesToMaxOverlapDisplay() async {
        let displays = Self.createSimulatedDualMonitors()
        let manager = DisplayManager(displayProvider: { displays })

        // Window straddling the boundary:
        // Position: x = 1300, width = 500.
        // Overlap on Primary (x: 0..1440): from 1300 to 1440 = 140 width * 400 = 56,000 pt²
        // Overlap on Secondary (x: 1440..3360): from 1440 to 1800 = 360 width * 400 = 144,000 pt²
        let windowFrame = CGRect(x: 1300, y: 100, width: 500, height: 400)

        let target = await manager.display(for: windowFrame)

        #expect(target?.id == 2)
    }

    @Test func straddlingWindowFavoringPrimaryDisplay() async {
        let displays = Self.createSimulatedDualMonitors()
        let manager = DisplayManager(displayProvider: { displays })

        // Window mostly on primary:
        // Position: x = 1100, width = 500 (1100..1600)
        // Overlap on Primary: 1100..1440 = 340 width * 400 = 136,000 pt²
        // Overlap on Secondary: 1440..1600 = 160 width * 400 = 64,000 pt²
        let windowFrame = CGRect(x: 1100, y: 100, width: 500, height: 400)

        let target = await manager.display(for: windowFrame)

        #expect(target?.id == 1)
    }

    // MARK: - TC-DISP-006: Contained Window Resolution

    @Test func containedWindowResolution() async {
        let displays = Self.createSimulatedDualMonitors()
        let manager = DisplayManager(displayProvider: { displays })

        let frameOnPrimary = CGRect(x: 100, y: 100, width: 600, height: 400)
        let targetPrimary = await manager.display(for: frameOnPrimary)
        #expect(targetPrimary?.id == 1)

        let frameOnSecondary = CGRect(x: 1600, y: 200, width: 800, height: 500)
        let targetSecondary = await manager.display(for: frameOnSecondary)
        #expect(targetSecondary?.id == 2)
    }

    // MARK: - TC-DISP-007: Off-Screen Fallback to Cursor Location

    @Test func offScreenWindowFallbackToCursor() async {
        let displays = Self.createSimulatedDualMonitors()
        let manager = DisplayManager(displayProvider: { displays })

        // Window positioned completely out of any display bounds
        let offScreenFrame = CGRect(x: -5000, y: -5000, width: 400, height: 300)

        // Cursor on Secondary display (x: 1600, y: 500)
        let cursorOnSecondary = CGPoint(x: 1600, y: 500)
        let target = await manager.display(for: offScreenFrame, cursorPoint: cursorOnSecondary)

        #expect(target?.id == 2)

        // Cursor out of bounds too -> falls back to primary
        let offScreenCursor = CGPoint(x: -9999, y: -9999)
        let targetPrimaryFallback = await manager.display(for: offScreenFrame, cursorPoint: offScreenCursor)
        #expect(targetPrimaryFallback?.id == 1)
    }

    // MARK: - TC-DISP-009: Cyclic Multi-Display Navigation

    @Test func cyclicMultiDisplayNavigation() async {
        let displays = Self.createSimulatedDualMonitors()
        let manager = DisplayManager(displayProvider: { displays })

        let primary = displays[0]
        let secondary = displays[1]

        let nextFromPrimary = await manager.nextDisplay(after: primary)
        #expect(nextFromPrimary?.id == 2)

        let nextFromSecondary = await manager.nextDisplay(after: secondary)
        #expect(nextFromSecondary?.id == 1) // Wraps around
    }

    // MARK: - TC-DISP-010: Single Screen Navigation Guard

    @Test func singleScreenNavigationGuard() async {
        let singleScreen = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 25, width: 1440, height: 875),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let manager = DisplayManager(displayProvider: { [singleScreen] })

        let next = await manager.nextDisplay(after: singleScreen)
        #expect(next == nil)
    }

    // MARK: - Primary Screen Height Property

    @Test func primaryScreenHeight() async {
        let displays = Self.createSimulatedDualMonitors()
        let manager = DisplayManager(displayProvider: { displays })

        let height = await manager.primaryScreenHeight
        #expect(height == 900)
    }
}
