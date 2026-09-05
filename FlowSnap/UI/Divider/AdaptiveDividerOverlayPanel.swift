import AppKit
import CoreGraphics
import QuartzCore

/// High-performance floating overlay panel displaying window hairline boundaries and interactive divider seams.
///
/// Features:
/// - 1.5px hairline outlines around snapped windows on the active display.
/// - 8-10px interactive divider seams with 2-3px glowing accent bars that illuminate on hover/drag.
/// - Native `NSCursor.resizeLeftRight` and `NSCursor.resizeUpDown` cursor rects and tracking areas.
/// - Direct mouse drag handling that coordinates with `AdaptiveDividerCoordinator`.
/// - Strict multi-monitor boundary isolation and pass-through hit testing outside interactive seams.
@MainActor
public final class AdaptiveDividerOverlayPanel: NSPanel, AdaptiveDividerOverlayManaging {

    public static let shared = AdaptiveDividerOverlayPanel()

    public static let restingAlpha: CGFloat = 0.0
    public static let activeAlpha: CGFloat = 1.0

    public let overlayView: AdaptiveDividerOverlayView

    public var isOverlayVisible: Bool {
        isVisible && alphaValue > 0.01
    }

    public init() {
        let view = AdaptiveDividerOverlayView(frame: .zero)
        self.overlayView = view

        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating + 1
        hasShadow = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = view
    }

    /// Displays or smoothly updates the overlay panel over the specified display container.
    public func show(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        activeJunction: CrossJunction? = nil,
        isDragging: Bool
    ) {
        guard activeDivider != nil || activeJunction != nil || isDragging else {
            hide(animated: true)
            return
        }

        if frame != containerFrame {
            setFrame(containerFrame, display: true)
        }

        overlayView.updateState(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: activeDivider,
            activeJunction: activeJunction,
            isDragging: isDragging
        )

        let targetAlpha: CGFloat = Self.activeAlpha

        if !isVisible {
            alphaValue = targetAlpha
            orderFrontRegardless()
        } else if isDragging {
            alphaValue = targetAlpha
        } else if abs(alphaValue - targetAlpha) > 0.01 {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().alphaValue = targetAlpha
            }
        }
    }

    /// Updates the overlay layout in real time during live dragging.
    public func update(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        activeJunction: CrossJunction? = nil,
        isDragging: Bool
    ) {
        if frame != containerFrame {
            setFrame(containerFrame, display: true)
        }

        overlayView.updateState(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: activeDivider,
            activeJunction: activeJunction,
            isDragging: isDragging
        )

        let targetAlpha: CGFloat = (activeDivider != nil || activeJunction != nil || isDragging) ? Self.activeAlpha : Self.restingAlpha

        if !isVisible {
            alphaValue = targetAlpha
            orderFrontRegardless()
        } else if isDragging || abs(alphaValue - targetAlpha) <= 0.01 {
            alphaValue = targetAlpha
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().alphaValue = targetAlpha
            }
        }
    }

    /// Dismisses the overlay panel with an optional smooth fade-out animation.
    public func hide(animated: Bool = true) {
        guard isVisible else { return }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().alphaValue = 0.0
            } completionHandler: { [weak self] in
                guard let self else { return }
                if self.alphaValue <= 0.01 {
                    self.orderOut(nil)
                }
            }
        } else {
            alphaValue = 0.0
            orderOut(nil)
        }
    }
}

/// Custom AppKit view rendering window outlines and interactive divider seams with native cursor tracking.
@MainActor
public final class AdaptiveDividerOverlayView: NSView {

    // MARK: - State

    public private(set) var containerFrame: CGRect = .zero
    public private(set) var windows: [ManagedWindow] = []
    public private(set) var dividers: [CollinearEdge] = []
    public private(set) var activeDivider: CollinearEdge?
    public private(set) var activeJunction: CrossJunction?
    public private(set) var isDragging: Bool = false

    // MARK: - Direct Drag Callbacks

    public var onDirectMouseDown: ((CGPoint, CollinearEdge?) -> Void)?
    public var onDirectMouseDragged: ((CGPoint) -> Void)?
    public var onDirectMouseUp: ((CGPoint) -> Void)?
    public var onDirectMouseMoved: ((CGPoint) -> Void)?

    // MARK: - Layer Hierarchy

    private let windowBordersContainerLayer = CALayer()
    private let dividersContainerLayer = CALayer()
    private let junctionsContainerLayer = CALayer()

    // MARK: - Constants

