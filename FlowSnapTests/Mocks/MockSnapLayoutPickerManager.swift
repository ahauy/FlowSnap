import CoreGraphics
import Foundation
@testable import FlowSnap

@MainActor
public final class MockSnapLayoutPickerManager: SnapLayoutPickerManaging {

    public var isVisible: Bool = false
    public var activeDisplayID: CGDirectDisplayID?
    public var pickerFrame: CGRect?
    public var mockedSlotToReturn: LayoutSlot?

    public var showPickerCallCount: Int = 0
    public var hidePickerCallCount: Int = 0
    public var hitTestSlotCallCount: Int = 0

    public init(pickerFrame: CGRect? = CGRect(x: 745, y: 955, width: 430, height: 92)) {
        self.pickerFrame = pickerFrame
    }

    public func showPicker(on display: Display) {
        isVisible = true
        activeDisplayID = display.id
        showPickerCallCount += 1
    }

    public func hidePicker(animated: Bool) {
        isVisible = false
        activeDisplayID = nil
        hidePickerCallCount += 1
    }

    public func hitTestSlot(at screenPoint: CGPoint) -> LayoutSlot? {
        hitTestSlotCallCount += 1
        return mockedSlotToReturn
    }
}
