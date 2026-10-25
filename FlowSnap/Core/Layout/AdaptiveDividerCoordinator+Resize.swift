import AppKit
import ApplicationServices
import CoreGraphics
import Foundation
import OSLog

extension AdaptiveDividerCoordinator {

    // MARK: - Drag & Resize

    public func handleMouseDown(at point: CGPoint) async -> Bool {
        // BUG-01: guard against dual-trigger (overlay callback + global downMonitor both fire)
        guard !isResizing else { return false }

        if let service = accessibilityService, !service.isTrusted {
            return false
        }

        // PERF-02+03: resolve gap and primaryHeight once at mouseDown and cache them.
        // Both values are constant for the lifetime of the drag session.
        let gap = resolveGap()
        dragGap = gap
        dragPrimaryHeight = await displayManager.primaryScreenHeight
        let container = await resolveContainer(at: point)
        if isWorkspaceRestrictionEnabled && currentActiveWorkspace != nil && !managedWindows.isEmpty {
            let belongsToWorkspaceScreen = managedWindows.contains { win in
                let intersection = win.frame.intersection(container)
                return !intersection.isNull && intersection.width > 20 && intersection.height > 20
            }
            if !belongsToWorkspaceScreen { return false }
        }
        if isNonWorkspaceAppFrontmost {
            return false
        }
        let displayWindows = filterWindows(for: container)
        let dividers = cachedDividers(for: displayWindows, container: container, gap: gap)
        let junctions = detector.detectJunctions(in: dividers, tolerance: max(gap + 12.0, 16.0))

        if let junction = detector.hitTestJunction(at: point, in: junctions) {
            guard !isPointOccluded(point, forParticipatingWindowIDs: junction.participatingWindowIDs) else {
                return false
            }
            activeJunction = junction
            activeDivider = nil
            dragDividers = dividers
            dragContainer = container
            isResizing = true
            var initMap: [CGWindowID: ManagedWindow] = [:]
            for w in displayWindows {
                initMap[w.id] = w
            }
            self.initialWindows = initMap
            self.lastCommittedFrames = initMap.mapValues { $0.frame }
            self.activeMinSizes.removeAll()

            cachedAXElements.removeAll()
            if let service = accessibilityService {
                for w in displayWindows {
                    if let element = service.windowElement(for: w) {
                        cachedAXElements[w.id] = element
                    }
                }
            }

            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: nil,
                activeJunction: junction,
                isDragging: true
            )
            dividerLogger.debug("Started junction resize session at \(junction.point.x, privacy: .public),\(junction.point.y, privacy: .public)")
            return true
        }

        guard let divider = detector.hitTestDivider(at: point, in: dividers) else {
            return false
        }
        guard !isPointOccluded(point, forParticipatingWindowIDs: divider.leadingWindowIDs + divider.trailingWindowIDs) else {
            return false
        }

        activeDivider = divider
        activeJunction = nil
        dragDividers = dividers
        // BUG-03: lock container to the display where drag started
        dragContainer = container
        isResizing = true
        var initMap: [CGWindowID: ManagedWindow] = [:]
        for w in displayWindows {
            initMap[w.id] = w
        }
        self.initialWindows = initMap
        self.lastCommittedFrames = initMap.mapValues { $0.frame }
        self.activeMinSizes.removeAll()

        // Cache AXUIElement references at mouseDown to eliminate redundant IPC lookups during drag
        cachedAXElements.removeAll()
        if let service = accessibilityService {
            for w in displayWindows {
                if let element = service.windowElement(for: w) {
                    cachedAXElements[w.id] = element
                }
            }
        }

