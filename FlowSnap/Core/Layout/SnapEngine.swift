import CoreGraphics
import Foundation

/// Converts a SnapTarget into a concrete frame using LayoutEngine and coordinates
/// pre-snap frame caching in WindowRegistry.
///
/// Flow: User Action → SnapEngine → SnapTarget → LayoutEngine → WindowRegistry.
/// See spec §31.
public struct SnapEngine: Sendable {

    private let layoutEngine: LayoutCalculating
    public let windowRegistry: WindowRegistry
    private let displayManager: (any DisplayManaging)?
    private let preferencesStore: PreferencesStore?

    public init(
        layoutEngine: LayoutCalculating = LayoutEngine(),
        windowRegistry: WindowRegistry,
        displayManager: (any DisplayManaging)? = nil,
        preferencesStore: PreferencesStore? = nil
    ) {
        self.layoutEngine = layoutEngine
        self.windowRegistry = windowRegistry
        self.displayManager = displayManager
        self.preferencesStore = preferencesStore
    }

    /// Resolve the effective gap for a snap operation (contracts.md §5.2).
    ///
    /// Priority: explicit `gap` > `preferencesStore.windowGap` > `0` (legacy default).
    private func resolveGap(_ gap: CGFloat?) async -> CGFloat {
        if let gap { return gap }
        guard let preferencesStore else { return 0 }
        return await preferencesStore.windowGap
    }

    /// Resolve the effective layout zone considering defaultRatio preferences.
    private func resolveZone(_ zone: LayoutZone) async -> LayoutZone {
        guard let preferencesStore else { return zone }
        let ratio = await preferencesStore.defaultRatio
        switch zone {
        case .leftHalf:
            return ratio.leftZone
        case .rightHalf:
            return ratio.rightZone
        default:
            return zone
        }
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
        gap: CGFloat? = nil
    ) async -> CGRect? {
        let effectiveGap = await resolveGap(gap)
        let uniform = effectiveGap > 0
        switch target {
        case .restore:
            return await windowRegistry.consumePreSnapFrame(for: window.id)

        case .zone(let zone):
            // BR-LAYOUT-004: Store pre-snap frame if not already recorded
            await windowRegistry.storePreSnapFrameIfNeeded(window.frame, for: window.id)
            let resolvedZone = await resolveZone(zone)
            let baseFrame = layoutEngine.frame(for: resolvedZone, in: availableFrame, gap: effectiveGap, uniform: uniform)
            return applyMinSizeAnchoring(baseFrame, minSize: window.minSize, zone: resolvedZone, availableFrame: availableFrame)

        case .layout(let layout):
            await windowRegistry.storePreSnapFrameIfNeeded(window.frame, for: window.id)
            guard let firstZone = layout.zones.first else { return nil }
            let baseFrame = layoutEngine.frame(for: firstZone, in: availableFrame, gap: effectiveGap, uniform: uniform)
            return applyMinSizeAnchoring(baseFrame, minSize: window.minSize, zone: firstZone, availableFrame: availableFrame)
        }
    }

    /// Calculate the target frame for a given display (convenience for Display entity).
    public func frame(
        for target: SnapTarget,
        window: ManagedWindow,
        on display: Display,
        gap: CGFloat? = nil
    ) async -> CGRect? {
        await calculateFrame(for: target, window: window, availableFrame: display.visibleFrame, gap: gap)
    }

    // MARK: - Multi-Monitor & AX Coordinate Inversion (US-SNAP-003)

    /// Calculates the target frame in Accessibility API coordinates on the specified display.
    public func calculateAXFrame(
        for target: SnapTarget,
        window: ManagedWindow,
        on display: Display,
        primaryScreenHeight: CGFloat,
        gap: CGFloat? = nil
    ) async -> CGRect? {
        guard let appKitFrame = await frame(for: target, window: window, on: display, gap: gap) else {
            return nil
        }
        return CoordinateTransformer.toAX(rect: appKitFrame, primaryScreenHeight: primaryScreenHeight)
    }

    /// Automatically resolves the target display and calculates target frame in Accessibility API coordinates.
    public func calculateAXFrame(
        for target: SnapTarget,
        window: ManagedWindow,
        displayManager: (any DisplayManaging)? = nil,
        cursorPoint: CGPoint? = nil,
        gap: CGFloat? = nil
    ) async -> CGRect? {
        guard let manager = displayManager ?? self.displayManager else {
            return nil
        }

        guard let targetDisplay = await manager.display(for: window.frame, cursorPoint: cursorPoint) else {
            return nil
        }

        let primaryHeight = await manager.primaryScreenHeight
        return await calculateAXFrame(
            for: target,
            window: window,
            on: targetDisplay,
            primaryScreenHeight: primaryHeight,
            gap: gap
        )
    }

    /// Moves a window to the next display in sequence, preserving its relative layout target.
    public func calculateFrameOnNextDisplay(
        for target: SnapTarget,
        window: ManagedWindow,
        displayManager: (any DisplayManaging)? = nil,
        gap: CGFloat? = nil
    ) async -> (frame: CGRect, display: Display)? {
        guard let manager = displayManager ?? self.displayManager else {
            return nil
        }

        guard let currentDisplay = await manager.display(for: window.frame, cursorPoint: nil) else {
            return nil
        }

        guard let nextDisplay = await manager.nextDisplay(after: currentDisplay) else {
            return nil
        }

        guard let targetFrame = await frame(for: target, window: window, on: nextDisplay, gap: gap) else {
            return nil
        }

        return (targetFrame, nextDisplay)
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
        case .rightHalf, .right50_50, .topRight, .bottomRight, .rightOneThird, .rightThird, .right40_60, .right20_80, .right25:
            x = availableFrame.maxX - effectiveWidth
        default:
            break
        }

        // Anchor to top edge if zone is top-aligned (in AppKit coordinates: top is maxY)
        switch zone {
        case .topHalf, .topLeft, .topRight:
            y = availableFrame.maxY - effectiveHeight
        case .bottomHalf, .bottomLeft, .bottomRight:
            y = availableFrame.minY
        default:
            break
        }

        return CGRect(x: x, y: y, width: effectiveWidth, height: effectiveHeight)
    }
}
