import CoreGraphics
import Foundation

/// Protocol for evaluating cursor coordinates against display boundaries to identify snap zones.
public protocol SnapDetecting: Sendable {
    func detectZone(
        at point: CGPoint,
        on display: Display,
        adjacentDisplays: [Display]
    ) -> SnapDetectionResult?
}
