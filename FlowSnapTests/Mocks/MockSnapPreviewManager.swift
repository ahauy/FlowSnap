import CoreGraphics
import Foundation
@testable import FlowSnap

@MainActor
public final class MockSnapPreviewManager: SnapPreviewManaging {

    public var isPreviewVisible: Bool = false
    public var lastShownFrame: CGRect?
    public var lastShownDisplayID: CGDirectDisplayID?
    public var showPreviewCallCount: Int = 0
    public var hidePreviewCallCount: Int = 0
    public var flashSnapSuccessCallCount: Int = 0

    public init() {}

    public func showPreview(frame: CGRect, displayID: CGDirectDisplayID) {
        isPreviewVisible = true
        lastShownFrame = frame
        lastShownDisplayID = displayID
        showPreviewCallCount += 1
    }

    public func hidePreview(animated: Bool) {
        isPreviewVisible = false
        hidePreviewCallCount += 1
    }

    public func flashSnapSuccess(frame: CGRect) {
        flashSnapSuccessCallCount += 1
    }
}