        overlayManager?.show(
            containerFrame: container,
            windows: displayWindows,
            dividers: dividers,
            activeDivider: divider,
            activeJunction: nil,
            isDragging: true
        )
        dividerLogger.debug("Started divider resize session on \(divider.orientation.rawValue, privacy: .public) divider at \(divider.coordinate, privacy: .public)")
        return true
    }

    /// Injects dynamic minimum size limits into windows so geometric computations clamp appropriately.
    func preparedWindowsForResize(_ windows: [ManagedWindow]) -> [ManagedWindow] {
        guard !activeMinSizes.isEmpty else { return windows }
        return windows.map { window in
            guard let dynamicMin = activeMinSizes[window.id] else { return window }
            var updated = window
            if let existing = window.minSize {
                updated.minSize = CGSize(
                    width: max(existing.width, dynamicMin.width),
                    height: max(existing.height, dynamicMin.height)
                )
            } else {
                updated.minSize = dynamicMin
            }
            return updated
        }
    }

    /// Clears dynamic minimum size constraints when dragging back in the expanding direction.
    func updateActiveMinSizes(with resizedFrames: [CGWindowID: CGRect], orientation: DividerOrientation) {
        for (id, minSize) in activeMinSizes {
            guard let frame = resizedFrames[id] else { continue }
            switch orientation {
            case .vertical:
                if frame.width > minSize.width + 1 {
                    activeMinSizes.removeValue(forKey: id)
                }
            case .horizontal:
                if frame.height > minSize.height + 1 {
                    activeMinSizes.removeValue(forKey: id)
                }
            }
        }
    }

    public func handleMouseDragged(to point: CGPoint) async {
        guard isResizing else { return }
        if let junction = activeJunction {
            await handleJunctionMouseDragged(to: point, junction: junction)
            return
        }
        guard let divider = activeDivider else { return }

        // PERF-02: use gap cached at mouseDown — no async lookup needed
        let gap = dragGap
        // BUG-03: use the container locked at mouseDown to prevent display-crossing instability
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        let targetCoordinate = (divider.orientation == .vertical) ? point.x : point.y
        let resizedFrames = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        // 1. Where the seam is actually allowed to end up
        let clampedCoordinate: CGFloat
        if let calculatedSeam = seamCoordinate(from: resizedFrames, for: divider, gap: gap) {
            clampedCoordinate = calculatedSeam
        } else {
            clampedCoordinate = (max(divider.minCoordinate, min(divider.maxCoordinate, targetCoordinate))).rounded()
        }
        let draggedDivider = seam(byMoving: divider, to: clampedCoordinate, gap: gap)

        // 2. Real-time preview frames for visual overlay
        var previewWindows: [ManagedWindow] = []
        for var window in displayWindows {
            if let newFrame = resizedFrames[window.id] {
                var stableFrame = newFrame
                if let initial = initialWindows[window.id] {
                    if divider.orientation == .vertical {
                        stableFrame.origin.y = initial.frame.origin.y
                        stableFrame.size.height = initial.frame.size.height
                    } else {
                        stableFrame.origin.x = initial.frame.origin.x
                        stableFrame.size.width = initial.frame.size.width
                    }
                }
                window.frame = stableFrame
            }
            previewWindows.append(window)
        }

        // 3. Real-time visual overlay update (120Hz ProMotion responsiveness)
        var overlayDividers = overlaySet(from: dragDividers, dragging: divider, to: draggedDivider)
        activeDivider = draggedDivider

        let now = ProcessInfo.processInfo.systemUptime
        if throttler.shouldProcess(timestamp: now) {
            let refreshed = detector.detectDividers(
                in: previewWindows, containerFrame: container, gap: gap, tolerance: max(gap + 16.0, 24.0)
            )
            if !refreshed.isEmpty {
                dragDividers = refreshed
                overlayDividers = overlaySet(from: refreshed, dragging: divider, to: draggedDivider)
            }
        }

        overlayManager?.update(
            containerFrame: container,
            windows: previewWindows,
            dividers: overlayDividers,
            activeDivider: draggedDivider,
            isDragging: true
        )

        // PERF-03: use primaryHeight cached at mouseDown — no DisplayManager round-trip per event
        await applyResizedFrames(resizedFrames, primaryHeight: dragPrimaryHeight)
    }

    func handleJunctionMouseDragged(to point: CGPoint, junction: CrossJunction) async {
        let gap = dragGap
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        let resizedFrames = detector.compute2DResizedFrames(
            for: junction,
            targetPoint: point,
            in: dragDividers,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        let vDivider = dragDividers.first(where: { isSameSeam($0, as: junction.verticalDivider) }) ?? junction.verticalDivider
        let hDivider = dragDividers.first(where: { isSameSeam($0, as: junction.horizontalDivider) }) ?? junction.horizontalDivider

        let clampedX = seamCoordinate(from: resizedFrames, for: vDivider, gap: gap)
            ?? max(vDivider.minCoordinate, min(vDivider.maxCoordinate, point.x)).rounded()
        let clampedY = seamCoordinate(from: resizedFrames, for: hDivider, gap: gap)
            ?? max(hDivider.minCoordinate, min(hDivider.maxCoordinate, point.y)).rounded()

        let draggedPoint = CGPoint(x: clampedX, y: clampedY)
        let draggedVDivider = seam(byMoving: vDivider, to: clampedX, gap: gap)
        let draggedHDivider = seam(byMoving: hDivider, to: clampedY, gap: gap)

        let draggedJunction = CrossJunction(
            id: junction.id,
            point: draggedPoint,
            verticalDivider: draggedVDivider,
            horizontalDivider: draggedHDivider,
            hitRadius: junction.hitRadius,
            participatingWindowIDs: junction.participatingWindowIDs
        )
        activeJunction = draggedJunction

        var previewWindows: [ManagedWindow] = []
        for var window in displayWindows {
            if let newFrame = resizedFrames[window.id] {
                window.frame = newFrame
            }
            previewWindows.append(window)
        }

        var overlayDividers = overlaySet(from: dragDividers, dragging: vDivider, to: draggedVDivider)
        overlayDividers = overlaySet(from: overlayDividers, dragging: hDivider, to: draggedHDivider)

        let now = ProcessInfo.processInfo.systemUptime
        if throttler.shouldProcess(timestamp: now) {
            let refreshed = detector.detectDividers(
                in: previewWindows, containerFrame: container, gap: gap, tolerance: max(gap + 16.0, 24.0)
            )
            if !refreshed.isEmpty {
                dragDividers = refreshed
                overlayDividers = overlaySet(from: refreshed, dragging: vDivider, to: draggedVDivider)
                overlayDividers = overlaySet(from: overlayDividers, dragging: hDivider, to: draggedHDivider)
            }
        }

        overlayManager?.update(
            containerFrame: container,
            windows: previewWindows,
            dividers: overlayDividers,
            activeDivider: nil,
            activeJunction: draggedJunction,
            isDragging: true
        )

        updateActiveMinSizes(with: resizedFrames, orientation: .vertical)
        updateActiveMinSizes(with: resizedFrames, orientation: .horizontal)
        await applyResizedFrames(resizedFrames, primaryHeight: dragPrimaryHeight)
    }

    public func handleMouseUp(at point: CGPoint) async {
        guard isResizing else { return }
        if let junction = activeJunction {
            await handleJunctionMouseUp(at: point, junction: junction)
            return
        }
        guard let divider = activeDivider else { return }
        dividerLogger.debug("Ended divider resize session with final snap")
        // PERF-02+03: use values cached at mouseDown
        let gap = dragGap
        // BUG-03: keep container consistent with drag session
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        // BUG-04: use the already-clamped divider.coordinate rather than raw mouse point
        // to prevent a 1-2pt jump between the live preview position and final committed frame.
        let targetCoordinate = divider.coordinate
        let resizedFrames = detector.computeResizedFrames(
            for: divider,
            targetCoordinate: targetCoordinate,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        let primaryHeight = dragPrimaryHeight
        await applyResizedFrames(resizedFrames, primaryHeight: primaryHeight, force: true)

        isResizing = false
        activeDivider = nil
        hoveredDivider = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        throttler.reset()
        setCursor(.arrow)

        // BUG-02: re-sync managedWindows with actual AX frames so the next drag
        // session starts from correct geometry (prevents X-axis drift on repeated horizontal drags).
        dividerCache = nil
        await refreshWindowsIfNeeded()

        let finalDisplayWindows = filterWindows(for: container)
        let finalDividers = cachedDividers(for: finalDisplayWindows, container: container, gap: gap)
        lastPresentedDividers = finalDividers
        lastPresentedWindows = finalDisplayWindows
        lastPresentedContainer = container

        // Auto-save customized ratio to the active workspace after autoSaveDelay (5 minutes)
        if let workspace = currentActiveWorkspace {
            var updatedNormalizedRects: [String: CGRect] = [:]
            for window in finalDisplayWindows {
                if let bundleID = window.bundleIdentifier {
                    let normRect = ZoneInference.normalizedRect(of: window.frame, within: container)
                    updatedNormalizedRects[bundleID] = normRect
                }
            }
            if !updatedNormalizedRects.isEmpty {
                ratioAutoSaveTask?.cancel()
                let delay = self.autoSaveDelay
                let targetWorkspaceID = workspace.id
                ratioAutoSaveTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    guard !Task.isCancelled, let self else { return }
                    try? await self.workspaceManager?.updateWorkspaceRatios(
                        workspaceID: targetWorkspaceID,
                        normalizedRects: updatedNormalizedRects
                    )
                }
            }
        }

        overlayManager?.hide(animated: true)
    }

    func handleJunctionMouseUp(at point: CGPoint, junction: CrossJunction) async {
        dividerLogger.debug("Ended junction resize session with final snap")
        let gap = dragGap
        let container: CGRect
        if let locked = dragContainer {
            container = locked
        } else {
            container = await resolveContainer(at: point)
        }
        let displayWindows = filterWindows(for: container)
        let baseWindows = initialWindows.isEmpty ? displayWindows : Array(initialWindows.values)
        let windowsToResize = preparedWindowsForResize(baseWindows.isEmpty ? managedWindows : baseWindows)

        let targetPoint = junction.point
        let resizedFrames = detector.compute2DResizedFrames(
            for: junction,
            targetPoint: targetPoint,
            in: dragDividers,
            windows: windowsToResize,
            containerFrame: container,
            gap: gap
        )

        let primaryHeight = dragPrimaryHeight
        await applyResizedFrames(resizedFrames, primaryHeight: primaryHeight, force: true)

        isResizing = false
        activeJunction = nil
        activeDivider = nil
        hoveredJunction = nil
        hoveredDivider = nil
        dragDividers = []
        initialWindows.removeAll()
        dragContainer = nil
        cachedAXElements.removeAll()
        lastCommittedFrames.removeAll()
        activeMinSizes.removeAll()
        throttler.reset()
        setCursor(.arrow)

        dividerCache = nil
        await refreshWindowsIfNeeded()

        let finalDisplayWindows = filterWindows(for: container)
        let finalDividers = cachedDividers(for: finalDisplayWindows, container: container, gap: gap)
        lastPresentedDividers = finalDividers
        lastPresentedWindows = finalDisplayWindows
        lastPresentedContainer = container

        if let workspace = currentActiveWorkspace {
            var updatedNormalizedRects: [String: CGRect] = [:]
            for window in finalDisplayWindows {
                if let bundleID = window.bundleIdentifier {
                    let normRect = ZoneInference.normalizedRect(of: window.frame, within: container)
                    updatedNormalizedRects[bundleID] = normRect
                }
            }
            if !updatedNormalizedRects.isEmpty {
                ratioAutoSaveTask?.cancel()
                let delay = self.autoSaveDelay
                let targetWorkspaceID = workspace.id
                ratioAutoSaveTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    guard !Task.isCancelled, let self else { return }
                    try? await self.workspaceManager?.updateWorkspaceRatios(
                        workspaceID: targetWorkspaceID,
                        normalizedRects: updatedNormalizedRects
                    )
                }
            }
        }

        overlayManager?.hide(animated: true)
    }

    /// Dispatches resized frames to WindowManager using a 2-phase ordering:
    /// Shrinking windows first to free up space, followed by Expanding windows.
    func applyResizedFrames(
        _ resizedFrames: [CGWindowID: CGRect],
        primaryHeight: CGFloat,
        force: Bool = false
    ) async {
        var updates: [(window: ManagedWindow, stableFrame: CGRect, isShrinking: Bool)] = []
        for (id, frame) in resizedFrames {
            guard let index = managedWindows.firstIndex(where: { $0.id == id }) else { continue }
            let currentWindow = managedWindows[index]

            var stableFrame = frame
            if let initial = initialWindows[id] {
                if let activeDivider, activeDivider.orientation == .vertical {
                    stableFrame.origin.y = initial.frame.origin.y
                    stableFrame.size.height = initial.frame.size.height
                } else if let activeDivider, activeDivider.orientation == .horizontal {
                    stableFrame.origin.x = initial.frame.origin.x
                    stableFrame.size.width = initial.frame.size.width
                }
            }
            stableFrame.origin.x = stableFrame.origin.x.rounded()
            stableFrame.origin.y = stableFrame.origin.y.rounded()
            stableFrame.size.width = stableFrame.size.width.rounded()
            stableFrame.size.height = stableFrame.size.height.rounded()

            // Skip redundant sub-pixel AX frame updates (< 0.5pt delta)
            if !force, let lastFrame = lastCommittedFrames[id] {
                let dx = abs(lastFrame.origin.x - stableFrame.origin.x)
                let dy = abs(lastFrame.origin.y - stableFrame.origin.y)
                let dw = abs(lastFrame.width - stableFrame.width)
                let dh = abs(lastFrame.height - stableFrame.height)
                if dx < 0.5 && dy < 0.5 && dw < 0.5 && dh < 0.5 {
                    continue
                }
            }

            // BUG-08: compare the relevant dimension rather than area so that windows
            // with extreme aspect ratios are ordered correctly in the 2-phase dispatch.
            let isShrinking: Bool
            if let activeDivider {
                switch activeDivider.orientation {
                case .vertical:
                    isShrinking = stableFrame.width <= currentWindow.frame.width
                case .horizontal:
                    isShrinking = stableFrame.height <= currentWindow.frame.height
                }
            } else {
                isShrinking = (stableFrame.width * stableFrame.height)
                    <= (currentWindow.frame.width * currentWindow.frame.height)
            }
            updates.append((window: currentWindow, stableFrame: stableFrame, isShrinking: isShrinking))
        }

        guard !updates.isEmpty else { return }
        let sortedUpdates = updates.sorted { ($0.isShrinking ? 0 : 1) < ($1.isShrinking ? 0 : 1) }

        // PERF-04: separate AX writes from registry updates so actor hops do not multiply
        // with window count. Perform all AX writes first (order-sensitive), then batch
        // the registry updates in a single pass.
        var updatedWindowsForRegistry: [ManagedWindow] = []

        for update in sortedUpdates {
            if let index = managedWindows.firstIndex(where: { $0.id == update.window.id }) {
                var updatedWindow = managedWindows[index]
                updatedWindow.frame = update.stableFrame
                managedWindows[index] = updatedWindow
                lastCommittedFrames[update.window.id] = update.stableFrame

                let axFrame = CoordinateTransformer.toAX(rect: update.stableFrame, primaryScreenHeight: primaryHeight)
                let element = cachedAXElements[update.window.id]
                try? await windowManager.move(updatedWindow, to: axFrame, element: element)
                // Only shrinking windows can hit a minimum size constraint.
                // Skipping AX readback on expanding windows eliminates ~50% of IPC latency per frame.
                if update.isShrinking {
                    syncActualWindowFrame(for: &updatedWindow, at: index, requested: update.stableFrame, primaryHeight: primaryHeight, cachedElement: element)
                }
                updatedWindowsForRegistry.append(updatedWindow)
            }
        }

        // Batch registry updates after all AX writes complete.
        if let registry = windowRegistry {
            for window in updatedWindowsForRegistry {
                await registry.update(window)
            }
        }
    }

    func syncActualWindowFrame(
        for updatedWindow: inout ManagedWindow,
        at index: Int,
        requested: CGRect,
        primaryHeight: CGFloat,
        cachedElement: AXUIElement?
    ) {
        guard let service = accessibilityService,
              let axElement = cachedElement ?? service.windowElement(for: updatedWindow),
              let actualAXFrame = service.frame(of: axElement) else { return }
        let actualAppKitFrame = CoordinateTransformer.toAppKit(rect: actualAXFrame, primaryScreenHeight: primaryHeight)
        if actualAppKitFrame.width > requested.width + 2 || actualAppKitFrame.height > requested.height + 2 {
            let clampedMinSize = CGSize(
                width: max(activeMinSizes[updatedWindow.id]?.width ?? 0, actualAppKitFrame.width),
                height: max(activeMinSizes[updatedWindow.id]?.height ?? 0, actualAppKitFrame.height)
            )
            activeMinSizes[updatedWindow.id] = clampedMinSize
        }
        if actualAppKitFrame.width > requested.width + 1 || actualAppKitFrame.height > requested.height + 1 {
            updatedWindow.frame = actualAppKitFrame
            lastCommittedFrames[updatedWindow.id] = actualAppKitFrame
            managedWindows[index] = updatedWindow
        }
    }

    // MARK: - Cancellation

    public func cancelResize() async {
        guard isResizing else { return }
        flushPendingDrag()
        dividerLogger.debug("Divider resize cancelled; restoring \(self.initialWindows.count, privacy: .public) windows")

        // Use cached primaryHeight if available (drag was cancelled mid-session), else fetch fresh.
        let primaryHeight = dragPrimaryHeight > 0 ? dragPrimaryHeight : await displayManager.primaryScreenHeight
        for (id, original) in initialWindows {
            guard let index = managedWindows.firstIndex(where: { $0.id == id }) else { continue }
            var window = managedWindows[index]
            guard window.frame != original.frame else { continue }

            window.frame = original.frame
            managedWindows[index] = window
            let axFrame = CoordinateTransformer.toAX(rect: original.frame, primaryScreenHeight: primaryHeight)
            let element = cachedAXElements[id]
            try? await windowManager.move(window, to: axFrame, element: element)
            await windowRegistry?.update(window)
        }

        dragContainer = nil
        endSession()
    }

    /// Tears down drag state without committing anything.
    func endSession() {
        flushPendingDrag()
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
        throttler.reset()
        dividerCache = nil
        lastPresentedDividers = []
        lastPresentedWindows = []
        lastPresentedContainer = nil
        setCursor(.arrow)
        // BUG-07: clear overlay view state so no phantom dividers survive after cancel
        if let panel = overlayManager as? AdaptiveDividerOverlayPanel {
            panel.overlayView.updateState(
                containerFrame: .zero, windows: [], dividers: [],
                activeDivider: nil, activeJunction: nil, isDragging: false
            )
        }
        overlayManager?.hide(animated: true)
    }
}
