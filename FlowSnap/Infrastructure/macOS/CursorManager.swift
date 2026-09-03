import CoreGraphics
import Foundation

/// Protocol abstracting mouse cursor positioning for testability.
///
/// Traces to US-DISP-015, BR-DISP-012, ASM-DISP-003.
public protocol CursorWarping: Sendable {
    func warpCursor(to point: CGPoint)
}

/// Production implementation of CursorWarping using CoreGraphics CGWarpMouseCursorPosition.
public final class CursorManager: CursorWarping, @unchecked Sendable {

    public init() {}

    public func warpCursor(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
    }
}
