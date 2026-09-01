import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
@Suite("AdaptiveDividerOverlayPanel Tests")
struct AdaptiveDividerOverlayPanelTests {

    let container = CGRect(x: 0, y: 0, width: 1440, height: 900)

    private func makeSampleData() -> ([ManagedWindow], [CollinearEdge]) {
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        let divider = CollinearEdge(
            orientation: .vertical,
            coordinate: 720,
            span: 0...900,
            hitRect: CGRect(x: 714, y: 0, width: 12, height: 900),
            leadingWindowIDs: [1],
            trailingWindowIDs: [2],
            minCoordinate: 200,
            maxCoordinate: 1240
        )
        return ([w1, w2], [divider])
    }

    @Test("Panel is initialized transparent and click-through so global monitors own hit testing")
    func panelInitialization() {
        let panel = AdaptiveDividerOverlayPanel()
        #expect(panel.isOpaque == false)
        #expect(panel.backgroundColor == .clear)
        #expect(panel.level == .floating + 1)
        // The seam is hit-tested from the coordinator's global mouse monitors, so
        // the panel must never swallow clicks meant for the windows underneath it.
        #expect(panel.ignoresMouseEvents == true)
        #expect(panel.styleMask.contains(.borderless))
        #expect(panel.styleMask.contains(.nonactivatingPanel))
    }

    @Test("Show and hide lifecycle updates panel visibility and alpha")
    func showAndHideLifecycle() {
        let panel = AdaptiveDividerOverlayPanel()
        let (windows, dividers) = makeSampleData()

        // Active hover / drag -> alphaValue becomes 1.0
        panel.show(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: dividers.first,
            isDragging: false
        )

        #expect(panel.frame == container)
        #expect(panel.overlayView.windows.count == 2)
        #expect(panel.overlayView.dividers.count == 1)
        #expect(panel.overlayView.activeDivider?.id == dividers.first?.id)

        panel.hide(animated: false)
        #expect(panel.alphaValue == 0.0)
        #expect(panel.isOverlayVisible == false)
    }

    @Test("Overlay is fully hidden when idle and opaque on hover or drag")
    func restingAlphaTransition() {
        let panel = AdaptiveDividerOverlayPanel()
        let (windows, dividers) = makeSampleData()

        // Clean Workspace: nothing lingers on screen when the pointer leaves the
        // seam, so the resting alpha is 0 and `show` collapses the panel entirely.
        #expect(AdaptiveDividerOverlayPanel.restingAlpha == 0.0)
        #expect(AdaptiveDividerOverlayPanel.activeAlpha == 1.0)

        // 1. Idle/resting (no active divider, not dragging) -> panel hides itself
        panel.show(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: nil,
            isDragging: false
        )
        #expect(panel.isOverlayVisible == false)
        #expect(panel.overlayView.activeDivider == nil)

        // 2. Active hover -> alpha is 1.0
        panel.show(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: dividers.first,
            isDragging: false
        )
        #expect(panel.isOverlayVisible == true)
        #expect(panel.overlayView.activeDivider?.id == dividers.first?.id)

        // 3. Live drag -> alpha is 1.0
        panel.update(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: dividers.first,
            isDragging: true
        )
        #expect(panel.alphaValue == 1.0)
    }

    @Test("Compute seam rect creates an 8-10px interactive seam")
    func seamRectComputation() {
        let panel = AdaptiveDividerOverlayPanel()
        let view = panel.overlayView

        let vDivider = CollinearEdge(
            orientation: .vertical,
            coordinate: 720,
            span: 100...800,
            hitRect: CGRect(x: 714, y: 100, width: 12, height: 700),
            leadingWindowIDs: [1],
            trailingWindowIDs: [2],
            minCoordinate: 200,
            maxCoordinate: 1240
        )

        let hDivider = CollinearEdge(
            orientation: .horizontal,
            coordinate: 450,
            span: 200...1200,
            hitRect: CGRect(x: 200, y: 444, width: 1000, height: 12),
            leadingWindowIDs: [1],
            trailingWindowIDs: [2],
            minCoordinate: 150,
            maxCoordinate: 750
        )

        view.updateState(
            containerFrame: container,
            windows: [],
            dividers: [vDivider, hDivider],
            activeDivider: nil,
            isDragging: false
        )

        let vSeam = view.computeSeamRect(for: vDivider)
        #expect(vSeam.origin.x == 711) // 720 - 9.0
        #expect(vSeam.width == 18.0)
        #expect(vSeam.origin.y == 100)
        #expect(vSeam.height == 700)

        let hSeam = view.computeSeamRect(for: hDivider)
        #expect(hSeam.origin.y == 441) // 450 - 9.0
        #expect(hSeam.height == 18.0)
        #expect(hSeam.origin.x == 200)
        #expect(hSeam.width == 1000)
    }

