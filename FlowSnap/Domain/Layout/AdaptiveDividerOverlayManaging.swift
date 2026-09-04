import AppKit
import CoreGraphics
import Foundation

/// Protocol governing the lifecycle, presentation, and visual state updates of the Adaptive Divider Overlay Panel.
@MainActor
public protocol AdaptiveDividerOverlayManaging: AnyObject, Sendable {
    /// Whether the divider overlay panel is currently visible on screen.
    var isOverlayVisible: Bool { get }

    /// Presents or updates the overlay panel over the specified display container frame.
    func show(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        activeJunction: CrossJunction?,
        isDragging: Bool
    )

    /// Updates the overlay panel's visual state during live resizing.
    func update(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        activeJunction: CrossJunction?,
        isDragging: Bool
    )

    /// Dismisses the overlay panel, optionally with animation.
    func hide(animated: Bool)
}

extension AdaptiveDividerOverlayManaging {
    public func show(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        isDragging: Bool
    ) {
        show(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: activeDivider,
            activeJunction: nil,
            isDragging: isDragging
        )
    }

    public func update(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        isDragging: Bool
    ) {
        update(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: activeDivider,
            activeJunction: nil,
            isDragging: isDragging
        )
    }
}
