import ApplicationServices
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Integration tests for TopologyProfileManager.
///
/// Traces to: US-DISP-016, REQ-DISP-004..007, BR-DISP-009..013, TC-016-04..07.
@MainActor
struct TopologyProfileManagerTests {

    private func makeDisplay(
        id: CGDirectDisplayID,
        originX: CGFloat,
        width: CGFloat = 1920,
        height: CGFloat = 1080,
        isPrimary: Bool = false
    ) -> Display {
        Display(
            id: id,
            frame: CGRect(x: originX, y: 0, width: width, height: height),
            visibleFrame: CGRect(x: originX, y: 25, width: width, height: height - 25),
            scaleFactor: 2.0,
            isPrimary: isPrimary
        )
    }

    private func makeManagedWindow(
        id: CGWindowID,
        bundleID: String,
        frame: CGRect
    ) -> ManagedWindow {
        ManagedWindow(
            id: id,
            pid: pid_t(id),
            bundleIdentifier: bundleID,
            title: "Test Window \(id)",
            frame: frame
        )
    }

    @Test func captureProfileRecordsPlacementsAndDisplays() async {
        let display1 = makeDisplay(id: 1, originX: 0, isPrimary: true)
        let display2 = makeDisplay(id: 2, originX: 1920)

        let mockDisplay = MockDisplayManager(displays: [display1, display2])
        let mockAX = MockAccessibilityService(isTrusted: true)

        let win1 = makeManagedWindow(id: 101, bundleID: "com.apple.Safari", frame: CGRect(x: 100, y: 100, width: 800, height: 600))
        let win2 = makeManagedWindow(id: 102, bundleID: "com.microsoft.VSCode", frame: CGRect(x: 2000, y: 100, width: 960, height: 1000))
        mockAX.mockVisibleWindows = [win1, win2]

        let userDefaults = UserDefaults(suiteName: "TestTopologySuite_\(UUID().uuidString)")!
        let manager = TopologyProfileManager(
            displayManager: mockDisplay,
            accessibilityService: mockAX,
            userDefaults: userDefaults
        )

        let fp = TopologyFingerprint.generate(from: [display1, display2])
        let profile = await manager.captureProfile(for: fp, name: "Dual Setup")

        #expect(profile.fingerprint == fp)
        #expect(profile.windowPlacements.count == 2)
        #expect(profile.displayIndexMap["com.apple.Safari"] == 0)
        #expect(profile.displayIndexMap["com.microsoft.VSCode"] == 1)
    }

    @Test func hotUnplugClampsWindowsToPrimaryDisplay() async {
        let display1 = makeDisplay(id: 1, originX: 0, width: 1440, height: 900, isPrimary: true)
        let display2 = makeDisplay(id: 2, originX: 1440, width: 1920, height: 1080)

        let mockDisplay = MockDisplayManager(displays: [display1]) // Unplugged, only display1 left
        mockDisplay.mockPrimaryDisplay = display1
        let mockAX = MockAccessibilityService(isTrusted: true)
        mockAX.mockFocusedElement = AXUIElementCreateSystemWide()

        // Window was at external display (x: 1800), now needing clamping on display1 (0..<1440)
        let win = makeManagedWindow(id: 101, bundleID: "com.microsoft.VSCode", frame: CGRect(x: 1800, y: 100, width: 1200, height: 800))
        mockAX.mockVisibleWindows = [win]

        let userDefaults = UserDefaults(suiteName: "TestTopologySuite_\(UUID().uuidString)")!
        let manager = TopologyProfileManager(
            displayManager: mockDisplay,
            accessibilityService: mockAX,
            userDefaults: userDefaults
        )

        let fp1 = TopologyFingerprint.generate(from: [display1])
        let fp2 = TopologyFingerprint.generate(from: [display1, display2])

        await manager.handleTopologyChange(.hotUnplugDisconnected(newFingerprint: fp1, departingFingerprint: fp2))

        #expect(mockAX.setFrameCallCount >= 1)
        if let lastFrame = mockAX.lastSetFrame {
            #expect(lastFrame.minX >= display1.visibleFrame.minX)
            #expect(lastFrame.maxX <= display1.visibleFrame.maxX)
            #expect(lastFrame.minY >= display1.visibleFrame.minY)
            #expect(lastFrame.maxY <= display1.visibleFrame.maxY)
        } else {
            Issue.record("Expected setFrame to be called with clamped frame")
        }
    }

