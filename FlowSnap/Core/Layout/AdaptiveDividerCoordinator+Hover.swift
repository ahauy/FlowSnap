import AppKit
import CoreGraphics
import Foundation

extension AdaptiveDividerCoordinator {

    // MARK: - Hover

    public func handleMouseMoved(to point: CGPoint) async {
        guard !isResizing else { return }

        if let service = accessibilityService, !service.isTrusted {
            if hoveredDivider != nil {
                setCursor(.arrow)
                hoveredDivider = nil
            }
            overlayManager?.hide(animated: false)
            return
        }

        let gap = resolveGap()
        let container = await resolveContainer(at: point)

        // Ensure mouse is on the same display where the workspace windows actually reside
        if isWorkspaceRestrictionEnabled && currentActiveWorkspace != nil && !managedWindows.isEmpty {
            let belongsToWorkspaceScreen = managedWindows.contains { win in
                let intersection = win.frame.intersection(container)
                return !intersection.isNull && intersection.width > 20 && intersection.height > 20
            }
            if !belongsToWorkspaceScreen {
                if hoveredDivider != nil {
                    setCursor(.arrow)
                    hoveredDivider = nil
                }
                overlayManager?.hide(animated: false)
                return
            }
        }

        // Ensure the active frontmost application belongs to the workspace or FlowSnap itself.
        // If the user switched to another app (e.g. Antigravity IDE, Browser, Slack),
        // the workspace is in the background — never draw the divider overlay on top of foreground apps.
        if isNonWorkspaceAppFrontmost {
            if hoveredDivider != nil || hoveredJunction != nil {
                setCursor(.arrow)
                hoveredDivider = nil
                hoveredJunction = nil
            }
            overlayManager?.hide(animated: false)
            return
        }

        let displayWindows = filterWindows(for: container)
        guard displayWindows.count >= 2 else {
            if hoveredDivider != nil || hoveredJunction != nil {
                setCursor(.arrow)
                hoveredDivider = nil
                hoveredJunction = nil
            }
            if !lastPresentedDividers.isEmpty || !lastPresentedWindows.isEmpty {
                lastPresentedDividers = []
                lastPresentedWindows = []
                lastPresentedContainer = nil
                if let panel = overlayManager as? AdaptiveDividerOverlayPanel {
                    panel.overlayView.updateState(
                        containerFrame: .zero,
                        windows: [],
                        dividers: [],
                        activeDivider: nil,
                        activeJunction: nil,
                        isDragging: false
                    )
                }
            }
            overlayManager?.hide(animated: false)
            return
        }
        let dividers = cachedDividers(for: displayWindows, container: container, gap: gap)
        let junctions = detector.detectJunctions(in: dividers, tolerance: max(gap + 12.0, 16.0))
        var hoveredJunc = detector.hitTestJunction(at: point, in: junctions)
        if let junc = hoveredJunc, isPointOccluded(point, forParticipatingWindowIDs: junc.participatingWindowIDs) {
            hoveredJunc = nil
        }
        var hovered = hoveredJunc != nil ? nil : detector.hitTestDivider(at: point, in: dividers)
        if let div = hovered, isPointOccluded(point, forParticipatingWindowIDs: div.leadingWindowIDs + div.trailingWindowIDs) {
            hovered = nil
        }

        // Nothing on screen changes unless the seam set or the hovered seam/junction
        // changed, so skip the overlay refresh when they did not. Without this,
        // a 120Hz pointer re-presents the panel on every single event.
        let junctionChanged = (hoveredJunction?.id != hoveredJunc?.id)
        let activeChanged: Bool
        switch (hoveredDivider, hovered) {
        case (nil, nil):
            activeChanged = junctionChanged
        case let (previous?, current?):
            activeChanged = previous.coordinate != current.coordinate || !isSameSeam(previous, as: current) || junctionChanged
        default:
            activeChanged = true
        }
        // The overlay draws window outlines too, so a change in which windows
        // are on screen is a change even when the seams look identical.
        let setChanged = !sameDividerSet(dividers, lastPresentedDividers)
            || displayWindows != lastPresentedWindows
            || container != lastPresentedContainer

        if let junc = hoveredJunc {
            hoveredJunction = junc
            hoveredDivider = nil
            setCursor(.crosshair)
        } else if let divider = hovered {
            hoveredJunction = nil
            hoveredDivider = divider
            switch divider.orientation {
            case .vertical:
                setCursor(.resizeLeftRight)
            case .horizontal:
                setCursor(.resizeUpDown)
            }
        } else {
            if hoveredDivider != nil || hoveredJunction != nil { setCursor(.arrow) }
            hoveredDivider = nil
            hoveredJunction = nil
        }

        guard activeChanged || setChanged else { return }
        lastPresentedDividers = dividers
        lastPresentedWindows = displayWindows
        lastPresentedContainer = container

        if let junc = hoveredJunc {
            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: nil,
                activeJunction: junc,
                isDragging: false
            )
        } else if let activeDivider = hovered {
            overlayManager?.show(
                containerFrame: container,
                windows: displayWindows,
                dividers: dividers,
                activeDivider: activeDivider,
                activeJunction: nil,
                isDragging: false
            )
        } else {
            overlayManager?.hide(animated: true)
        }
    }
}
