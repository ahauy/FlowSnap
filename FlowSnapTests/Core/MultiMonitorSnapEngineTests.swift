import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for SnapEngine multi-monitor frame calculation and AX coordinate inversion.
///
/// Traces to US-SNAP-003, TC-DISP-011, TC-DISP-012, REQ-DISP-002, REQ-DISP-003, REQ-DISP-006.
@MainActor
struct MultiMonitorSnapEngineTests {

    static func makeSimulatedEnvironment() -> (SnapEngine, DisplayManager, [Display]) {
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
        let displays = [primary, secondary]
        let displayManager = DisplayManager(displayProvider: { displays })
        let registry = WindowRegistry()
        let snapEngine = SnapEngine(windowRegistry: registry, displayManager: displayManager)
        return (snapEngine, displayManager, displays)
    }

    // MARK: - TC-DISP-011: Multi-Monitor Target Frame & AX Conversion

    @Test func calculateAXFrameOnSecondaryDisplay() async {
        let (snapEngine, displayManager, displays) = Self.makeSimulatedEnvironment()
        let secondary = displays[1]

        // Window located on secondary display
        let window = ManagedWindow(
            id: 101,
            pid: 2001,
            title: "Secondary Window",
            frame: CGRect(x: 1600, y: 200, width: 600, height: 400),
            kind: .normal
        )

        // Snap to left half on secondary display
        // Secondary visibleFrame: x: 1440, y: 0, width: 1920, height: 1080
        // Left half in AppKit: x: 1440, y: 0, width: 960, height: 1080
        // Primary Screen Height: 900
        // AX Inversion:
        // x_AX = 1440
        // y_AX = 900 - (0 + 1080) = -180
        // width = 960, height = 1080
        let axFrame = await snapEngine.calculateAXFrame(
            for: .left,
            window: window,
            displayManager: displayManager
        )

        #expect(axFrame != nil)
        #expect(axFrame?.origin.x == 1440)
        #expect(axFrame?.origin.y == -180)
        #expect(axFrame?.width == 960)
        #expect(axFrame?.height == 1080)
    }

    @Test func calculateAXFrameOnPrimaryDisplay() async {
        let (snapEngine, displayManager, displays) = Self.makeSimulatedEnvironment()
        let primary = displays[0]

        // Window on primary display
        let window = ManagedWindow(
            id: 102,
            pid: 2002,
            title: "Primary Window",
            frame: CGRect(x: 100, y: 100, width: 600, height: 400),
            kind: .normal
        )

        // Snap to left half on primary display
        // Primary visibleFrame: x: 0, y: 25, width: 1440, height: 875
        // Left half in AppKit: x: 0, y: 25, width: 720, height: 875
        // Primary Screen Height: 900
        // AX Inversion:
        // x_AX = 0
        // y_AX = 900 - (25 + 875) = 0
        // width = 720, height = 875
        let axFrame = await snapEngine.calculateAXFrame(
            for: .left,
            window: window,
            displayManager: displayManager
        )

        #expect(axFrame != nil)
        #expect(axFrame?.origin.x == 0)
        #expect(axFrame?.origin.y == 0)
        #expect(axFrame?.width == 720)
        #expect(axFrame?.height == 875)
    }

    // MARK: - TC-DISP-012: Move Window to Next Display Preserving Zone

    @Test func moveWindowToNextDisplayPreservingZone() async {
        let (snapEngine, displayManager, _) = Self.makeSimulatedEnvironment()

        // Window initially on primary display (x: 100)
        let window = ManagedWindow(
            id: 103,
            pid: 2003,
            title: "Window To Move",
            frame: CGRect(x: 100, y: 100, width: 600, height: 400),
            kind: .normal
        )

        // Move to next display snapped to right half
        let result = await snapEngine.calculateFrameOnNextDisplay(
            for: .right,
            window: window,
            displayManager: displayManager
        )

        #expect(result != nil)
        #expect(result?.display.id == 2)
        // Right half on Secondary (x: 1440..3360):
        // x: 1440 + 960 = 2400, y: 0, width: 960, height: 1080
        #expect(result?.frame.origin.x == 2400)
        #expect(result?.frame.origin.y == 0)
        #expect(result?.frame.width == 960)
        #expect(result?.frame.height == 1080)
    }
}
