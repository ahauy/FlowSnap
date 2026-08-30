import ApplicationServices
import CoreGraphics
import Foundation

/// Protocol abstraction for window querying and manipulation.
///
/// See spec §27. All window manipulations execute on the MainActor.
@MainActor
public protocol WindowManaging: Sendable {
    func focusedWindow() async -> ManagedWindow?
    func move(_ window: ManagedWindow, to frame: CGRect) async throws
    func move(_ window: ManagedWindow, to frame: CGRect, element: AXUIElement?) async throws
    func focus(_ window: ManagedWindow) async throws
    func minimize(_ window: ManagedWindow) async throws
}

extension WindowManaging {
    public func move(_ window: ManagedWindow, to frame: CGRect, element: AXUIElement?) async throws {
        try await move(window, to: frame)
    }
}

