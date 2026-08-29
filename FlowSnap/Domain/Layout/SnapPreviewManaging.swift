import CoreGraphics
import Foundation

/// Protocol for controlling the life cycle and visual presentation of the HUD snap preview overlay.
@MainActor
public protocol SnapPreviewManaging: AnyObject, Sendable {
    var isPreviewVisible: Bool { get }

    func showPreview(frame: CGRect, displayID: CGDirectDisplayID)
    func hidePreview(animated: Bool)
    func flashSnapSuccess(frame: CGRect)
}