    @Test func hotPlugAutoRestoresWindowsToTargetDisplays() async {
        let display1 = makeDisplay(id: 1, originX: 0, width: 1440, height: 900, isPrimary: true)
        let display2 = makeDisplay(id: 2, originX: 1440, width: 1920, height: 1080)

        let mockDisplay = MockDisplayManager(displays: [display1, display2])
        let mockAX = MockAccessibilityService(isTrusted: true)
        mockAX.mockFocusedElement = AXUIElementCreateSystemWide()

        let winSafari = makeManagedWindow(id: 101, bundleID: "com.apple.Safari", frame: CGRect(x: 100, y: 100, width: 600, height: 500))
        let winCode = makeManagedWindow(id: 102, bundleID: "com.microsoft.VSCode", frame: CGRect(x: 200, y: 200, width: 600, height: 500))
        mockAX.mockVisibleWindows = [winSafari, winCode]

        let userDefaults = UserDefaults(suiteName: "TestTopologySuite_\(UUID().uuidString)")!
        let manager = TopologyProfileManager(
            displayManager: mockDisplay,
            accessibilityService: mockAX,
            userDefaults: userDefaults
        )

        let fp = TopologyFingerprint.generate(from: [display1, display2])

        // Save a profile where Code is on display index 1
        var profile = DisplayTopologyProfile(fingerprint: fp, name: "Desk")
        profile.windowPlacements = [
            "com.apple.Safari": WindowPlacement(bundleIdentifier: "com.apple.Safari", zone: .leftHalf),
            "com.microsoft.VSCode": WindowPlacement(bundleIdentifier: "com.microsoft.VSCode", zone: .rightHalf)
        ]
        profile.displayIndexMap = [
            "com.apple.Safari": 0,
            "com.microsoft.VSCode": 1
        ]
        manager.saveProfile(profile)

        // Trigger hot plug
        await manager.handleTopologyChange(.hotPlugConnected(newFingerprint: fp, addedCount: 1))

        #expect(mockAX.setFrameCallCount >= 2)
    }

    @Test func hotPlugGracefullySkipsMissingApps() async {
        let display1 = makeDisplay(id: 1, originX: 0, isPrimary: true)
        let display2 = makeDisplay(id: 2, originX: 1920)

        let mockDisplay = MockDisplayManager(displays: [display1, display2])
        let mockAX = MockAccessibilityService(isTrusted: true)
        mockAX.mockFocusedElement = AXUIElementCreateSystemWide()

        // Only Safari is open; VS Code is closed
        let winSafari = makeManagedWindow(id: 101, bundleID: "com.apple.Safari", frame: CGRect(x: 100, y: 100, width: 600, height: 500))
        mockAX.mockVisibleWindows = [winSafari]

        let userDefaults = UserDefaults(suiteName: "TestTopologySuite_\(UUID().uuidString)")!
        let manager = TopologyProfileManager(
            displayManager: mockDisplay,
            accessibilityService: mockAX,
            userDefaults: userDefaults
        )

        let fp = TopologyFingerprint.generate(from: [display1, display2])
        var profile = DisplayTopologyProfile(fingerprint: fp)
        profile.windowPlacements = [
            "com.apple.Safari": WindowPlacement(bundleIdentifier: "com.apple.Safari", zone: .leftHalf),
            "com.microsoft.VSCode": WindowPlacement(bundleIdentifier: "com.microsoft.VSCode", zone: .rightHalf)
        ]
        profile.displayIndexMap = [
            "com.apple.Safari": 0,
            "com.microsoft.VSCode": 1
        ]
        manager.saveProfile(profile)

        let success = await manager.restoreProfile(profile)
        #expect(success == true)
        #expect(mockAX.setFrameCallCount == 1) // Only Safari was set, Code skipped cleanly
    }
}
