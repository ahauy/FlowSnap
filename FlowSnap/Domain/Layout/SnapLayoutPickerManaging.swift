import CoreGraphics
import Foundation

/// Protocol governing the lifecycle, presentation, hit-testing, and dismissal of the Top-Edge Snap Layout Picker.
@MainActor
public protocol SnapLayoutPickerManaging: AnyObject, Sendable {
    /// Whether the layout picker panel is currently visible on screen.
    var isVisible: Bool { get }

    /// The display where the picker is currently presented.
    var activeDisplayID: CGDirectDisplayID? { get }

    /// The global frame of the picker panel on screen (AppKit coordinate space).
    var pickerFrame: CGRect? { get }

    /// Presents the layout picker centered at the top of the specified display.
    func showPicker(on display: Display)

    /// Dismisses the layout picker panel.
    func hidePicker(animated: Bool)

    /// Performs hit-testing against the layout template slots with the given global screen point.
    /// Returns the hovered `LayoutSlot` if the point intersects a slot.
    func hitTestSlot(at screenPoint: CGPoint) -> LayoutSlot?
}
