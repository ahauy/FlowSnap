import CoreGraphics
import Foundation

/// Pure mathematical involution performing exact bidirectional coordinate conversions
/// between macOS AppKit (bottom-left origin) and Accessibility API (top-left of Primary screen origin).
///
/// Traces to US-SNAP-003, BR-DISP-001, BR-DISP-003, BR-DISP-007.
public struct CoordinateTransformer: Sendable {

    /// Converts an AppKit CGRect to Accessibility API coordinates.
    ///
    /// Formula:
    /// $$Y_{AX} = H_{Primary} - (Y_{AppKit} + Height)$$
    ///
    /// - Parameters:
    ///   - rect: Frame in AppKit points.
    ///   - primaryScreenHeight: Total height in points of the primary display (where origin is `(0,0)`).
    /// - Returns: Frame in Accessibility API global coordinates.
    @inlinable
    public static func toAX(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - (rect.origin.y + rect.height),
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts an Accessibility API CGRect to AppKit coordinates.
    ///
    /// Formula:
    /// $$Y_{AppKit} = H_{Primary} - (Y_{AX} + Height)$$
    ///
    /// - Parameters:
    ///   - rect: Frame in Accessibility API global coordinates.
    ///   - primaryScreenHeight: Total height in points of the primary display.
    /// - Returns: Frame in AppKit points.
    @inlinable
    public static func toAppKit(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryScreenHeight - (rect.origin.y + rect.height),
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts an AppKit CGPoint to Accessibility API coordinates.
    ///
    /// Formula:
    /// $$Y_{AX} = H_{Primary} - Y_{AppKit}$$
    ///
    /// - Parameters:
    ///   - point: Point in AppKit points.
    ///   - primaryScreenHeight: Total height in points of the primary display.
    /// - Returns: Point in Accessibility API coordinates.
    @inlinable
    public static func toAX(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }

    /// Converts an Accessibility API CGPoint to AppKit coordinates.
    ///
    /// Formula:
    /// $$Y_{AppKit} = H_{Primary} - Y_{AX}$$
    ///
    /// - Parameters:
    ///   - point: Point in Accessibility API coordinates.
    ///   - primaryScreenHeight: Total height in points of the primary display.
    /// - Returns: Point in AppKit points.
    @inlinable
    public static func toAppKit(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: primaryScreenHeight - point.y)
    }
}
