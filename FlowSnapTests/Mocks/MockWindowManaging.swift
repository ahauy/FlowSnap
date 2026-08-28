import CoreGraphics
import Foundation
@testable import FlowSnap

/// Test double implementing WindowManaging for unit tests.
@MainActor
public final class MockWindowManaging: WindowManaging {

    public var mockFocusedWindow: ManagedWindow?
    public private(set) var movedWindows: [(window: ManagedWindow, frame: CGRect)] = []
    public private(set) var focusedCallCount = 0
    public private(set) var moveCallCount = 0

    public init(mockFocusedWindow: ManagedWindow? = nil) {
        self.mockFocusedWindow = mockFocusedWindow
    }

    public func focusedWindow() async -> ManagedWindow? {
        focusedCallCount += 1
        return mockFocusedWindow
    }

    public func move(_ window: ManagedWindow, to frame: CGRect) async throws {
        moveCallCount += 1
        movedWindows.append((window, frame))
    }

    public func focus(_ window: ManagedWindow) async throws {}
    public func minimize(_ window: ManagedWindow) async throws {}
}
