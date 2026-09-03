import CoreGraphics
import Foundation

/// Protocol abstracting spatial navigation across multi-monitor topologies.
///
/// Traces to US-DISP-015, BR-DISP-007, BR-DISP-008, BR-DISP-011.
public protocol DisplayNavigating: Sendable {
    /// Sorts displays spatially from left to right (primary: minX, secondary: minY).
    func sortedDisplays(from displays: [Display]) -> [Display]

    /// Returns the next display in spatial sequence with cyclic wrap-around.
    /// If displays.count <= 1, returns nil.
    func nextDisplay(after current: Display, in displays: [Display]) -> Display?

    /// Returns the previous display in spatial sequence with cyclic wrap-around.
    /// If displays.count <= 1, returns nil.
    func previousDisplay(before current: Display, in displays: [Display]) -> Display?
}

/// Pure spatial calculation engine for multi-monitor topologies.
///
/// Sorts displays by physical layout (left-to-right) and executes cyclic modulo traversal.
public struct DisplayNavigator: DisplayNavigating {

    public init() {}

    public func sortedDisplays(from displays: [Display]) -> [Display] {
        displays.sorted { first, second in
            if first.frame.minX != second.frame.minX {
                return first.frame.minX < second.frame.minX
            }
            return first.frame.minY < second.frame.minY
        }
    }

    public func nextDisplay(after current: Display, in displays: [Display]) -> Display? {
        guard displays.count > 1 else { return nil }
        let sorted = sortedDisplays(from: displays)
        guard let currentIndex = sorted.firstIndex(where: { $0.id == current.id }) else {
            return sorted.first
        }
        let nextIndex = (currentIndex + 1) % sorted.count
        return sorted[nextIndex]
    }

    public func previousDisplay(before current: Display, in displays: [Display]) -> Display? {
        guard displays.count > 1 else { return nil }
        let sorted = sortedDisplays(from: displays)
        guard let currentIndex = sorted.firstIndex(where: { $0.id == current.id }) else {
            return sorted.last
        }
        let prevIndex = (currentIndex - 1 + sorted.count) % sorted.count
        return sorted[prevIndex]
    }
}
