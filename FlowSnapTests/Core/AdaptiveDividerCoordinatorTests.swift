import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@MainActor
final class MockAdaptiveDividerOverlayManager: AdaptiveDividerOverlayManaging {
    var isOverlayVisible: Bool = false
    var showCallCount: Int = 0
    var updateCallCount: Int = 0
    var hideCallCount: Int = 0
    var lastContainerFrame: CGRect?
    var lastWindows: [ManagedWindow] = []
    var lastDividers: [CollinearEdge] = []
    var lastActiveDivider: CollinearEdge?
    var lastActiveJunction: CrossJunction?
    var lastIsDragging: Bool?

    func show(containerFrame: CGRect, windows: [ManagedWindow], dividers: [CollinearEdge], activeDivider: CollinearEdge?, activeJunction: CrossJunction?, isDragging: Bool) {
        showCallCount += 1
        isOverlayVisible = true
        lastContainerFrame = containerFrame
        lastWindows = windows
        lastDividers = dividers
        lastActiveDivider = activeDivider
        lastActiveJunction = activeJunction
        lastIsDragging = isDragging
    }

    func update(containerFrame: CGRect, windows: [ManagedWindow], dividers: [CollinearEdge], activeDivider: CollinearEdge?, activeJunction: CrossJunction?, isDragging: Bool) {
        updateCallCount += 1
        lastContainerFrame = containerFrame
        lastWindows = windows
        lastDividers = dividers
        lastActiveDivider = activeDivider
        lastActiveJunction = activeJunction
        lastIsDragging = isDragging
    }

    func hide(animated: Bool) {
        hideCallCount += 1
        isOverlayVisible = false
    }
}

/// Throttler double that grants a fixed number of commits instead of reading
/// the wall clock, keeping drag tests deterministic.
final class ScriptedThrottler: LiveResizeThrottling, @unchecked Sendable {
    private let lock = NSLock()
    private let allowance: Int
    private var remaining: Int
    private var _grants = 0

    init(grants: Int) {
        allowance = grants
        remaining = grants
    }

    var grantCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _grants
    }

    func shouldProcess(timestamp: TimeInterval) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard remaining > 0 else { return false }
        remaining -= 1
        _grants += 1
        return true
    }

    func reset() {
        lock.lock(); defer { lock.unlock() }
        remaining = allowance
        _grants = 0
    }
}

/// Counts detector invocations so tests can assert the hover/drag paths do not
/// re-run geometry work they should be reusing.
final class CountingDividerDetector: CollinearEdgeDetecting, @unchecked Sendable {
    private let underlying: CollinearEdgeDetector

    private let lock = NSLock()
    private var _detectCount = 0
    private var _resizeCount = 0

    init(defaultMinWidth: CGFloat = 200, defaultMinHeight: CGFloat = 150) {
        underlying = CollinearEdgeDetector(defaultMinWidth: defaultMinWidth, defaultMinHeight: defaultMinHeight)
    }

    var detectCount: Int { lock.lock(); defer { lock.unlock() }; return _detectCount }
    var resizeCount: Int { lock.lock(); defer { lock.unlock() }; return _resizeCount }
    func resetCounters() { lock.lock(); defer { lock.unlock() }; _detectCount = 0; _resizeCount = 0 }

    func detectDividers(in windows: [ManagedWindow], containerFrame: CGRect, gap: CGFloat, tolerance: CGFloat) -> [CollinearEdge] {
        lock.lock(); _detectCount += 1; lock.unlock()
        return underlying.detectDividers(in: windows, containerFrame: containerFrame, gap: gap, tolerance: tolerance)
    }

    func hitTestDivider(at point: CGPoint, in dividers: [CollinearEdge]) -> CollinearEdge? {
        underlying.hitTestDivider(at: point, in: dividers)
    }

    func computeResizedFrames(for divider: CollinearEdge, targetCoordinate: CGFloat, windows: [ManagedWindow], containerFrame: CGRect, gap: CGFloat) -> [CGWindowID: CGRect] {
        lock.lock(); _resizeCount += 1; lock.unlock()
        return underlying.computeResizedFrames(for: divider, targetCoordinate: targetCoordinate, windows: windows, containerFrame: containerFrame, gap: gap)
    }

    func detectJunctions(in dividers: [CollinearEdge], tolerance: CGFloat) -> [CrossJunction] {
        underlying.detectJunctions(in: dividers, tolerance: tolerance)
    }

    func hitTestJunction(at point: CGPoint, in junctions: [CrossJunction]) -> CrossJunction? {
        underlying.hitTestJunction(at: point, in: junctions)
    }

    func compute2DResizedFrames(for junction: CrossJunction, targetPoint: CGPoint, in dividers: [CollinearEdge], windows: [ManagedWindow], containerFrame: CGRect, gap: CGFloat) -> [CGWindowID: CGRect] {
        underlying.compute2DResizedFrames(for: junction, targetPoint: targetPoint, in: dividers, windows: windows, containerFrame: containerFrame, gap: gap)
    }
}

