import CoreGraphics
import Foundation
@testable import FlowSnap

@MainActor
public final class MockMouseDragTracker: MouseDragTracking {

    public var isTracking: Bool = false
    public var onDragHandler: (@Sendable (CGPoint) -> Void)?
    public var onReleaseHandler: (@Sendable (CGPoint) -> Void)?

    public var startTrackingCallCount: Int = 0
    public var stopTrackingCallCount: Int = 0

    public init() {}

    public func startTracking(
        onDrag: @escaping @Sendable (CGPoint) -> Void,
        onRelease: @escaping @Sendable (CGPoint) -> Void
    ) {
        isTracking = true
        startTrackingCallCount += 1
        self.onDragHandler = onDrag
        self.onReleaseHandler = onRelease
    }

    public func stopTracking() {
        isTracking = false
        stopTrackingCallCount += 1
        onDragHandler = nil
        onReleaseHandler = nil
    }

    // Helper simulation methods for tests
    public func simulateDrag(to point: CGPoint) {
        onDragHandler?(point)
    }

    public func simulateRelease(at point: CGPoint) {
        onReleaseHandler?(point)
    }
}
