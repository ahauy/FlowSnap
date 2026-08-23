import AppKit
import CoreGraphics

/// Concrete display manager backed by NSScreen.
///
/// Converts NSScreen data to Display domain models.
/// See spec §33.
final class DisplayManager: DisplayManaging {

    var displays: [Display] {
        // TODO: Map NSScreen.screens to Display models
        []
    }

    func display(containing point: CGPoint) -> Display? {
        // TODO: Find which display frame contains the point
        nil
    }

    func display(containing window: ManagedWindow) -> Display? {
        // TODO: Use window center point to find containing display
        let center = CGPoint(
            x: window.frame.midX,
            y: window.frame.midY
        )
        return display(containing: center)
    }
}