    public static let seamThickness: CGFloat = 18.0
    public static let accentBarThickness: CGFloat = 3.0
    public static let hairlineBorderWidth: CGFloat = 1.5
    public static let windowCornerRadius: CGFloat = 10.0
    public static let handleLength: CGFloat = 36.0
    public static let handleThickness: CGFloat = 4.0

    // MARK: - Initialization

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.addSublayer(windowBordersContainerLayer)
        layer?.addSublayer(dividersContainerLayer)
        layer?.addSublayer(junctionsContainerLayer)
    }

    // MARK: - State Updates & Rendering

    public func updateState(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        activeJunction: CrossJunction? = nil,
        isDragging: Bool
    ) {
        self.containerFrame = containerFrame
        self.windows = windows
        self.dividers = dividers
        self.activeDivider = activeDivider
        self.activeJunction = activeJunction
        self.isDragging = isDragging

        // Disable implicit layer animations for 120Hz ProMotion responsiveness
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        renderWindowOutlines()
        renderDividerSeams()
        renderJunctionHandle()

        CATransaction.commit()

        window?.invalidateCursorRects(for: self)
    }

    private func renderWindowOutlines() {
        windowBordersContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // Only outline primary windows that directly participate in divider seams,
        // preventing unwanted outlines around child/floating panels (e.g. Antigravity chat popup)
        let seamWindowIDs = Set(dividers.flatMap { $0.leadingWindowIDs + $0.trailingWindowIDs })
        let targetWindows = seamWindowIDs.isEmpty ? windows : windows.filter { seamWindowIDs.contains($0.id) }

        for window in targetWindows {
            let localRect = window.frame.offsetBy(
                dx: -containerFrame.minX,
                dy: -containerFrame.minY
            )
            guard localRect.width > 20, localRect.height > 20 else { continue }

            let shapeLayer = CAShapeLayer()
            // Inset by half hairline border width for pixel-crisp rendering
            let insetRect = localRect.insetBy(
                dx: Self.hairlineBorderWidth / 2.0,
                dy: Self.hairlineBorderWidth / 2.0
            )
            shapeLayer.path = CGPath(
                roundedRect: insetRect,
                cornerWidth: Self.windowCornerRadius,
                cornerHeight: Self.windowCornerRadius,
                transform: nil
            )
            shapeLayer.fillColor = nil
            shapeLayer.strokeColor = NSColor.controlAccentColor.withAlphaComponent(0.35).cgColor
            shapeLayer.lineWidth = Self.hairlineBorderWidth
            windowBordersContainerLayer.addSublayer(shapeLayer)
        }
    }

    private func renderDividerSeams() {
        dividersContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        for divider in dividers {
            let isActive = (activeDivider != nil && divider.id == activeDivider?.id)
            let (barLayer, handleLayer) = makeDividerLayers(for: divider, isActive: isActive)
            dividersContainerLayer.addSublayer(barLayer)
            dividersContainerLayer.addSublayer(handleLayer)
        }
    }

    private func renderJunctionHandle() {
        junctionsContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard let junction = activeJunction else { return }

        let localX = junction.point.x - containerFrame.minX
        let localY = junction.point.y - containerFrame.minY

        let handleRadius: CGFloat = 10.0
        let handleRect = CGRect(
            x: localX - handleRadius,
            y: localY - handleRadius,
            width: handleRadius * 2.0,
            height: handleRadius * 2.0
        )

        let ringLayer = CAShapeLayer()
        ringLayer.frame = handleRect
        ringLayer.path = CGPath(ellipseIn: CGRect(origin: .zero, size: handleRect.size), transform: nil)
        ringLayer.fillColor = NSColor.controlAccentColor.cgColor
        ringLayer.shadowColor = NSColor.controlAccentColor.cgColor
        ringLayer.shadowOpacity = isDragging ? 1.0 : 0.85
        ringLayer.shadowRadius = isDragging ? 7.0 : 5.0
        ringLayer.shadowOffset = .zero

        let innerRadius: CGFloat = 4.0
        let innerDot = CAShapeLayer()
        innerDot.frame = CGRect(
            x: handleRadius - innerRadius,
            y: handleRadius - innerRadius,
            width: innerRadius * 2.0,
            height: innerRadius * 2.0
        )
        innerDot.path = CGPath(ellipseIn: CGRect(origin: .zero, size: CGSize(width: innerRadius * 2, height: innerRadius * 2)), transform: nil)
        innerDot.fillColor = NSColor.white.cgColor
        ringLayer.addSublayer(innerDot)

        junctionsContainerLayer.addSublayer(ringLayer)
    }

    private func makeDividerLayers(
        for divider: CollinearEdge,
        isActive: Bool
    ) -> (barLayer: CALayer, handleLayer: CALayer) {
        let barLayer = CALayer()
        let handleLayer = CALayer()

        let (barRect, handleRect) = computeBarAndHandleRects(for: divider)
        barLayer.frame = barRect
        barLayer.cornerRadius = Self.accentBarThickness / 2.0
        handleLayer.frame = handleRect
        handleLayer.cornerRadius = Self.handleThickness / 2.0

        applyDividerLayerStyling(barLayer: barLayer, handleLayer: handleLayer, isActive: isActive)
        return (barLayer, handleLayer)
    }

    private func computeBarAndHandleRects(
        for divider: CollinearEdge
    ) -> (barRect: CGRect, handleRect: CGRect) {
        switch divider.orientation {
        case .vertical:
            let localX = divider.coordinate - containerFrame.minX
            let minY = divider.span.lowerBound - containerFrame.minY
            let maxY = divider.span.upperBound - containerFrame.minY
            let spanLength = max(1.0, maxY - minY)
            let centerY = (minY + maxY) / 2.0

            let barRect = CGRect(
                x: localX - Self.accentBarThickness / 2.0,
                y: minY + 4.0,
                width: Self.accentBarThickness,
                height: max(1.0, spanLength - 8.0)
            )
            let handleRect = CGRect(
                x: localX - Self.handleThickness / 2.0,
                y: centerY - Self.handleLength / 2.0,
                width: Self.handleThickness,
                height: Self.handleLength
            )
            return (barRect, handleRect)

        case .horizontal:
            let localY = divider.coordinate - containerFrame.minY
            let minX = divider.span.lowerBound - containerFrame.minX
            let maxX = divider.span.upperBound - containerFrame.minX
            let spanLength = max(1.0, maxX - minX)
            let centerX = (minX + maxX) / 2.0

            let barRect = CGRect(
                x: minX + 4.0,
                y: localY - Self.accentBarThickness / 2.0,
                width: max(1.0, spanLength - 8.0),
                height: Self.accentBarThickness
            )
            let handleRect = CGRect(
                x: centerX - Self.handleLength / 2.0,
                y: localY - Self.handleThickness / 2.0,
                width: Self.handleLength,
                height: Self.handleThickness
            )
            return (barRect, handleRect)
        }
    }

    private func applyDividerLayerStyling(barLayer: CALayer, handleLayer: CALayer, isActive: Bool) {
        if isActive {
            barLayer.backgroundColor = NSColor.controlAccentColor.cgColor
            barLayer.shadowColor = NSColor.controlAccentColor.cgColor
            barLayer.shadowOpacity = isDragging ? 0.95 : 0.85
            barLayer.shadowRadius = isDragging ? 6.0 : 4.5
            barLayer.shadowOffset = .zero
            barLayer.opacity = 1.0

            handleLayer.backgroundColor = NSColor.white.cgColor
            handleLayer.shadowColor = NSColor.black.withAlphaComponent(0.5).cgColor
            handleLayer.shadowOpacity = 0.6
            handleLayer.shadowRadius = 2.5
            handleLayer.shadowOffset = .zero
            handleLayer.opacity = 1.0
        } else {
            barLayer.backgroundColor = NSColor.white.withAlphaComponent(0.3).cgColor
            barLayer.shadowOpacity = 0.0
            barLayer.opacity = 0.4

            handleLayer.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
            handleLayer.shadowOpacity = 0.0
            handleLayer.opacity = 0.0
        }
    }

    // MARK: - Geometry & Hit Testing

    /// Computes the 8-10px interactive seam bounding rectangle in local view coordinates.
    public func computeSeamRect(for divider: CollinearEdge) -> CGRect {
        let halfThickness = Self.seamThickness / 2.0

        switch divider.orientation {
        case .vertical:
            let localX = divider.coordinate - containerFrame.minX
            let minY = divider.span.lowerBound - containerFrame.minY
            let height = max(1.0, divider.span.upperBound - divider.span.lowerBound)
            return CGRect(
                x: localX - halfThickness,
                y: minY,
                width: Self.seamThickness,
                height: height
            )

        case .horizontal:
            let localY = divider.coordinate - containerFrame.minY
            let minX = divider.span.lowerBound - containerFrame.minX
            let width = max(1.0, divider.span.upperBound - divider.span.lowerBound)
            return CGRect(
                x: minX,
                y: localY - halfThickness,
                width: width,
                height: Self.seamThickness
            )
        }
    }

    /// Hit-tests a point against all available divider seam hit rectangles.
    public func hitTestDivider(at localPoint: NSPoint) -> CollinearEdge? {
        for divider in dividers {
            let seamRect = computeSeamRect(for: divider)
            if seamRect.contains(localPoint) {
                return divider
            }
        }
        return nil
    }

    /// Hit-tests a point against the active junction hit area.
    public func hitTestJunction(at localPoint: NSPoint) -> CrossJunction? {
        guard let junction = activeJunction else { return nil }
        let screenPoint = convertToScreen(localPoint)
        return junction.contains(screenPoint) ? junction : nil
    }

    /// Transparent pass-through hit testing: returns `self` only when over an interactive seam, junction, or dragging.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        if isDragging {
            return self
        }
        if hitTestJunction(at: point) != nil {
            return self
        }
        for divider in dividers {
            let seamRect = computeSeamRect(for: divider)
            if seamRect.contains(point) {
                return self
            }
        }
        return nil
    }

    // MARK: - Cursor Rects & Tracking Areas

    public override func resetCursorRects() {
        super.resetCursorRects()
        if let junction = activeJunction {
            let localX = junction.point.x - containerFrame.minX
            let localY = junction.point.y - containerFrame.minY
            let r = junction.hitRadius
            let junctionRect = CGRect(x: localX - r, y: localY - r, width: r * 2.0, height: r * 2.0)
            addCursorRect(junctionRect, cursor: .crosshair)
        }

        guard !dividers.isEmpty else { return }

        for divider in dividers {
            let seamRect = computeSeamRect(for: divider)
            let cursor: NSCursor = (divider.orientation == .vertical) ? .resizeLeftRight : .resizeUpDown
            addCursorRect(seamRect, cursor: cursor)
        }
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .cursorUpdate, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }

    public override func cursorUpdate(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        if hitTestJunction(at: localPoint) != nil {
            NSCursor.crosshair.set()
        } else if let divider = hitTestDivider(at: localPoint) {
            let cursor: NSCursor = (divider.orientation == .vertical) ? .resizeLeftRight : .resizeUpDown
            cursor.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    // MARK: - Direct Mouse Events

    public override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        let screenPoint = convertToScreen(localPoint)

        if let junction = hitTestJunction(at: localPoint) {
            isDragging = true
            activeJunction = junction
            activeDivider = nil

            updateState(
                containerFrame: containerFrame,
                windows: windows,
                dividers: dividers,
                activeDivider: nil,
                activeJunction: junction,
                isDragging: true
            )

            onDirectMouseDown?(screenPoint, nil)
            return
        }

        guard let divider = hitTestDivider(at: localPoint) else {
            super.mouseDown(with: event)
            return
        }

        isDragging = true
        activeDivider = divider
        activeJunction = nil

        updateState(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: divider,
            activeJunction: nil,
            isDragging: true
        )

        onDirectMouseDown?(screenPoint, divider)
    }

    public override func mouseDragged(with event: NSEvent) {
        guard isDragging else {
            super.mouseDragged(with: event)
            return
        }

        let localPoint = convert(event.locationInWindow, from: nil)
        let screenPoint = convertToScreen(localPoint)
        onDirectMouseDragged?(screenPoint)
    }

    public override func mouseUp(with event: NSEvent) {
        guard isDragging else {
            super.mouseUp(with: event)
            return
        }

        isDragging = false
        let localPoint = convert(event.locationInWindow, from: nil)
        let screenPoint = convertToScreen(localPoint)
        let remainingJunction = hitTestJunction(at: localPoint)
        let remainingDivider = remainingJunction == nil ? hitTestDivider(at: localPoint) : nil
        activeJunction = remainingJunction
        activeDivider = remainingDivider

        updateState(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: remainingDivider,
            activeJunction: remainingJunction,
            isDragging: false
        )

        onDirectMouseUp?(screenPoint)
        window?.invalidateCursorRects(for: self)
    }

    public override func mouseMoved(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        let screenPoint = convertToScreen(localPoint)
        onDirectMouseMoved?(screenPoint)
    }

    private func convertToScreen(_ localPoint: NSPoint) -> CGPoint {
        // BUG-06: use NSWindow's coordinate conversion to correctly handle multi-monitor
        // setups where containerFrame.minX may be negative (display left of primary).
        if let screenPoint = window?.convertPoint(toScreen: localPoint) {
            return CGPoint(x: screenPoint.x, y: screenPoint.y)
        }
        // Fallback before panel is attached to a window (e.g. during unit tests).
        return CGPoint(
            x: localPoint.x + containerFrame.minX,
            y: localPoint.y + containerFrame.minY
        )
    }
}
