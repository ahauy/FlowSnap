import CoreGraphics
import Foundation

/// Computes concrete window frames from layout definitions.
///
/// Pure computation — zero side effects, zero AppKit/AX dependencies.
/// Implements odd-pixel flooring policy (BR-LAYOUT-002) and visible frame boundary
/// isolation (BR-LAYOUT-001). See spec §30.
public struct LayoutEngine: LayoutCalculating, Sendable {

    public init() {}

    /// Calculate concrete frame for a single standard layout zone within available display bounds.
    ///
    /// - Parameters:
    ///   - zone: The standard zone target (half, quarter, maximize).
    ///   - availableFrame: Display visible frame (screen bounds minus Menu Bar and Dock).
    ///   - gap: Pixel gap between adjacent partitions.
    /// - Returns: Concrete pixel frame positioned within availableFrame.
    public func frame(
        for zone: LayoutZone,
        in availableFrame: CGRect,
        gap: CGFloat = 0
    ) -> CGRect {
        let originX = availableFrame.origin.x
        let originY = availableFrame.origin.y
        let totalWidth = max(0, availableFrame.width)
        let totalHeight = max(0, availableFrame.height)

        let safeGap = max(0, gap)
        let effectiveWidth = max(0, totalWidth - safeGap)
        let effectiveHeight = max(0, totalHeight - safeGap)

        // BR-LAYOUT-002: Flooring policy for odd pixel dimensions
        let leftWidth = floor(effectiveWidth / 2.0)
        let rightWidth = effectiveWidth - leftWidth
        let rightX = originX + leftWidth + safeGap

        let topHeight = floor(effectiveHeight / 2.0)
        let bottomHeight = effectiveHeight - topHeight
        let topY = originY + bottomHeight + safeGap
        let bottomY = originY

        // 70/30 Asymmetric split
        let left70Width = floor(effectiveWidth * 0.7)
        let right30Width = effectiveWidth - left70Width
        let right30X = originX + left70Width + safeGap

        // 3-Column Equal split
        let threeColEffectiveWidth = max(0, totalWidth - 2 * safeGap)
        let col1Width = floor(threeColEffectiveWidth / 3.0)
        let col2Width = floor((threeColEffectiveWidth - col1Width) / 2.0)
        let col3Width = threeColEffectiveWidth - col1Width - col2Width
        let col2X = originX + col1Width + safeGap
        let col3X = originX + col1Width + col2Width + (2 * safeGap)

        switch zone {
        case .leftHalf:
            return CGRect(x: originX, y: originY, width: leftWidth, height: totalHeight)
        case .rightHalf:
            return CGRect(x: rightX, y: originY, width: rightWidth, height: totalHeight)
        case .topHalf:
            return CGRect(x: originX, y: topY, width: totalWidth, height: topHeight)
        case .bottomHalf:
            return CGRect(x: originX, y: bottomY, width: totalWidth, height: bottomHeight)
        case .topLeft:
            return CGRect(x: originX, y: topY, width: leftWidth, height: topHeight)
        case .topRight:
            return CGRect(x: rightX, y: topY, width: rightWidth, height: topHeight)
        case .bottomLeft:
            return CGRect(x: originX, y: bottomY, width: leftWidth, height: bottomHeight)
        case .bottomRight:
            return CGRect(x: rightX, y: bottomY, width: rightWidth, height: bottomHeight)
        case .maximize:
            return CGRect(x: originX, y: originY, width: totalWidth, height: totalHeight)
        case .leftTwoThirds:
            return CGRect(x: originX, y: originY, width: left70Width, height: totalHeight)
        case .rightOneThird:
            return CGRect(x: right30X, y: originY, width: right30Width, height: totalHeight)
        case .leftThird:
            return CGRect(x: originX, y: originY, width: col1Width, height: totalHeight)
        case .centerThird:
            return CGRect(x: col2X, y: originY, width: col2Width, height: totalHeight)
        case .rightThird:
            return CGRect(x: col3X, y: originY, width: col3Width, height: totalHeight)
        }
    }

    /// Calculate concrete frames for a collection of managed windows assigned to a multi-zone layout.
    public func frames(
        for windows: [ManagedWindow],
        in availableFrame: CGRect,
        layout: Layout,
        gap: CGFloat = 0
    ) -> [CGWindowID: CGRect] {
        var result: [CGWindowID: CGRect] = [:]
        let count = min(windows.count, layout.zones.count)

        for index in 0..<count {
            let window = windows[index]
            let zone = layout.zones[index]
            result[window.id] = frame(for: zone, in: availableFrame, gap: gap)
        }

        return result
    }
}
