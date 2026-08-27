import CoreGraphics
import Foundation

/// Converts a SnapTarget into a concrete frame using LayoutEngine and coordinates
/// pre-snap frame caching in WindowRegistry.
///
/// Flow: User Action → SnapEngine → SnapTarget → LayoutEngine → WindowRegistry.
/// See spec §31.
public struct SnapEngine: Sendable {

    private let layoutEngine: LayoutCalculating
    private let windowRegistry: WindowRegistry

    public init(
        layoutEngine: LayoutCalculating = LayoutEngine(),
        windowRegistry: WindowRegistry
    ) {
        self.layoutEngine = layoutEngine
        self.windowRegistry = windowRegistry
    }

    /// Calculate the concrete frame for a target without applying it to the window.
    ///
    /// - Parameters:
    ///   - target: The destination snap zone or restore action.
    ///   - window: The managed window to position.
    ///   - availableFrame: The display's visible bounds.
    ///   - gap: Pixel gap between windows.
    /// - Returns: The target frame if valid, or nil if restore has no cached frame.
    public func calculateFrame(
        for target: SnapTarget,
        window: ManagedWindow,
        availableFrame: CGRect,
        gap: CGFloat = 0
    ) async -> CGRect? {
        switch target {
        case .restore:
            return await windowRegistry.consumePreSnapFrame(for: window.id)

        case .zone(let zone):
            // BR-LAYOUT-004: Store pre-snap frame if not already recorded
            await windowRegistry.storePreSnapFrameIfNeeded(window.frame, for: window.id)
            let baseFrame = layoutEngine.frame(for: zone, in: availableFrame, gap: gap)
            return applyMinSizeAnchoring(baseFrame, minSize: window.minSize, zone: zone, availableFrame: availableFrame)

        case .layout(let layout):
            await windowRegistry.storePreSnapFrameIfNeeded(window.frame, for: window.id)
            guard let firstZone = layout.zones.first else { return nil }
            let baseFrame = layoutEngine.frame(for: firstZone, in: availableFrame, gap: gap)
            return applyMinSizeAnchoring(baseFrame, minSize: window.minSize, zone: firstZone, availableFrame: availableFrame)
        }
    }

    /// Calculate the target frame for a given display (convenience for Display entity).
    public func frame(
        for target: SnapTarget,
        window: ManagedWindow,
        on display: Display,
        gap: CGFloat = 0
    ) async -> CGRect? {
        await calculateFrame(for: target, window: window, availableFrame: display.visibleFrame, gap: gap)
    }

    // MARK: - Private Anchoring Helper (BR-LAYOUT-005)

    private func applyMinSizeAnchoring(
        _ baseFrame: CGRect,
        minSize: CGSize?,
        zone: LayoutZone,
        availableFrame: CGRect
    ) -> CGRect {
        guard let minSize = minSize else { return baseFrame }

        let effectiveWidth = max(baseFrame.width, minSize.width)
        let effectiveHeight = max(baseFrame.height, minSize.height)

        var x = baseFrame.origin.x
        var y = baseFrame.origin.y

        // Anchor to right edge if zone is right-aligned
        switch zone {
        case .rightHalf, .topRight, .bottomRight:
            x = availableFrame.maxX - effectiveWidth
        default:
            break
        }

        // Anchor to bottom edge if zone is bottom-aligned
        switch zone {
        case .bottomHalf, .bottomLeft, .bottomRight:
            y = availableFrame.maxY - effectiveHeight
        default:
            break
        }

        return CGRect(x: x, y: y, width: effectiveWidth, height: effectiveHeight)
    }
}
