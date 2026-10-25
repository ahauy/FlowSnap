import ApplicationServices
import CoreGraphics
import Foundation

extension AdaptiveDividerCoordinator {

    // MARK: - Window Management

    public func updateWindows(_ windows: [ManagedWindow]) {
        updateWindows(windows, allVisibleWindows: windows)
    }

    public func updateWindows(_ windows: [ManagedWindow], allVisibleWindows: [ManagedWindow]?) {
        self.managedWindows = windows
        self.allVisibleWindows = allVisibleWindows ?? windows
    }

    func refreshWindowsIfNeeded() async {
        if isResizing { return }
        guard accessibilityService != nil || windowRegistry != nil else { return }
        if isWorkspaceRestrictionEnabled, let activeWorkspace = currentActiveWorkspace {
            if let service = accessibilityService, !service.isTrusted { return }
            let workspaceBundleIDs = Set(activeWorkspace.placements.map { $0.bundleIdentifier.lowercased() })
            if let service = accessibilityService {
                let visible = service.allVisibleManagedWindows()
                self.allVisibleWindows = visible
                let filtered = visible.filter { window in
                    guard let id = window.bundleIdentifier?.lowercased() else { return false }
                    return workspaceBundleIDs.contains(id)
                }
                if filtered.count >= 2 {
                    self.managedWindows = filtered
                    return
                }
            }
            if let registry = windowRegistry {
                let tracked = await registry.allWindows
                self.allVisibleWindows = tracked
                let filtered = tracked.filter { window in
                    guard let id = window.bundleIdentifier?.lowercased() else { return false }
                    return workspaceBundleIDs.contains(id)
                }
                if filtered.count >= 2 {
                    self.managedWindows = filtered
                    return
                }
            }
            self.managedWindows = []
            self.allVisibleWindows = []
            self.dividerCache = nil
            return
        }

        if let service = accessibilityService, !service.isTrusted { return }
        if let service = accessibilityService {
            let visible = service.allVisibleManagedWindows()
            self.allVisibleWindows = visible
            if visible.count >= 2 {
                self.managedWindows = visible
                return
            }
        }
        if let registry = windowRegistry {
            let tracked = await registry.allWindows
            self.allVisibleWindows = tracked
            if tracked.count >= 2 {
                self.managedWindows = tracked
                return
            }
        }
        self.managedWindows = []
        self.allVisibleWindows = []
        self.dividerCache = nil
    }

