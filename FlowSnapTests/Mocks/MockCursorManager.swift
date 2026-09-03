import CoreGraphics
import Foundation
@testable import FlowSnap

public final class MockCursorManager: CursorWarping, @unchecked Sendable {

    public var warpedPoints: [CGPoint] = []

    public init() {}

    public func warpCursor(to point: CGPoint) {
        warpedPoints.append(point)
    }

    public var lastWarpedPoint: CGPoint? {
        warpedPoints.last
    }
}
