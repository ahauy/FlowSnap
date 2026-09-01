import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

/// Tests for the geometry half of full-screen classification.
///
/// Every frame here is a live measurement from a 1440x900 display with a 30pt menu
/// bar, taken over Accessibility in raw AX coordinates (top-left origin). They are
/// recorded as numbers rather than described, because the whole point of the rule
/// is that the shapes are close enough to be confused by a looser test.
///
/// The Dock sits on the left edge on this machine, so `visibleFrame` is
/// `(64,0,1376,870)`. That is what breaks an exact `visibleFrame` comparison: a
/// genuinely full-screen window still covers the full display width.
struct FullScreenGeometryTests {

    private static let display = AXAccessibilityService.DisplayGeometry(
        frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
        menuBarHeight: 30
    )

    private static var displays: [AXAccessibilityService.DisplayGeometry] { [display] }

    // MARK: - Genuine full-screen must be accepted

    @Test func realFullScreenWindowFillsDisplay() {
        // Measured on a window this test process owns and toggled with
        // toggleFullScreen(nil): attribute true, position not settable.
        let frame = CGRect(x: 0, y: 30, width: 1440, height: 870)
        #expect(AXAccessibilityService.fillsDisplay(frame, in: Self.displays))
    }

    @Test func fullScreenOnSecondaryDisplayIsAccepted() {
        // Same shape, offset to a display to the right of the primary one.
        let secondary = AXAccessibilityService.DisplayGeometry(
            frame: CGRect(x: 1440, y: 0, width: 1920, height: 1080),
            menuBarHeight: 30
        )
        let frame = CGRect(x: 1440, y: 30, width: 1920, height: 1050)
        #expect(AXAccessibilityService.fillsDisplay(frame, in: [Self.display, secondary]))
    }

    // MARK: - The false positive that motivated this rule

    @Test func chromiumZoomedWindowIsNotFullScreen() {
        // Brave's AXMainWindow, measured while its menu bar was still on screen:
        // it answered AXFullScreen = true for this frame. Chromium reports the web
        // content rectangle as the window frame, so the tab strip (40pt) and the
        // bookmarks bar (41pt) are already subtracted from the top.
        let frame = CGRect(x: 0, y: 111, width: 1440, height: 789)
        #expect(!AXAccessibilityService.fillsDisplay(frame, in: Self.displays))
    }

    @Test func ordinaryWindowsAreNotFullScreen() {
        // Zalo, VS Code, System Settings and a Finder document window.
        let frames: [CGRect] = [
            CGRect(x: 64, y: 30, width: 686, height: 870),
            CGRect(x: 72, y: 38, width: 1360, height: 855),
            CGRect(x: 545, y: 30, width: 723, height: 870),
            CGRect(x: 754, y: 30, width: 682, height: 870)
        ]
        for frame in frames {
            #expect(!AXAccessibilityService.fillsDisplay(frame, in: Self.displays), "misclassified \(frame) as full-screen")
        }
    }

    // MARK: - Menu bar height must come from the display, not be assumed

    @Test func windowCoveringTheMenuBarIsNotFullScreen() {
        // A window stretched over the menu bar too. Reaching the bottom is not
        // enough on its own; the top edge has to sit at the menu bar line.
        let frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        #expect(!AXAccessibilityService.fillsDisplay(frame, in: Self.displays))
    }

    @Test func narrowWindowTouchingBottomIsNotFullScreen() {
        let frame = CGRect(x: 0, y: 30, width: 700, height: 870)
        #expect(!AXAccessibilityService.fillsDisplay(frame, in: Self.displays))
    }

    @Test func toleranceAbsorbsRoundingButNotAMissingToolbar() {
        // 1pt of shadow inset at the screen edge is normal.
        let inset = CGRect(x: 0, y: 31, width: 1439, height: 869)
        #expect(AXAccessibilityService.fillsDisplay(inset, in: Self.displays))

        // A 60pt gap is a toolbar or a docked panel, not full-screen.
        let gapped = CGRect(x: 0, y: 90, width: 1440, height: 810)
        #expect(!AXAccessibilityService.fillsDisplay(gapped, in: Self.displays))
    }

    @Test func emptyDisplayListMatchesNothing() {
        #expect(!AXAccessibilityService.fillsDisplay(CGRect(x: 0, y: 30, width: 1440, height: 870), in: []))
    }

    // MARK: - The menu bar height must not absorb the Dock

    @Test func menuBarHeightIgnoresBottomDock() {
        // 1440x900 in AppKit space: 30pt menu bar, 70pt Dock along the bottom.
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 70, width: 1440, height: 800)

        let height = AXAccessibilityService.DisplayGeometry.menuBarHeight(
            frame: screenFrame,
            visibleFrame: visible
        )
        #expect(height == 30)

        // The tempting shortcut is wrong here: it yields 100, and a full-screen
        // window's top edge sits at 30, so it would be rejected.
        #expect(screenFrame.height - visible.height == 100)
    }

    @Test func menuBarHeightIgnoresLeftDock() {
        // The configuration measured on the development machine, where the two
        // formulas agree - which is why the bottom-Dock case is easy to miss.
        let screenFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 64, y: 0, width: 1376, height: 870)
        let height = AXAccessibilityService.DisplayGeometry.menuBarHeight(
            frame: screenFrame,
            visibleFrame: visible
        )
        #expect(height == 30)
    }

    @Test func fullScreenIsStillRecognisedWithDockAtBottom() {
        // A full-screen window covers the Dock, so its frame does not change with
        // Dock position; only a mis-derived menu bar height could break this.
        let dockBottom = AXAccessibilityService.DisplayGeometry(
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            menuBarHeight: AXAccessibilityService.DisplayGeometry.menuBarHeight(
                frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                visibleFrame: CGRect(x: 0, y: 70, width: 1440, height: 800)
            )
        )
        #expect(AXAccessibilityService.fillsDisplay(
            CGRect(x: 0, y: 30, width: 1440, height: 870),
            in: [dockBottom]
        ))
    }
}