    func resolveContainer(at point: CGPoint) async -> CGRect {
        let display = await displayManager.display(containing: point)
        if let display {
            return display.visibleFrame
        }
        let primary = await displayManager.primaryDisplay
        return primary?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    /// Returns the window gap from PreferencesStore synchronously.
    /// `preferencesStore.windowGap` is a `@MainActor` `@AppStorage` property — no actual async
    /// work occurs; the `async` annotation was a no-op causing spurious context-switches.
    func resolveGap() -> CGFloat {
        preferencesStore?.windowGap ?? 0
    }

    func filterWindows(for container: CGRect) -> [ManagedWindow] {
        let sourceWindows = (isResizing && !initialWindows.isEmpty) ? Array(initialWindows.values) : managedWindows
        return sourceWindows.filter { window in
            let intersection = window.frame.intersection(container)
            return !intersection.isNull && intersection.width > 20 && intersection.height > 20
        }
    }

    /// Computes the exact seam coordinate directly from the resized window frames,
    /// ensuring the divider line never detaches or penetrates inside window bounds.
    func seamCoordinate(
        from resizedFrames: [CGWindowID: CGRect],
        for divider: CollinearEdge,
        gap: CGFloat
    ) -> CGFloat? {
        guard !resizedFrames.isEmpty else { return nil }
        let halfGap = gap / 2.0
        switch divider.orientation {
        case .vertical:
            let leadingMaxX = divider.leadingWindowIDs.compactMap { resizedFrames[$0]?.maxX }.max()
            let trailingMinX = divider.trailingWindowIDs.compactMap { resizedFrames[$0]?.minX }.min()
            if let lMaxX = leadingMaxX, let tMinX = trailingMinX {
                return ((lMaxX + tMinX) / 2.0).rounded()
            } else if let lMaxX = leadingMaxX {
                return (lMaxX + halfGap).rounded()
            } else if let tMinX = trailingMinX {
                return (tMinX - halfGap).rounded()
            }
        case .horizontal:
            let leadingMaxY = divider.leadingWindowIDs.compactMap { resizedFrames[$0]?.maxY }.max()
            let trailingMinY = divider.trailingWindowIDs.compactMap { resizedFrames[$0]?.minY }.min()
            if let lMaxY = leadingMaxY, let tMinY = trailingMinY {
                return ((lMaxY + tMinY) / 2.0).rounded()
            } else if let lMaxY = leadingMaxY {
                return (lMaxY + halfGap).rounded()
            } else if let tMinY = trailingMinY {
                return (tMinY - halfGap).rounded()
            }
        }
        return nil
    }

    /// Translates a pinned divider to a new seam coordinate while preserving hitRect span and limits.
    func seam(
        byMoving reference: CollinearEdge,
        to coordinate: CGFloat,
        gap: CGFloat
    ) -> CollinearEdge {
        guard coordinate != reference.coordinate else { return reference }

        let captureWidth = max(18.0, gap + 16.0)
        let hitRect: CGRect
        switch reference.orientation {
        case .vertical:
            hitRect = CGRect(
                x: coordinate - captureWidth / 2.0,
                y: reference.span.lowerBound,
                width: captureWidth,
                height: max(1.0, reference.span.upperBound - reference.span.lowerBound)
            )
        case .horizontal:
            hitRect = CGRect(
                x: reference.span.lowerBound,
                y: coordinate - captureWidth / 2.0,
                width: max(1.0, reference.span.upperBound - reference.span.lowerBound),
                height: captureWidth
            )
        }

        return CollinearEdge(
            id: reference.id,
            orientation: reference.orientation,
            coordinate: coordinate,
            span: reference.span,
            hitRect: hitRect,
            leadingWindowIDs: reference.leadingWindowIDs,
            trailingWindowIDs: reference.trailingWindowIDs,
            minCoordinate: reference.minCoordinate,
            maxCoordinate: reference.maxCoordinate
        )
    }

    /// Whether candidate represents the same seam as reference (orientation and adjacent windows).
    func isSameSeam(_ candidate: CollinearEdge, as reference: CollinearEdge) -> Bool {
        candidate.orientation == reference.orientation
            && Set(candidate.leadingWindowIDs) == Set(reference.leadingWindowIDs)
            && Set(candidate.trailingWindowIDs) == Set(reference.trailingWindowIDs)
    }

    /// Whether two divider sets describe identical geometry.
    func sameDividerSet(_ lhs: [CollinearEdge], _ rhs: [CollinearEdge]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).allSatisfy {
            $0.orientation == $1.orientation && $0.coordinate == $1.coordinate &&
            $0.span == $1.span && $0.leadingWindowIDs == $1.leadingWindowIDs &&
            $0.trailingWindowIDs == $1.trailingWindowIDs
        }
    }

    /// Returns the divider set with the dragged seam replaced with its updated position.
    func overlaySet(
        from dividers: [CollinearEdge],
        dragging reference: CollinearEdge,
        to dragged: CollinearEdge
    ) -> [CollinearEdge] {
        var result = dividers.map { candidate in
            isSameSeam(candidate, as: reference) ? dragged : candidate
        }
        if result.contains(where: { isSameSeam($0, as: reference) }) == false {
            result.append(dragged)
        }
        return result
    }

    /// Checks whether `point` is occluded by any window that sits in front of the given participating windows in Z-order.
    public func isPointOccluded(_ point: CGPoint, forParticipatingWindowIDs participatingIDs: [CGWindowID]) -> Bool {
        guard !allVisibleWindows.isEmpty else { return false }
        let participatingSet = Set(participatingIDs)

        // Find the backmost Z-index among participating windows (highest index in front-to-back list)
        var maxParticipatingIndex = -1
        for (index, window) in allVisibleWindows.enumerated() {
            if participatingSet.contains(window.id) {
                maxParticipatingIndex = max(maxParticipatingIndex, index)
            }
        }
        guard maxParticipatingIndex > 0 else { return false }

        // Any window appearing before `maxParticipatingIndex` is in front of at least one participating window.
        for index in 0..<maxParticipatingIndex {
            let occluder = allVisibleWindows[index]
            if participatingSet.contains(occluder.id) { continue }
            if occluder.frame.contains(point) {
                return true
            }
        }
        return false
    }
}
