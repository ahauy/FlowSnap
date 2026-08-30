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

    public static let restingAlpha: CGFloat = 0.22
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
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        contentView = view
    }

    /// Displays or smoothly updates the overlay panel over the specified display container.
    public func show(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
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
            isDragging: isDragging
        )

        let targetAlpha: CGFloat = (activeDivider != nil || isDragging) ? Self.activeAlpha : Self.restingAlpha

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
            isDragging: isDragging
        )

        let targetAlpha: CGFloat = (activeDivider != nil || isDragging) ? Self.activeAlpha : Self.restingAlpha

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
    public private(set) var isDragging: Bool = false

    // MARK: - Direct Drag Callbacks

    public var onDirectMouseDown: ((CGPoint, CollinearEdge) -> Void)?
    public var onDirectMouseDragged: ((CGPoint) -> Void)?
    public var onDirectMouseUp: ((CGPoint) -> Void)?
    public var onDirectMouseMoved: ((CGPoint) -> Void)?

    // MARK: - Layer Hierarchy

    private let windowBordersContainerLayer = CALayer()
    private let dividersContainerLayer = CALayer()

    // MARK: - Constants

    public static let seamThickness: CGFloat = 10.0
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
    }

    // MARK: - State Updates & Rendering

    public func updateState(
        containerFrame: CGRect,
        windows: [ManagedWindow],
        dividers: [CollinearEdge],
        activeDivider: CollinearEdge?,
        isDragging: Bool
    ) {
        self.containerFrame = containerFrame
        self.windows = windows
        self.dividers = dividers
        self.activeDivider = activeDivider
        self.isDragging = isDragging

        // Disable implicit layer animations for 120Hz ProMotion responsiveness
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        renderWindowOutlines()
        renderDividerSeams()

        CATransaction.commit()

        window?.invalidateCursorRects(for: self)
    }

    private func renderWindowOutlines() {
        windowBordersContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        // 1. Full Screen / Desktop Workspace Container Border Outline
        let containerBorder = CAShapeLayer()
        let containerInsetRect = bounds.insetBy(
            dx: Self.hairlineBorderWidth / 2.0,
            dy: Self.hairlineBorderWidth / 2.0
        )
        containerBorder.path = CGPath(
            roundedRect: containerInsetRect,
            cornerWidth: 12.0,
            cornerHeight: 12.0,
            transform: nil
        )
        containerBorder.fillColor = nil
        containerBorder.strokeColor = NSColor.controlAccentColor.withAlphaComponent(0.45).cgColor
        containerBorder.lineWidth = Self.hairlineBorderWidth * 1.5
        windowBordersContainerLayer.addSublayer(containerBorder)

        // 2. Individual Window Outlines
        for window in windows {
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
            let barLayer = CALayer()
            let handleLayer = CALayer()

            switch divider.orientation {
            case .vertical:
                let localX = divider.coordinate - containerFrame.minX
                let minY = divider.span.lowerBound - containerFrame.minY
                let maxY = divider.span.upperBound - containerFrame.minY
                let spanLength = max(1.0, maxY - minY)

                let barRect = CGRect(
                    x: localX - Self.accentBarThickness / 2.0,
                    y: minY + 4.0,
                    width: Self.accentBarThickness,
                    height: max(1.0, spanLength - 8.0)
                )
                barLayer.frame = barRect
                barLayer.cornerRadius = Self.accentBarThickness / 2.0

                let centerY = (minY + maxY) / 2.0
                handleLayer.frame = CGRect(
                    x: localX - Self.handleThickness / 2.0,
                    y: centerY - Self.handleLength / 2.0,
                    width: Self.handleThickness,
                    height: Self.handleLength
                )
                handleLayer.cornerRadius = Self.handleThickness / 2.0

            case .horizontal:
                let localY = divider.coordinate - containerFrame.minY
                let minX = divider.span.lowerBound - containerFrame.minX
                let maxX = divider.span.upperBound - containerFrame.minX
                let spanLength = max(1.0, maxX - minX)

                let barRect = CGRect(
                    x: minX + 4.0,
                    y: localY - Self.accentBarThickness / 2.0,
                    width: max(1.0, spanLength - 8.0),
                    height: Self.accentBarThickness
                )
                barLayer.frame = barRect
                barLayer.cornerRadius = Self.accentBarThickness / 2.0

                let centerX = (minX + maxX) / 2.0
                handleLayer.frame = CGRect(
                    x: centerX - Self.handleLength / 2.0,
                    y: localY - Self.handleThickness / 2.0,
                    width: Self.handleLength,
                    height: Self.handleThickness
                )
                handleLayer.cornerRadius = Self.handleThickness / 2.0
            }

            // Accent bar glowing styling
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

            dividersContainerLayer.addSublayer(barLayer)
            dividersContainerLayer.addSublayer(handleLayer)
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

    /// Transparent pass-through hit testing: returns `self` only when over an interactive seam or dragging.
    public override func hitTest(_ point: NSPoint) -> NSView? {
        if isDragging {
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
        if let divider = hitTestDivider(at: localPoint) {
            let cursor: NSCursor = (divider.orientation == .vertical) ? .resizeLeftRight : .resizeUpDown
            cursor.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    // MARK: - Direct Mouse Events

    public override func mouseDown(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)
        guard let divider = hitTestDivider(at: localPoint) else {
            super.mouseDown(with: event)
            return
        }

        isDragging = true
        activeDivider = divider
        let screenPoint = convertToScreen(localPoint)

        updateState(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: divider,
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
        let remainingHover = hitTestDivider(at: localPoint)
        activeDivider = remainingHover

        updateState(
            containerFrame: containerFrame,
            windows: windows,
            dividers: dividers,
            activeDivider: remainingHover,
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
        CGPoint(
            x: localPoint.x + containerFrame.minX,
            y: localPoint.y + containerFrame.minY
        )
    }
}
