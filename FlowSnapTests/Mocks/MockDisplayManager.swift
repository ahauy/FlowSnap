import CoreGraphics
import Foundation
@testable import FlowSnap

public final class MockDisplayManager: DisplayManaging, @unchecked Sendable {

    public var mockDisplays: [Display] = []
    public var mockPrimaryDisplay: Display?
    public var mockPrimaryScreenHeight: CGFloat = 1080

    public var displays: [Display] {
        get async { mockDisplays }
    }

    public var primaryDisplay: Display? {
        get async { mockPrimaryDisplay ?? mockDisplays.first(where: { $0.isPrimary }) ?? mockDisplays.first }
    }

    public var primaryScreenHeight: CGFloat {
        get async { mockPrimaryScreenHeight }
    }

    public init(displays: [Display] = []) {
        self.mockDisplays = displays
    }

    public func display(containing point: CGPoint) async -> Display? {
        mockDisplays.first { $0.frame.contains(point) }
    }

    public func display(for windowFrame: CGRect, cursorPoint: CGPoint?) async -> Display? {
        if let cursorPoint, let display = await display(containing: cursorPoint) {
            return display
        }
        return mockDisplays.first { $0.frame.intersects(windowFrame) } ?? mockDisplays.first
    }

    private let navigator: any DisplayNavigating = DisplayNavigator()

    public func nextDisplay(after currentDisplay: Display) async -> Display? {
        navigator.nextDisplay(after: currentDisplay, in: mockDisplays)
    }

    public func previousDisplay(before currentDisplay: Display) async -> Display? {
        navigator.previousDisplay(before: currentDisplay, in: mockDisplays)
    }
}
