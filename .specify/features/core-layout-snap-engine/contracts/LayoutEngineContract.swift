import CoreGraphics
import Foundation

// MARK: - LayoutZone Enum

public enum LayoutZone: String, CaseIterable, Sendable, Codable, Hashable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
}

// MARK: - SnapTarget Contract

public enum SnapTarget: Sendable, Hashable {
    case zone(LayoutZone)
    case restore
    case layout(Layout)

    public static let left = SnapTarget.zone(.leftHalf)
    public static let right = SnapTarget.zone(.rightHalf)
    public static let top = SnapTarget.zone(.topHalf)
    public static let bottom = SnapTarget.zone(.bottomHalf)
    public static let topLeft = SnapTarget.zone(.topLeft)
    public static let topRight = SnapTarget.zone(.topRight)
    public static let bottomLeft = SnapTarget.zone(.bottomLeft)
    public static let bottomRight = SnapTarget.zone(.bottomRight)
    public static let maximize = SnapTarget.zone(.maximize)

    public var zone: LayoutZone? {
        if case .zone(let z) = self { return z }
        return nil
    }
}

// MARK: - LayoutCalculating Protocol

public protocol LayoutCalculating: Sendable {
    func frame(
        for zone: LayoutZone,
        in availableFrame: CGRect,
        gap: CGFloat
    ) -> CGRect

    func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout,
        gap: CGFloat
    ) -> [CGWindowID: CGRect]
}
