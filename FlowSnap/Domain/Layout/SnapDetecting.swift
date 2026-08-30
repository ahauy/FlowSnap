import CoreGraphics
import Foundation

/// Protocol for evaluating cursor coordinates against display boundaries to identify snap zones.
public protocol SnapDetecting: Sendable {
    func detectZone(
        at point: CGPoint,
        on display: Display,
        adjacentDisplays: [Display],
        defaultRatio: LayoutRatio,
        windowGap: CGFloat
    ) -> SnapDetectionResult?

    /// Checks whether the cursor is in the top-center trigger zone (middle 40% width, top edge).
    func isTopCenterZone(at point: CGPoint, on display: Display) -> Bool
}

public extension SnapDetecting {
    func detectZone(
        at point: CGPoint,
        on display: Display,
        adjacentDisplays: [Display]
    ) -> SnapDetectionResult? {
        detectZone(
            at: point,
            on: display,
            adjacentDisplays: adjacentDisplays,
            defaultRatio: .equal,
            windowGap: 0
        )
    }
}
