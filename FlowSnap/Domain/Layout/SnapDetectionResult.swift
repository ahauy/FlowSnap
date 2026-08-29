import CoreGraphics
import Foundation

/// Encapsulates the detected snap target, computed preview geometry, and screen metadata.
public struct SnapDetectionResult: Equatable, Sendable {
    /// Semantic snap destination (e.g. .left, .right, .maximize, .topLeft).
    public let target: SnapTarget

    /// Pre-calculated target frame in screen coordinates for overlay rendering.
    public let previewFrame: CGRect

    /// Display ID on which the snap zone was detected.
    public let displayID: CGDirectDisplayID

    /// Whether the triggered edge is adjacent to another connected display.
    public let isAdjacentEdge: Bool

    /// Whether the triggered zone is in the top-center summon region (30% - 70% width, top edge).
    public let isTopCenterZone: Bool

    public init(
        target: SnapTarget,
        previewFrame: CGRect,
        displayID: CGDirectDisplayID,
        isAdjacentEdge: Bool = false,
        isTopCenterZone: Bool = false
    ) {
        self.target = target
        self.previewFrame = previewFrame
        self.displayID = displayID
        self.isAdjacentEdge = isAdjacentEdge
        self.isTopCenterZone = isTopCenterZone
    }
}
