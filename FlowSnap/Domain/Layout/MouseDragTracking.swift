import CoreGraphics
import Foundation

/// Protocol for global mouse drag and release event interception.
@MainActor
public protocol MouseDragTracking: AnyObject, Sendable {
    var isTracking: Bool { get }

    func startTracking(
        onDrag: @escaping @Sendable (CGPoint) -> Void,
        onRelease: @escaping @Sendable (CGPoint) -> Void
    )

    func stopTracking()
}
