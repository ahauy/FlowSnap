import AppKit
import Combine
import CoreGraphics
import Foundation
import OSLog

extension AdaptiveDividerCoordinator {

    // MARK: - Lifecycle

    public func start() {
        guard !isTracking else { return }
        isTracking = true
        dividerLogger.debug("Starting AdaptiveDividerCoordinator global monitors")

        if let overlayPanel = overlayManager as? AdaptiveDividerOverlayPanel {
            overlayPanel.overlayView.onDirectMouseDown = { [weak self] pt, _ in self?.triggerMouseDown(at: pt) }
            overlayPanel.overlayView.onDirectMouseDragged = { [weak self] pt in self?.scheduleDragTask(to: pt) }
            overlayPanel.overlayView.onDirectMouseUp = { [weak self] pt in self?.triggerMouseUp(at: pt) }
            overlayPanel.overlayView.onDirectMouseMoved = { [weak self] pt in self?.triggerMouseMoved(at: pt) }
        }
        moveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.triggerMouseMoved(at: NSEvent.mouseLocation)
        }
        downMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.triggerMouseDown(at: NSEvent.mouseLocation)
        }
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDragged) { [weak self] _ in
            self?.scheduleDragTask(to: NSEvent.mouseLocation)
        }
        upMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseUp) { [weak self] _ in
            self?.triggerMouseUp(at: NSEvent.mouseLocation)
        }
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return }
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                await self.cancelResize()
            }
        }
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.isTracking else { return }
            if self.isNonWorkspaceAppFrontmost {
                self.resetState()
            }
        }
        appTerminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isTracking else { return }
                await self.refreshWindowsIfNeeded()
                if self.managedWindows.count < 2 {
                    self.resetState()
                }
            }
        }
        if let workspaceManager {
            workspaceCancellable = workspaceManager.$activeWorkspace
                .dropFirst()
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        guard let self, self.isTracking else { return }
                        self.resetState()
                    }
                }
        }
    }

    func triggerMouseMoved(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self, self.isTracking else { return }
            if let service = self.accessibilityService, !service.isTrusted { return }
            await self.refreshWindowsIfNeeded()
            await self.handleMouseMoved(to: point)
        }
    }

    func triggerMouseDown(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self, self.isTracking else { return }
            if let service = self.accessibilityService, !service.isTrusted { return }
            await self.refreshWindowsIfNeeded()
            _ = await self.handleMouseDown(at: point)
        }
    }

    func triggerMouseUp(at point: CGPoint) {
        Task { @MainActor [weak self] in
            guard let self, self.isTracking else { return }
            if let service = self.accessibilityService, !service.isTrusted { return }
            await self.handleMouseUp(at: point)
        }
    }

    public func stop() {
        guard isTracking else { return }
        dividerLogger.debug("Stopping AdaptiveDividerCoordinator global monitors")
        if let moveMonitor { NSEvent.removeMonitor(moveMonitor); self.moveMonitor = nil }
        if let downMonitor { NSEvent.removeMonitor(downMonitor); self.downMonitor = nil }
        if let dragMonitor { NSEvent.removeMonitor(dragMonitor); self.dragMonitor = nil }
        if let upMonitor { NSEvent.removeMonitor(upMonitor); self.upMonitor = nil }
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor); self.keyMonitor = nil }
        if let appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appActivationObserver)
            self.appActivationObserver = nil
        }
        if let appTerminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appTerminationObserver)
            self.appTerminationObserver = nil
        }
        workspaceCancellable?.cancel()
        workspaceCancellable = nil
        flushPendingDrag()
        isTracking = false
        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        activeJunction = nil
        hoveredJunction = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        dragGap = 0
        dragPrimaryHeight = 0
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        dividerCache = nil
        allVisibleWindows.removeAll()
        lastPresentedDividers = []
        lastPresentedWindows = []
        lastPresentedContainer = nil
        setCursor(.arrow)
        // BUG-07: clear overlay view state so phantom hit-areas cannot survive a restart
        if let panel = overlayManager as? AdaptiveDividerOverlayPanel {
            panel.overlayView.updateState(
                containerFrame: .zero, windows: [], dividers: [],
                activeDivider: nil, activeJunction: nil, isDragging: false
            )
        }
        overlayManager?.hide(animated: false)
    }

    /// Coalesces high-frequency mouse drag events to ensure smooth 120Hz tracking without queuing lag.
    ///
    /// **Work-loop invariant (PERF-01):** `isDragScheduled` stays `true` until the loop has fully
    /// drained all pending points. This guarantees that only ONE `handleMouseDragged` call is
    /// in-flight at any moment, regardless of cursor speed. Incoming events during an AX round-trip
    /// only update `pendingDragPoint` (latest wins); they never spawn a new concurrent task.
    func scheduleDragTask(to point: CGPoint) {
        pendingDragPoint = point
        guard !isDragScheduled else { return }
        isDragScheduled = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            while let targetPoint = self.pendingDragPoint {
                self.pendingDragPoint = nil
                guard self.isTracking else { break }
                if let service = self.accessibilityService, !service.isTrusted { break }
                await self.handleMouseDragged(to: targetPoint)
            }
            // Only cleared once the queue is fully drained — prevents re-entry during AX await.
            self.isDragScheduled = false
        }
    }

    func flushPendingDrag() {
        pendingDragPoint = nil
        isDragScheduled = false
    }
}
