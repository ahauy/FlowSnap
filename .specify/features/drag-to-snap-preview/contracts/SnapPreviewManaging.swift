import CoreGraphics
import Foundation

@MainActor
public protocol SnapPreviewManaging: AnyObject, Sendable {
    var isPreviewVisible: Bool { get }
    func showPreview(frame: CGRect, displayID: CGDirectDisplayID)
    func hidePreview(animated: Bool)
    func flashSnapSuccess(frame: CGRect)
}
