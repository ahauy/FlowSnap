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
    ///   - zone: The standard zone target (half, quarter, maximize, asymmetric ratio).
    ///   - availableFrame: Display visible frame (screen bounds minus Menu Bar and Dock).
    ///   - gap: Pixel gap between adjacent partitions.
    ///   - uniform: When true, gap is subtracted from BOTH outer edges
    ///     (BR-CRW-003: effectiveWidth = totalWidth - 3*gap for 2-column,
    ///      totalWidth - 4*gap for 3-column). Default false
    ///     preserves legacy inner-only behavior (BR-CRW-004).
    /// - Returns: Concrete pixel frame positioned within availableFrame.
    public func frame(
        for zone: LayoutZone,
        in availableFrame: CGRect,
        gap: CGFloat = 0,
        uniform: Bool = false
    ) -> CGRect {
        let originX = availableFrame.origin.x
        let originY = availableFrame.origin.y
        let totalWidth = max(0, availableFrame.width)
        let totalHeight = max(0, availableFrame.height)

        let safeGap = max(0, gap)

        // BR-CRW-003: Uniform gap trims BOTH outer edges; origin shifts inward by gap.
        let widthInset = uniform ? safeGap : 0
        let effectiveWidth = max(0, totalWidth - (uniform ? 3 * safeGap : safeGap))
        let effectiveHeight = max(0, totalHeight - safeGap)
        let zoneOriginX = originX + widthInset

        // BR-LAYOUT-002: Flooring policy for odd pixel dimensions
        let leftWidth = floor(effectiveWidth / 2.0)
        let rightWidth = effectiveWidth - leftWidth
        let rightX = zoneOriginX + leftWidth + safeGap

        let topHeight = floor(effectiveHeight / 2.0)
        let bottomHeight = effectiveHeight - topHeight
        let topY = originY + bottomHeight + safeGap
        let bottomY = originY

        // 70/30 Asymmetric split
        let left70Width = floor(effectiveWidth * 0.7)
        let right30Width = effectiveWidth - left70Width
        let right30X = zoneOriginX + left70Width + safeGap

        // 60/40 Asymmetric split
        let left60Width = floor(effectiveWidth * 0.6)
        let right40Width = effectiveWidth - left60Width
        let right40X = zoneOriginX + left60Width + safeGap

        // 80/20 Asymmetric split
        let left80Width = floor(effectiveWidth * 0.8)
        let right20Width = effectiveWidth - left80Width
        let right20X = zoneOriginX + left80Width + safeGap

        // 3-Column Equal split (legacy thirds)
        let threeColEffectiveWidth = max(0, totalWidth - 2 * safeGap)
        let col1Width = floor(threeColEffectiveWidth / 3.0)
        let col2Width = floor((threeColEffectiveWidth - col1Width) / 2.0)
        let col3Width = threeColEffectiveWidth - col1Width - col2Width
        let col2X = originX + col1Width + safeGap
        let col3X = originX + col1Width + col2Width + (2 * safeGap)

        // 25/50/25 3-Column split (US-SNAP-008)
        // Uniform trims 4 edges (2 outer + 2 inner gutters); legacy trims 2 inner gutters.
        let gapCount = uniform ? 4 : 2
        let twoFiveEffectiveWidth = max(0, totalWidth - CGFloat(gapCount) * safeGap)
        let q25Width = floor(twoFiveEffectiveWidth * 0.25)
        let halfWidth = floor(twoFiveEffectiveWidth * 0.5)
        let q25Remainder = twoFiveEffectiveWidth - q25Width - halfWidth
        let c25X = zoneOriginX + q25Width + safeGap
        let r25X = zoneOriginX + q25Width + halfWidth + (2 * safeGap)

        switch zone {
        case .leftHalf, .left50_50:
            return CGRect(x: zoneOriginX, y: originY, width: leftWidth, height: totalHeight)
        case .rightHalf, .right50_50:
            return CGRect(x: rightX, y: originY, width: rightWidth, height: totalHeight)
        case .topHalf:
            return CGRect(x: zoneOriginX, y: topY, width: effectiveWidth, height: topHeight)
        case .bottomHalf:
            return CGRect(x: zoneOriginX, y: bottomY, width: effectiveWidth, height: bottomHeight)
        case .topLeft:
            return CGRect(x: zoneOriginX, y: topY, width: leftWidth, height: topHeight)
        case .topRight:
            return CGRect(x: rightX, y: topY, width: rightWidth, height: topHeight)
        case .bottomLeft:
            return CGRect(x: zoneOriginX, y: bottomY, width: leftWidth, height: bottomHeight)
        case .bottomRight:
            return CGRect(x: rightX, y: bottomY, width: rightWidth, height: bottomHeight)
        case .maximize:
            return CGRect(x: originX, y: originY, width: totalWidth, height: totalHeight)
        case .leftTwoThirds, .left70_30:
            return CGRect(x: zoneOriginX, y: originY, width: left70Width, height: totalHeight)
        case .rightOneThird:
            return CGRect(x: right30X, y: originY, width: right30Width, height: totalHeight)
        case .leftThird:
            return CGRect(x: originX, y: originY, width: col1Width, height: totalHeight)
        case .centerThird:
            return CGRect(x: col2X, y: originY, width: col2Width, height: totalHeight)
        case .rightThird:
            return CGRect(x: col3X, y: originY, width: col3Width, height: totalHeight)
        case .left60_40:
            return CGRect(x: zoneOriginX, y: originY, width: left60Width, height: totalHeight)
        case .right40_60:
            return CGRect(x: right40X, y: originY, width: right40Width, height: totalHeight)
        case .left80_20:
            return CGRect(x: zoneOriginX, y: originY, width: left80Width, height: totalHeight)
        case .right20_80:
            return CGRect(x: right20X, y: originY, width: right20Width, height: totalHeight)
        case .left25:
            return CGRect(x: zoneOriginX, y: originY, width: q25Width, height: totalHeight)
        case .center50:
            return CGRect(x: c25X, y: originY, width: halfWidth, height: totalHeight)
        case .right25:
            return CGRect(x: r25X, y: originY, width: q25Remainder, height: totalHeight)
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
