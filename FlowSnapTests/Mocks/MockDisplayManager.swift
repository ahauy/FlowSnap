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

    public func nextDisplay(after currentDisplay: Display) async -> Display? {
        guard mockDisplays.count > 1 else { return nil }
        guard let index = mockDisplays.firstIndex(where: { $0.id == currentDisplay.id }) else {
            return mockDisplays.first
        }
        let nextIndex = (index + 1) % mockDisplays.count
        return mockDisplays[nextIndex]
    }
}
