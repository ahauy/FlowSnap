import CoreGraphics
import Foundation

/// Protocol abstracting display topology, spatial queries, and multi-monitor navigation.
///
/// Traces to US-SNAP-003, BR-DISP-001, BR-DISP-002, BR-DISP-004, BR-DISP-005, BR-DISP-006.
public protocol DisplayManaging: Sendable {

    /// All active, non-mirrored displays currently connected.
    var displays: [Display] { get async }

    /// The primary display (where AppKit origin is `(0, 0)`).
    var primaryDisplay: Display? { get async }

    /// Total height in points of the primary display (anchor for global AX coordinate inversion).
    var primaryScreenHeight: CGFloat { get async }

    /// Finds the display containing the specified point in AppKit coordinates.
    func display(containing point: CGPoint) async -> Display?

    /// Finds the target display for a window frame.
    ///
    /// Evaluates maximum intersection area (`BR-DISP-002`).
    /// If intersection area is zero (window off-screen), falls back to `cursorPoint`, then `primaryDisplay`.
    func display(for windowFrame: CGRect, cursorPoint: CGPoint?) async -> Display?

    /// Returns the next display in sequence, cycling around.
    ///
    /// If only 1 display is connected, returns `nil` (`BR-DISP-006`).
    func nextDisplay(after currentDisplay: Display) async -> Display?

    /// Returns the previous display in sequence, cycling around.
    ///
    /// If only 1 display is connected, returns `nil` (`BR-DISP-008`).
    func previousDisplay(before currentDisplay: Display) async -> Display?
}

public extension DisplayManaging {
    /// Convenience helper when cursor point is omitted.
    func display(for windowFrame: CGRect) async -> Display? {
        await display(for: windowFrame, cursorPoint: nil)
    }
}
