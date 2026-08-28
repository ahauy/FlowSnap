import CoreGraphics
import Foundation

// MARK: - Display Contracts (US-SNAP-003)

/// Domain model for a macOS display.
public struct DisplayContract: Identifiable, Hashable, Sendable {
    public let id: CGDirectDisplayID
    public let frame: CGRect
    public let visibleFrame: CGRect
    public let scaleFactor: CGFloat
    public let isPrimary: Bool

    public init(
        id: CGDirectDisplayID,
        frame: CGRect,
        visibleFrame: CGRect,
        scaleFactor: CGFloat,
        isPrimary: Bool? = nil
    ) {
        self.id = id
        self.frame = frame
        self.visibleFrame = visibleFrame
        self.scaleFactor = scaleFactor
        self.isPrimary = isPrimary ?? (frame.origin == .zero)
    }
}

/// Abstract protocol for display management.
public protocol DisplayManagingContract: Sendable {
    var displays: [DisplayContract] { get async }
    var primaryDisplay: DisplayContract? { get async }
    var primaryScreenHeight: CGFloat { get async }
    func display(containing point: CGPoint) async -> DisplayContract?
    func display(for windowFrame: CGRect, cursorPoint: CGPoint?) async -> DisplayContract?
    func nextDisplay(after currentDisplay: DisplayContract) async -> DisplayContract?
}

/// Coordinate conversion contract.
public protocol CoordinateTransformingContract: Sendable {
    static func toAX(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect
    static func toAppKit(rect: CGRect, primaryScreenHeight: CGFloat) -> CGRect
    static func toAX(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint
    static func toAppKit(point: CGPoint, primaryScreenHeight: CGFloat) -> CGPoint
}
