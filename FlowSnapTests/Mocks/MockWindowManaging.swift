import ApplicationServices
import CoreGraphics
import Foundation
@testable import FlowSnap

/// Test double implementing WindowManaging for unit tests.
@MainActor
public final class MockWindowManaging: WindowManaging {

    public var mockFocusedWindow: ManagedWindow?
    public private(set) var movedWindows: [(window: ManagedWindow, frame: CGRect)] = []
    /// The element each move was addressed to, parallel to `movedWindows`.
    ///
    /// Identity is the only thing that survives a move: asserting on it is how a
    /// test can prove the write landed on the window that was measured rather than
    /// on whatever frame-matching happened to return.
    public private(set) var movedElements: [AXUIElement?] = []
    public private(set) var focusedCallCount = 0
    public private(set) var moveCallCount = 0

    /// When set, `move` throws it instead of recording the move. Models E6 — a
    /// window that refuses to move (fixed-size panel, AX failure).
    public var moveError: Error?

    public init(mockFocusedWindow: ManagedWindow? = nil) {
        self.mockFocusedWindow = mockFocusedWindow
    }

    public func focusedWindow() async -> ManagedWindow? {
        focusedCallCount += 1
        return mockFocusedWindow
    }

    public func move(_ window: ManagedWindow, to frame: CGRect) async throws {
        try await move(window, to: frame, element: nil)
    }

    public func move(_ window: ManagedWindow, to frame: CGRect, element: AXUIElement?) async throws {
        moveCallCount += 1
        movedElements.append(element)
        if let moveError {
            // Record the attempt before failing: the caller's contract is about
            // what it *tried* to do, and a test asserting "no move happened"
            // should read as moveCallCount == 0, not as an empty frame list.
            movedWindows.append((window, frame))
            throw moveError
        }
        movedWindows.append((window, frame))
    }

    public private(set) var focusedWindows: [ManagedWindow] = []
    public private(set) var minimizedWindows: [ManagedWindow] = []
    public private(set) var unminimizedWindows: [ManagedWindow] = []
    public private(set) var focusCallCount = 0
    public private(set) var minimizeCallCount = 0
    public private(set) var unminimizeCallCount = 0

    public var focusError: Error?
    public var minimizeError: Error?
    public var unminimizeError: Error?

    public func focus(_ window: ManagedWindow) async throws {
        focusCallCount += 1
        focusedWindows.append(window)
        if let focusError {
            throw focusError
        }
    }

    public func minimize(_ window: ManagedWindow) async throws {
        minimizeCallCount += 1
        minimizedWindows.append(window)
        if let minimizeError {
            throw minimizeError
        }
    }

    public func unminimize(_ window: ManagedWindow) async throws {
        unminimizeCallCount += 1
        unminimizedWindows.append(window)
        if let unminimizeError {
            throw unminimizeError
        }
    }
}
