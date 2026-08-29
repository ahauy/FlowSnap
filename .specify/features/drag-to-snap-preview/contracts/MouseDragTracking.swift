import CoreGraphics
import Foundation

@MainActor
public protocol MouseDragTracking: AnyObject, Sendable {
    var isTracking: Bool { get }
    func startTracking(
        onDrag: @escaping @Sendable (CGPoint) -> Void,
        onRelease: @escaping @Sendable (CGPoint) -> Void
    )
    func stopTracking()
}
