import AppKit
import CoreGraphics
import Foundation

/// Manages presentation, hit-testing, and dismiss lifecycle of the Top-Edge Snap Layout Picker flyout.
///
/// Implements `SnapLayoutPickerManaging` on `@MainActor`.
@MainActor
public final class SnapLayoutPickerManager: SnapLayoutPickerManaging {

    public static let shared = SnapLayoutPickerManager()

    private let panel: SnapLayoutPickerPanel
    private let previewManager: SnapPreviewManaging
    private let layoutEngine: LayoutCalculating
    private let preferencesStore: PreferencesStore?

    private var isPresenting: Bool = false
    public private(set) var activeDisplayID: CGDirectDisplayID?
    public private(set) var currentHoveredSlot: LayoutSlot?

    public var isVisible: Bool {
        isPresenting
    }

    public var pickerFrame: CGRect? {
        isPresenting ? panel.frame : nil
    }

    public var currentTemplates: [LayoutTemplate] {
        let ratio = preferencesStore?.defaultRatio ?? .equal
        return LayoutTemplate.templates(for: ratio)
    }

    public init(
        panel: SnapLayoutPickerPanel = SnapLayoutPickerPanel(),
        previewManager: SnapPreviewManaging = SnapPreviewPanel.shared,
        layoutEngine: LayoutCalculating = LayoutEngine(),
        preferencesStore: PreferencesStore? = nil
    ) {
        self.panel = panel
        self.previewManager = previewManager
        self.layoutEngine = layoutEngine
        self.preferencesStore = preferencesStore
    }

    // MARK: - Presentation & Dismissal

    public func showPicker(on display: Display) {
        let pickerWidth: CGFloat = 430
        let pickerHeight: CGFloat = 92

        let targetX = display.visibleFrame.midX - (pickerWidth / 2.0)
        let targetY = display.visibleFrame.maxY - pickerHeight - 8

        let targetFrame = CGRect(x: targetX, y: targetY, width: pickerWidth, height: pickerHeight)
        let initialFrame = CGRect(x: targetX, y: targetY + 20, width: pickerWidth, height: pickerHeight)

        activeDisplayID = display.id
        isPresenting = true
        currentHoveredSlot = nil
        panel.updateView(hoveredSlotId: nil, templates: currentTemplates)

        panel.setFrame(initialFrame, display: true)
        panel.alphaValue = 0.0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetFrame, display: true)
            panel.animator().alphaValue = 1.0
        }
    }

    public func hidePicker(animated: Bool = true) {
        guard isPresenting else { return }

        isPresenting = false
        activeDisplayID = nil
        currentHoveredSlot = nil
        panel.updateView(hoveredSlotId: nil)

        if animated {
            let currentFrame = panel.frame
            let exitFrame = CGRect(x: currentFrame.minX, y: currentFrame.minY + 16, width: currentFrame.width, height: currentFrame.height)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().setFrame(exitFrame, display: true)
                panel.animator().alphaValue = 0.0
            } completionHandler: { [weak self] in
                guard let self else { return }
                if !self.isPresenting {
                    self.panel.orderOut(nil)
                }
            }
        } else {
            panel.alphaValue = 0.0
            panel.orderOut(nil)
        }
    }

    // MARK: - Hit-Testing

    public func hitTestSlot(at screenPoint: CGPoint) -> LayoutSlot? {
        guard isVisible else { return nil }

        let frame = panel.frame
        guard frame.contains(screenPoint) else {
            if currentHoveredSlot != nil {
                currentHoveredSlot = nil
                panel.updateView(hoveredSlotId: nil)
            }
            return nil
        }

        // Screen coordinate relative to panel origin (0...width, 0...height where (0,0) is bottom-left in AppKit)
        let localX = screenPoint.x - frame.minX
        let localYFromTop = frame.maxY - screenPoint.y // Convert to top-down coordinates

        let padding: CGFloat = 10
        let spacing: CGFloat = 12
        let cardWidth: CGFloat = 96
        let cardGeoWidth: CGFloat = 88
        let cardGeoHeight: CGFloat = 56

        let templates = currentTemplates
        var detectedSlot: LayoutSlot?

        for (index, template) in templates.enumerated() {
            let cardMinX = padding + CGFloat(index) * (cardWidth + spacing)
            let cardMaxX = cardMinX + cardWidth

            if localX >= cardMinX && localX <= cardMaxX {
                // Inside this template card column
                // Evaluate inside geometry box (top-left aligned with 4px margin)
                let geoMinX = cardMinX + ((cardWidth - cardGeoWidth) / 2.0)
                let geoMaxX = geoMinX + cardGeoWidth
                let geoMinY: CGFloat = 10 // top margin inside card
                let geoMaxY = geoMinY + cardGeoHeight

                if localX >= geoMinX && localX <= geoMaxX && localYFromTop >= geoMinY && localYFromTop <= geoMaxY {
                    let relX = (localX - geoMinX) / cardGeoWidth
                    let relY = (localYFromTop - geoMinY) / cardGeoHeight

                    for slot in template.slots {
                        let norm = slot.normalizedRect
                        if relX >= norm.minX && relX <= norm.maxX && relY >= norm.minY && relY <= norm.maxY {
                            detectedSlot = slot
                            break
                        }
                    }
                }
                break
            }
        }

        if detectedSlot != currentHoveredSlot {
            currentHoveredSlot = detectedSlot
            panel.updateView(hoveredSlotId: detectedSlot?.id, templates: currentTemplates)
        }

        return detectedSlot
    }
}