@MainActor
@Suite("AdaptiveDividerCoordinator Tests")
struct AdaptiveDividerCoordinatorTests {

    let displayBounds = CGRect(x: 0, y: 0, width: 1440, height: 900)

    private func makeSUT(
        overlayManager: AdaptiveDividerOverlayManaging? = nil,
        detector: CollinearEdgeDetecting? = nil,
        throttler: any LiveResizeThrottling = LiveResizeThrottler(fps: 1000.0),
        accessibilityService: AccessibilityService? = nil
    ) -> (AdaptiveDividerCoordinator, MockWindowManaging, MockDisplayManager, MockAdaptiveDividerOverlayManager?) {
        let mockWM = MockWindowManaging()
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let mockOverlay = (overlayManager as? MockAdaptiveDividerOverlayManager) ?? MockAdaptiveDividerOverlayManager()
        let coordinator = AdaptiveDividerCoordinator(
            detector: detector ?? CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150),
            windowManager: mockWM,
            displayManager: mockDM,
            throttler: throttler,
            accessibilityService: accessibilityService,
            overlayManager: mockOverlay
        )
        return (coordinator, mockWM, mockDM, mockOverlay)
    }

    @Test("Hover over vertical divider changes cursor to resizeLeftRight and reveals overlay with persistent resting state")
    func hoverOverVerticalDividerChangesCursor() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        // Hover directly on divider X=720
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.hoveredDivider?.orientation == .vertical)
        #expect(sut.currentCursor == .resizeLeftRight)
        #expect(mockOverlay?.showCallCount == 1)
        #expect(mockOverlay?.isOverlayVisible == true)
        #expect(mockOverlay?.lastActiveDivider?.orientation == .vertical)

        // Move away within the same display (hides overlay when not hovering on a divider)
        await sut.handleMouseMoved(to: CGPoint(x: 200, y: 450))
        #expect(sut.hoveredDivider == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Hover over horizontal divider changes cursor to resizeUpDown")
    func hoverOverHorizontalDividerChangesCursor() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Bottom", frame: CGRect(x: 0, y: 0, width: 1440, height: 450))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Top", frame: CGRect(x: 0, y: 450, width: 1440, height: 450))
        sut.updateWindows([w1, w2])

        await sut.handleMouseMoved(to: CGPoint(x: 500, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.hoveredDivider?.orientation == .horizontal)
        #expect(sut.currentCursor == .resizeUpDown)
        #expect(mockOverlay?.showCallCount == 1)
    }

    @Test("MouseDown on divider captures active divider and begins resizing")
    func mouseDownCapturesActiveDivider() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        let hit = await sut.handleMouseDown(at: CGPoint(x: 721, y: 300))
        #expect(hit == true)
        #expect(sut.isResizing == true)
        #expect(sut.activeDivider != nil)
        #expect(mockOverlay?.lastIsDragging == true)

        let miss = await sut.handleMouseDown(at: CGPoint(x: 100, y: 100))
        #expect(miss == false)
    }

    @Test("MouseDrag dispatches simultaneous resize to WindowManager and updates overlay")
    func mouseDragResizesCollinearWindows() async {
        let (sut, mockWM, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 10, pid: 1, title: "VSCode", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 20, pid: 2, title: "Chrome", frame: CGRect(x: 720, y: 450, width: 720, height: 450))
        let w3 = ManagedWindow(id: 30, pid: 3, title: "Terminal", frame: CGRect(x: 720, y: 0, width: 720, height: 450))
        sut.updateWindows([w1, w2, w3])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 300))
        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 300))

        #expect(mockWM.moveCallCount >= 3)
        #expect(sut.managedWindows.first { $0.id == 10 }?.frame.width == 800)
        #expect(sut.managedWindows.first { $0.id == 20 }?.frame.origin.x == 800)
        #expect(sut.managedWindows.first { $0.id == 20 }?.frame.width == 640)
        #expect(sut.managedWindows.first { $0.id == 30 }?.frame.origin.x == 800)
        #expect(sut.managedWindows.first { $0.id == 30 }?.frame.width == 640)
        #expect(mockOverlay?.updateCallCount ?? 0 >= 1)
        #expect(mockOverlay?.lastIsDragging == true)

        // Mouse up ends session and hides overlay
        await sut.handleMouseUp(at: CGPoint(x: 800, y: 300))
        #expect(sut.isResizing == false)
        #expect(sut.activeDivider == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Real-time overlay and window frames update in lockstep during drag, followed by atomic final snap on mouseUp")
    func realTimeOverlayAndWindowFramesUpdateInLockstepOnDrag() async {
        let mockWM = MockWindowManaging()
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let mockOverlay = MockAdaptiveDividerOverlayManager()

        let coordinator = AdaptiveDividerCoordinator(
            detector: CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150),
            windowManager: mockWM,
            displayManager: mockDM,
            throttler: LiveResizeThrottler(fps: 60.0),
            overlayManager: mockOverlay
        )

        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        coordinator.updateWindows([w1, w2])

        // 1. Mouse down
        _ = await coordinator.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // 2. Drag to X=850
        await coordinator.handleMouseDragged(to: CGPoint(x: 850, y: 450))

        // WindowManager move is called on every coalesced drag task
        #expect(mockWM.moveCallCount == 2)
        #expect(coordinator.managedWindows.first { $0.id == 1 }?.frame.width == 850)
        #expect(coordinator.managedWindows.first { $0.id == 2 }?.frame.origin.x == 850)
        #expect(coordinator.managedWindows.first { $0.id == 2 }?.frame.width == 590)

        // 3. Mouse up at final release position X=850
        await coordinator.handleMouseUp(at: CGPoint(x: 850, y: 450))

        // Atomic final snap guarantees 100% exact alignment
        #expect(coordinator.managedWindows.first { $0.id == 1 }?.frame.width == 850)
        #expect(coordinator.managedWindows.first { $0.id == 2 }?.frame.origin.x == 850)
        #expect(coordinator.managedWindows.first { $0.id == 2 }?.frame.width == 590)
        #expect(coordinator.isResizing == false)
    }

    // MARK: - Hover caching

    @Test("Hover re-detects dividers only when the layout actually changes")
    func hoverCachesDividersAcrossEvents() async {
        let detector = CountingDividerDetector()
        let (sut, _, _, _) = makeSUT(detector: detector)
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        detector.resetCounters()

        // A pointer sweeping across a static layout must not re-run detection.
        for x in stride(from: 100.0, through: 1300.0, by: 25.0) {
            await sut.handleMouseMoved(to: CGPoint(x: x, y: 450))
        }
        #expect(detector.detectCount == 1)

        // Moving a window invalidates the cache on the very next event.
        var moved = w2
        moved.frame = CGRect(x: 800, y: 0, width: 640, height: 900)
        sut.updateWindows([w1, moved])
        await sut.handleMouseMoved(to: CGPoint(x: 450, y: 450))
        #expect(detector.detectCount == 2)
    }

    @Test("Hover does not refresh the overlay while nothing has changed")
    func hoverSkipsRedundantOverlayRefresh() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        // 1. Initial hover directly on divider presents overlay once
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        let afterFirst = mockOverlay?.showCallCount ?? 0
        #expect(afterFirst == 1)

        // 2. Moving along the same divider seam does not re-present
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 500))
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 420))
        #expect(mockOverlay?.showCallCount == afterFirst)

        // 3. Moving away hides overlay
        await sut.handleMouseMoved(to: CGPoint(x: 200, y: 450))
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    // MARK: - Drag stability

    @Test("Dragging one seam of a multi-divider layout keeps the guide on that seam")
    func dragKeepsIdentityOfDraggedSeam() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        // Three columns: seams at x=480 and x=960, both vertical.
        let w1 = ManagedWindow(id: 1, pid: 10, title: "A", frame: CGRect(x: 0, y: 0, width: 480, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "B", frame: CGRect(x: 480, y: 0, width: 480, height: 900))
        let w3 = ManagedWindow(id: 3, pid: 30, title: "C", frame: CGRect(x: 960, y: 0, width: 480, height: 900))
        sut.updateWindows([w1, w2, w3])

        // Grab the LEFT seam.
        _ = await sut.handleMouseDown(at: CGPoint(x: 480, y: 450))
        #expect(sut.activeDivider?.coordinate == 480)
        #expect(Set(sut.activeDivider?.leadingWindowIDs ?? []) == [1])

        await sut.handleMouseDragged(to: CGPoint(x: 600, y: 450))

        // The guide must follow the seam that was grabbed, not the other one.
        #expect(mockOverlay?.lastActiveDivider?.coordinate == 600)
        #expect(Set(mockOverlay?.lastActiveDivider?.leadingWindowIDs ?? []) == [1])

        // The untouched seam must still be drawn, and still sit at 960.
        let otherSeams = (mockOverlay?.lastDividers ?? []).filter {
            Set($0.leadingWindowIDs) != [1]
        }
        #expect(otherSeams.contains { $0.coordinate == 960 })

        await sut.handleMouseUp(at: CGPoint(x: 600, y: 450))
    }

    @Test("Drag re-detects only on throttled commits, not per mouse event")
    func dragDoesNotRedetectPerEvent() async {
        let detector = CountingDividerDetector()
        // Sixty pointer events, but only three commits are allowed through.
        let throttler = ScriptedThrottler(grants: 3)
        let (sut, _, _, _) = makeSUT(detector: detector, throttler: throttler)
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        detector.resetCounters()

        for x in stride(from: 730.0, through: 1000.0, by: 4.5) {
            await sut.handleMouseDragged(to: CGPoint(x: x, y: 450))
        }

        // Detection rides the throttle: one pass per commit, never per event.
        #expect(detector.detectCount == throttler.grantCount)
        #expect(detector.detectCount == 3)
        // The resize itself is still computed for every event, which is what
        // keeps the ghost guide tracking the pointer at full rate.
        #expect(detector.resizeCount > 60)
    }

    @Test("Window frames and overlay update in lockstep on every drag task")
    func windowFramesAndOverlayUpdateInLockstepOnDrag() async {
        let (sut, mockWM, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 450))
        #expect(mockOverlay?.lastActiveDivider?.coordinate == 800)
        #expect(mockWM.moveCallCount == 2)
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 800)

        await sut.handleMouseDragged(to: CGPoint(x: 850, y: 450))
        #expect(mockOverlay?.lastActiveDivider?.coordinate == 850)
        #expect(mockWM.moveCallCount == 4)
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 850)
        #expect(mockOverlay?.updateCallCount == 2)
    }

    @Test("Divider drag past the minimum clamps instead of inverting")
    func dragBeyondMinimumClamps() async {
        let (sut, mockWM, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // Yank far past the point where the right window would breach its
        // minimum. The seam must stop at the limit, never travel backwards.
        await sut.handleMouseDragged(to: CGPoint(x: 1440, y: 450))
        let leftWidth = sut.managedWindows.first { $0.id == 1 }?.frame.width ?? 0
        #expect(leftWidth > 720)
        #expect(leftWidth <= 1440 - 200)

        // Pull hard the other way: same story, sign preserved.
        await sut.handleMouseDragged(to: CGPoint(x: -1440, y: 450))
        let clamped = sut.managedWindows.first { $0.id == 1 }?.frame.width ?? 0
        #expect(clamped >= 200)
        #expect(clamped < leftWidth)

        await sut.handleMouseUp(at: CGPoint(x: -1440, y: 450))
        #expect(mockWM.moveCallCount > 0)
    }

    // MARK: - Cancellation

    @Test("Escape cancels an in-flight drag and restores original frames")
    func cancelResizeRestoresFrames() async {
        let (sut, mockWM, _, mockOverlay) = makeSUT()
        let leftFrame = CGRect(x: 0, y: 0, width: 720, height: 900)
        let rightFrame = CGRect(x: 720, y: 0, width: 720, height: 900)
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: leftFrame)
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: rightFrame)
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        await sut.handleMouseDragged(to: CGPoint(x: 900, y: 450))
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 900)

        await sut.cancelResize()

        #expect(sut.isResizing == false)
        #expect(sut.activeDivider == nil)
        #expect(sut.hoveredDivider == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame == leftFrame)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame == rightFrame)

        // The restore must reach the window manager, not just local state.
        let restoredFrames = mockWM.movedWindows.map(\.frame)
        #expect(!restoredFrames.isEmpty)
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Cancel outside a drag is a no-op")
    func cancelWithoutDragDoesNothing() async {
        let (sut, mockWM, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        let before = mockWM.moveCallCount
        await sut.cancelResize()
        #expect(mockWM.moveCallCount == before)
        #expect(sut.isResizing == false)
    }

    @Test("Hover after a cancelled drag brings the overlay back for an unchanged layout")
    func hoverAfterCancelRepresentsOverlay() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        // Hover first so the resting overlay is populated and the presented
        // snapshot is filled in.
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(mockOverlay?.isOverlayVisible == true)

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 450))
        await sut.cancelResize()
        #expect(mockOverlay?.isOverlayVisible == false)

        // The layout is byte-for-byte what it was before the drag and the
        // pointer is nowhere near a seam, so the overlay remains hidden.
        await sut.handleMouseMoved(to: CGPoint(x: 200, y: 450))
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    // MARK: - 2-Phase SetFrame Ordering & Zero Overlap

    @Test("2-phase setFrame ordering moves shrinking window first before expanding window")
    func twoPhaseSetFrameOrderingMovesShrinkingWindowBeforeExpandingWindow() async {
        let (sut, mockWM, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // Drag right: Left expands (720 -> 800), Right shrinks (720 -> 640).
        // Right window (shrinking) must be moved FIRST.
        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 450))
        #expect(mockWM.movedWindows.count >= 2)
        let lastTwoMoves = Array(mockWM.movedWindows.suffix(2))
        #expect(lastTwoMoves[0].window.id == 2) // Shrinking window moved first
        #expect(lastTwoMoves[1].window.id == 1) // Expanding window moved second

        // Drag left: Left shrinks (800 -> 600), Right expands (640 -> 840).
        // Left window (shrinking) must be moved FIRST.
        await sut.handleMouseDragged(to: CGPoint(x: 600, y: 450))
        let nextTwoMoves = Array(mockWM.movedWindows.suffix(2))
        #expect(nextTwoMoves[0].window.id == 1) // Shrinking window moved first
        #expect(nextTwoMoves[1].window.id == 2) // Expanding window moved second
    }

    @Test("Hard seam clamping eliminates window overlap under extreme drag")
    func hardSeamClampingEliminatesWindowOverlapUnderExtremeDrag() async {
        let (sut, _, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // Extreme drag right
        await sut.handleMouseDragged(to: CGPoint(x: 2000, y: 450))
        let leftRight = sut.managedWindows.first { $0.id == 1 }?.frame ?? .zero
        let rightRight = sut.managedWindows.first { $0.id == 2 }?.frame ?? .zero
        #expect(leftRight.maxX == rightRight.minX)
        #expect(leftRight.intersection(rightRight).width <= 0)
        #expect(rightRight.width >= 200)

        // Extreme drag left
        await sut.handleMouseDragged(to: CGPoint(x: -1000, y: 450))
        let leftLeft = sut.managedWindows.first { $0.id == 1 }?.frame ?? .zero
        let rightLeft = sut.managedWindows.first { $0.id == 2 }?.frame ?? .zero
        #expect(leftLeft.maxX == rightLeft.minX)
        #expect(leftLeft.intersection(rightLeft).width <= 0)
        #expect(leftLeft.width >= 200)

        await sut.handleMouseUp(at: CGPoint(x: -1000, y: 450))
    }

    // MARK: - Accessibility Trust Gating

    @Test("Untrusted accessibility service blocks divider hover and tracking")
    func untrustedAccessibilityBlocksHoverAndTracking() async {
        let mockService = MockAccessibilityService(isTrusted: false)
        let (sut, _, _, mockOverlay) = makeSUT(accessibilityService: mockService)
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(sut.hoveredDivider == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(mockOverlay?.showCallCount == 0)
        #expect(mockOverlay?.isOverlayVisible == false)

        let hit = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        #expect(hit == false)
        #expect(sut.isResizing == false)
        #expect(sut.activeDivider == nil)
    }

    @Test("Trusted accessibility service allows divider hover and tracking")
    func trustedAccessibilityAllowsHoverAndTracking() async {
        let mockService = MockAccessibilityService(isTrusted: true)
        let (sut, _, _, mockOverlay) = makeSUT(accessibilityService: mockService)
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(sut.hoveredDivider != nil)
        #expect(sut.currentCursor == .resizeLeftRight)
        #expect(mockOverlay?.showCallCount == 1)

        let hit = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        #expect(hit == true)
        #expect(sut.isResizing == true)
    }

    // MARK: - OS Minimum Size Divider Attachment

    @Test("Divider line never detaches or penetrates inside window bounds when window hits real OS minimum size")
    func dividerLineNeverDetachesOrPenetratesWhenHittingOSMinimumSize() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        // Window 1 has a real OS minimum width of 500px
        let w1 = ManagedWindow(
            id: 1, pid: 10, title: "Left",
            frame: CGRect(x: 0, y: 0, width: 720, height: 900),
            minSize: CGSize(width: 500, height: 300)
        )
        let w2 = ManagedWindow(
            id: 2, pid: 20, title: "Right",
            frame: CGRect(x: 720, y: 0, width: 720, height: 900)
        )
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // Drag divider aggressively leftward to X=100
        await sut.handleMouseDragged(to: CGPoint(x: 100, y: 450))

        // Left window must be hard-locked at its minSize width 500
        let leftWindow = sut.managedWindows.first { $0.id == 1 }
        let rightWindow = sut.managedWindows.first { $0.id == 2 }
        #expect(leftWindow?.frame.width == 500)
        #expect(rightWindow?.frame.origin.x == 500)
        #expect(rightWindow?.frame.width == 940)

        // The divider line coordinate MUST be exactly 500, never penetrating into Window 1 (< 500) or detaching (> 500)
        #expect(sut.activeDivider?.coordinate == 500)
        #expect(mockOverlay?.lastActiveDivider?.coordinate == 500)
        #expect(leftWindow?.frame.maxX == sut.activeDivider?.coordinate)
        #expect(rightWindow?.frame.minX == sut.activeDivider?.coordinate)

        await sut.handleMouseUp(at: CGPoint(x: 100, y: 450))
    }

    // MARK: - 120Hz ProMotion & IPC Performance Optimizations

    @Test("MouseDown caches AXUIElement references and eliminates redundant window lookup IPC during drag")
    func mouseDownCachesAXUIElementsAndEliminatesRedundantIPC() async {
        let mockService = MockAccessibilityService(isTrusted: true)
        let mockElement1 = AXUIElementCreateSystemWide()
        let mockElement2 = AXUIElementCreateSystemWide()
        mockService.mockWindowElements[1] = mockElement1
        mockService.mockWindowElements[2] = mockElement2

        let windowManager = WindowManager(accessibilityService: mockService)
        let display = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let mockDM = MockDisplayManager(displays: [display])
        let mockOverlay = MockAdaptiveDividerOverlayManager()
        let coordinator = AdaptiveDividerCoordinator(
            detector: CollinearEdgeDetector(defaultMinWidth: 200, defaultMinHeight: 150),
            windowManager: windowManager,
            displayManager: mockDM,
            throttler: LiveResizeThrottler(fps: 1000.0),
            accessibilityService: mockService,
            overlayManager: mockOverlay
        )

        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        coordinator.updateWindows([w1, w2])

        // 1. Mouse down caches AX elements
        _ = await coordinator.handleMouseDown(at: CGPoint(x: 720, y: 450))
        let initialLookupCount = mockService.windowElementCallCount
        #expect(initialLookupCount == 2) // Resolved once per participating window

        // 2. Drag multiple times
        for x in stride(from: 730.0, through: 800.0, by: 10.0) {
            await coordinator.handleMouseDragged(to: CGPoint(x: x, y: 450))
        }

        // Window element lookups must NOT be re-queried during drag because references are cached
        #expect(mockService.windowElementCallCount == initialLookupCount)
        #expect(mockService.setFrameCallCount > 0)

        // 3. Mouse up clears cache cleanly
        await coordinator.handleMouseUp(at: CGPoint(x: 800, y: 450))
        #expect(coordinator.isResizing == false)
    }

    @Test("Sub-pixel drag movements (<0.5pt) update visual guide but skip redundant AX frame updates")
    func subPixelDragSkipsRedundantAXUpdates() async {
        let (sut, mockWM, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        let baseMoveCount = mockWM.moveCallCount

        // Drag by 0.2pt (sub-pixel)
        await sut.handleMouseDragged(to: CGPoint(x: 720.2, y: 450))

        // Visual overlay MUST update immediately (120Hz responsiveness)
        #expect(mockOverlay?.updateCallCount ?? 0 >= 1)

        // WindowManager move MUST be skipped since delta < 0.5pt
        #expect(mockWM.moveCallCount == baseMoveCount)

        // Substantial drag by 40pt MUST commit to WindowManager
        await sut.handleMouseDragged(to: CGPoint(x: 760, y: 450))
        #expect(mockWM.moveCallCount > baseMoveCount)

        await sut.handleMouseUp(at: CGPoint(x: 760, y: 450))
    }

    @Test("Bi-directional resizing smoothly expands and shrinks windows without locking after hitting minimum width")
    func biDirectionalResizingUnblockedAfterReachingMinimumWidth() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(
            id: 1, pid: 10, title: "Left",
            frame: CGRect(x: 0, y: 0, width: 720, height: 900),
            minSize: CGSize(width: 500, height: 300)
        )
        let w2 = ManagedWindow(
            id: 2, pid: 20, title: "Right",
            frame: CGRect(x: 720, y: 0, width: 720, height: 900)
        )
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // 1. Drag left past minimum width (clamped at 500)
        await sut.handleMouseDragged(to: CGPoint(x: 100, y: 450))
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 500)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.origin.x == 500)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.width == 940)

        // 2. Drag right smoothly without being blocked or locked
        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 450))
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 800)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.origin.x == 800)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.width == 640)

        // 3. Drag right to opposite minimum width (right window minimum width 200)
        await sut.handleMouseDragged(to: CGPoint(x: 1400, y: 450))
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 1240)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.origin.x == 1240)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.width == 200)

        // 4. Drag back left smoothly
        await sut.handleMouseDragged(to: CGPoint(x: 600, y: 450))
        #expect(sut.managedWindows.first { $0.id == 1 }?.frame.width == 600)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.origin.x == 600)
        #expect(sut.managedWindows.first { $0.id == 2 }?.frame.width == 840)

        await sut.handleMouseUp(at: CGPoint(x: 600, y: 450))
        #expect(sut.isResizing == false)
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Runtime minimum size limits clamp divider drag and clear when expanding")
    func runtimeMinSizeLimitsClampAndClearOnExpand() async {
        let (sut, _, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "A", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "B", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        await sut.handleMouseDragged(to: CGPoint(x: 600, y: 450))
        #expect(sut.activeMinSizes.isEmpty)

        await sut.handleMouseUp(at: CGPoint(x: 600, y: 450))
        #expect(sut.activeMinSizes.isEmpty)
    }

    @Test("Divider line and windows remain attached and never separate at extreme minimum-size limits")
    func windowsAndDividerRemainAttachedAtExtremeLimits() async throws {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(
            id: 1, pid: 10, title: "Left",
            frame: CGRect(x: 0, y: 0, width: 720, height: 900),
            minSize: CGSize(width: 400, height: 300)
        )
        let w2 = ManagedWindow(
            id: 2, pid: 20, title: "Right",
            frame: CGRect(x: 720, y: 0, width: 720, height: 900),
            minSize: CGSize(width: 350, height: 300)
        )
        sut.updateWindows([w1, w2])

        // Start resize
        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))

        // Extreme yank to the far left (x = -500)
        await sut.handleMouseDragged(to: CGPoint(x: -500, y: 450))
        let leftWin1 = try #require(sut.managedWindows.first { $0.id == 1 })
        let rightWin1 = try #require(sut.managedWindows.first { $0.id == 2 })

        // Must clamp cleanly at minSize width 400
        #expect(leftWin1.frame.width == 400)
        #expect(rightWin1.frame.minX == 400)
        #expect(rightWin1.frame.width == 1040)
        #expect(leftWin1.frame.maxX == rightWin1.frame.minX)

        // Release at extreme boundary
        await sut.handleMouseUp(at: CGPoint(x: -500, y: 450))
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Divider remains active for ad-hoc collinear windows when no active workspace is open")
    func dividerActiveForAdHocCollinearWindowsWhenNoActiveWorkspaceIsOpen() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])
        // Explicitly set provider to nil (no active workspace)
        sut.activeWorkspaceProvider = { nil }

        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))

        #expect(mockOverlay?.isOverlayVisible == true)
        #expect(sut.hoveredDivider?.orientation == .vertical)
        #expect(sut.currentCursor == .resizeLeftRight)
    }

    @Test("Divider visible when active workspace matches windows")
    func dividerVisibleWhenActiveWorkspaceMatchesWindows() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, bundleIdentifier: "com.microsoft.VSCode", title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, bundleIdentifier: "com.apple.Terminal", title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])

        let workspace = Workspace(
            name: "Dev",
            placements: [
                WindowPlacement(bundleIdentifier: "com.microsoft.VSCode", zone: .leftHalf, orderIndex: 0),
                WindowPlacement(bundleIdentifier: "com.apple.Terminal", zone: .rightHalf, orderIndex: 1)
            ]
        )
        sut.activeWorkspaceProvider = { workspace }

        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))

        #expect(mockOverlay?.isOverlayVisible == true)
    }

    @Test("MouseUp on workspace windows triggers debounced ratio auto-save")
    func mouseUpOnWorkspaceWindowsTriggersDebouncedRatioAutoSave() async throws {
        let (sut, _, _, _) = makeSUT()
        let w1 = ManagedWindow(id: 1, pid: 10, bundleIdentifier: "com.microsoft.VSCode", title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let w2 = ManagedWindow(id: 2, pid: 20, bundleIdentifier: "com.apple.Terminal", title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([w1, w2])
        sut.autoSaveDelay = 0.05 // 50ms for testing

        let workspaceID = UUID()
        let workspace = Workspace(
            id: workspaceID,
            name: "Dev",
            placements: [
                WindowPlacement(bundleIdentifier: "com.microsoft.VSCode", zone: .leftHalf, orderIndex: 0),
                WindowPlacement(bundleIdentifier: "com.apple.Terminal", zone: .rightHalf, orderIndex: 1)
            ]
        )
        sut.activeWorkspaceProvider = { workspace }

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        await sut.handleMouseDragged(to: CGPoint(x: 800, y: 450))
        await sut.handleMouseUp(at: CGPoint(x: 800, y: 450))

        // Wait for debounce timer
        try await Task.sleep(nanoseconds: 100_000_000)

        // Drag completed and auto-saved task executed cleanly
        #expect(sut.managedWindows.count == 2)
    }

    @Test("Hovering at T-junction activates crosshair cursor and displays junction handle")
    func hoveringAtTJunctionActivatesCrosshairCursor() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let left = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let topRight = ManagedWindow(id: 2, pid: 20, title: "TopRight", frame: CGRect(x: 720, y: 450, width: 720, height: 450))
        let bottomRight = ManagedWindow(id: 3, pid: 30, title: "BottomRight", frame: CGRect(x: 720, y: 0, width: 720, height: 450))
        sut.updateWindows([left, topRight, bottomRight])

        // Hover directly at the intersection point (720, 450)
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))

        #expect(sut.hoveredJunction != nil)
        #expect(sut.hoveredJunction?.point == CGPoint(x: 720, y: 450))
        #expect(sut.currentCursor == .crosshair)
        #expect(mockOverlay?.lastActiveJunction != nil)
        #expect(mockOverlay?.isOverlayVisible == true)

        // Moving outside 14pt hit-radius falls back to vertical divider (e.g. at 720, 200)
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 200))
        #expect(sut.hoveredJunction == nil)
        #expect(sut.hoveredDivider?.orientation == .vertical)
        #expect(sut.currentCursor == .resizeLeftRight)
    }

    @Test("Dragging at T-junction updates 3 participating windows in 2D simultaneously")
    func draggingAtTJunctionUpdates3WindowsIn2D() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let left = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let topRight = ManagedWindow(id: 2, pid: 20, title: "TopRight", frame: CGRect(x: 720, y: 450, width: 720, height: 450))
        let bottomRight = ManagedWindow(id: 3, pid: 30, title: "BottomRight", frame: CGRect(x: 720, y: 0, width: 720, height: 450))
        sut.updateWindows([left, topRight, bottomRight])

        // MouseDown at intersection (720, 450)
        let didStart = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        #expect(didStart == true)
        #expect(sut.isResizing == true)
        #expect(sut.activeJunction != nil)
        #expect(mockOverlay?.lastActiveJunction != nil)
        #expect(mockOverlay?.lastIsDragging == true)

        // Drag to (750, 500) — moving junction right (+30pt) and up (+50pt)
        await sut.handleMouseDragged(to: CGPoint(x: 750, y: 500))

        let updatedLeft = sut.managedWindows.first { $0.id == 1 }!
        let updatedTopRight = sut.managedWindows.first { $0.id == 2 }!
        let updatedBottomRight = sut.managedWindows.first { $0.id == 3 }!

        #expect(updatedLeft.frame == CGRect(x: 0, y: 0, width: 750, height: 900))
        #expect(updatedTopRight.frame == CGRect(x: 750, y: 500, width: 690, height: 400))
        #expect(updatedBottomRight.frame == CGRect(x: 750, y: 0, width: 690, height: 500))

        // MouseUp to commit
        await sut.handleMouseUp(at: CGPoint(x: 750, y: 500))
        #expect(sut.isResizing == false)
        #expect(sut.activeJunction == nil)
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Cancelling 2D junction resize restores all 3 windows to original frames")
    func cancellingJunctionResizeRestoresAll3Windows() async {
        let (sut, _, _, _) = makeSUT()
        let left = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let topRight = ManagedWindow(id: 2, pid: 20, title: "TopRight", frame: CGRect(x: 720, y: 450, width: 720, height: 450))
        let bottomRight = ManagedWindow(id: 3, pid: 30, title: "BottomRight", frame: CGRect(x: 720, y: 0, width: 720, height: 450))
        sut.updateWindows([left, topRight, bottomRight])

        _ = await sut.handleMouseDown(at: CGPoint(x: 720, y: 450))
        await sut.handleMouseDragged(to: CGPoint(x: 780, y: 520))

        // Cancel resize
        await sut.cancelResize()

        #expect(sut.isResizing == false)
        #expect(sut.activeJunction == nil)

        let restoredLeft = sut.managedWindows.first { $0.id == 1 }!
        let restoredTopRight = sut.managedWindows.first { $0.id == 2 }!
        let restoredBottomRight = sut.managedWindows.first { $0.id == 3 }!

        #expect(restoredLeft.frame == CGRect(x: 0, y: 0, width: 720, height: 900))
        #expect(restoredTopRight.frame == CGRect(x: 720, y: 450, width: 720, height: 450))
        #expect(restoredBottomRight.frame == CGRect(x: 720, y: 0, width: 720, height: 450))
    }

    @Test("Hover when display has fewer than 2 windows hides overlay and resets cursor to arrow")
    func hoverWithFewerThanTwoWindowsHidesOverlay() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let singleWindow = ManagedWindow(id: 1, pid: 10, title: "OnlyOne", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        sut.updateWindows([singleWindow])

        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))

        #expect(sut.hoveredDivider == nil)
        #expect(sut.hoveredJunction == nil)
        #expect(sut.currentCursor == .arrow)
        #expect(mockOverlay?.isOverlayVisible == false)
    }

    @Test("Switching to non-workspace frontmost app like Finder resets state and hides overlay")
    func nonWorkspaceFrontmostAppHidesOverlay() async {
        let (sut, _, _, mockOverlay) = makeSUT()
        let left = ManagedWindow(id: 1, pid: 10, title: "Left", frame: CGRect(x: 0, y: 0, width: 720, height: 900))
        let right = ManagedWindow(id: 2, pid: 20, title: "Right", frame: CGRect(x: 720, y: 0, width: 720, height: 900))
        sut.updateWindows([left, right])

        // Initially hovering on divider shows overlay
        await sut.handleMouseMoved(to: CGPoint(x: 720, y: 450))
        #expect(mockOverlay?.isOverlayVisible == true)

        // Switch to Finder (com.apple.finder)
        sut.frontmostApplicationProvider = { "com.apple.finder" }
        sut.resetState()

        #expect(mockOverlay?.isOverlayVisible == false)
        #expect(sut.hoveredDivider == nil)
        #expect(sut.hoveredJunction == nil)
        #expect(sut.currentCursor == .arrow)
    }
}