    @Test("Hit-testing allows click pass-through outside divider seam")
    func hitTestingPassThrough() {
        let panel = AdaptiveDividerOverlayPanel()
        let view = panel.overlayView
        let (windows, dividers) = makeSampleData()

        view.updateState(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: nil,
            isDragging: false
        )

        // Point directly inside the 10px divider seam (X=720, Y=450) -> returns view
        let hitDivider = view.hitTest(NSPoint(x: 720, y: 450))
        #expect(hitDivider == view)

        // Point over left window body (X=300, Y=450) -> returns nil (pass-through)
        let hitWindow = view.hitTest(NSPoint(x: 300, y: 450))
        #expect(hitWindow == nil)

        // While dragging is active, all points return view
        view.updateState(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: dividers.first,
            isDragging: true
        )
        let hitWhileDragging = view.hitTest(NSPoint(x: 300, y: 450))
        #expect(hitWhileDragging == view)
    }

    @Test("Direct mouse drag events notify registered callbacks")
    func directMouseDragCallbacks() {
        let panel = AdaptiveDividerOverlayPanel()
        let view = panel.overlayView
        let (windows, dividers) = makeSampleData()

        view.updateState(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: nil,
            isDragging: false
        )

        var mouseDownPoint: CGPoint?
        var mouseDraggedPoint: CGPoint?
        var mouseUpPoint: CGPoint?

        view.onDirectMouseDown = { point, _ in mouseDownPoint = point }
        view.onDirectMouseDragged = { point in mouseDraggedPoint = point }
        view.onDirectMouseUp = { point in mouseUpPoint = point }

        guard let downEvent = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: NSPoint(x: 720, y: 450),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            eventNumber: 1,
            clickCount: 1,
            pressure: 1.0
        ) else {
            Issue.record("Failed to create mouseDown event")
            return
        }
        view.mouseDown(with: downEvent)
        #expect(mouseDownPoint == CGPoint(x: 720, y: 450))
        #expect(view.isDragging == true)

        guard let dragEvent = NSEvent.mouseEvent(
            with: .leftMouseDragged,
            location: NSPoint(x: 750, y: 450),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            eventNumber: 2,
            clickCount: 1,
            pressure: 1.0
        ) else {
            Issue.record("Failed to create mouseDragged event")
            return
        }
        view.mouseDragged(with: dragEvent)
        #expect(mouseDraggedPoint == CGPoint(x: 750, y: 450))

        guard let upEvent = NSEvent.mouseEvent(
            with: .leftMouseUp,
            location: NSPoint(x: 750, y: 450),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: panel.windowNumber,
            context: nil,
            eventNumber: 3,
            clickCount: 1,
            pressure: 0.0
        ) else {
            Issue.record("Failed to create mouseUp event")
            return
        }
        view.mouseUp(with: upEvent)
        #expect(mouseUpPoint == CGPoint(x: 750, y: 450))
        #expect(view.isDragging == false)
    }

    @Test("Window outlines render individual windows without desktop workspace container border")
    func windowOutlinesRenderWithoutDesktopContainerBorder() {
        let panel = AdaptiveDividerOverlayPanel()
        let view = panel.overlayView
        let (windows, dividers) = makeSampleData()

        view.updateState(
            containerFrame: container,
            windows: windows,
            dividers: dividers,
            activeDivider: nil,
            isDragging: false
        )

        // Window borders container layer should only contain shapes for individual windows (count == 2)
        // without an intrusive full-screen container border outline
        let windowBordersLayer = view.layer?.sublayers?.first
        #expect(windowBordersLayer?.sublayers?.count == 2)
    }

    @Test("Secondary display offset is strictly isolated")
    func multiMonitorBoundaryIsolation() {
        let panel = AdaptiveDividerOverlayPanel()
        let view = panel.overlayView
        let secondaryContainer = CGRect(x: 1440, y: 0, width: 1920, height: 1080)

        let divider = CollinearEdge(
            orientation: .vertical,
            coordinate: 2400, // 1440 + 960
            span: 0...1080,
            hitRect: CGRect(x: 2394, y: 0, width: 12, height: 1080),
            leadingWindowIDs: [1],
            trailingWindowIDs: [2],
            minCoordinate: 1640,
            maxCoordinate: 3160
        )

        view.updateState(
            containerFrame: secondaryContainer,
            windows: [],
            dividers: [divider],
            activeDivider: nil,
            isDragging: false
        )

        let seam = view.computeSeamRect(for: divider)
        // In local view coordinates, localX = 2400 - 1440 = 960, half thickness = 9 -> origin.x = 951
        #expect(seam.origin.x == 951)
        #expect(seam.width == 18.0)
        #expect(seam.height == 1080)
    }
}
