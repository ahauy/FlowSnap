import CoreGraphics
import Foundation

public protocol SnapDetecting: Sendable {
    func detectZone(
        at point: CGPoint,
        on display: Display,
        adjacentDisplays: [Display]
    ) -> SnapDetectionResult?
}
