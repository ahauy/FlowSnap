import AppKit
import CoreGraphics
import SwiftUI

/// Non-activating floating NSPanel hosting the SwiftUI SnapLayoutPickerView.
///
/// Designed to sit directly below the macOS Menu Bar when triggered.
/// Never steals window focus or disrupts ongoing mouse drag operations.
@MainActor
public final class SnapLayoutPickerPanel: NSPanel {

    private var hostingView: NSHostingView<SnapLayoutPickerView>?

    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating + 1
        ignoresMouseEvents = false
        hasShadow = false
        isReleasedWhenClosed = false

        updateView(hoveredSlotId: nil)
    }

    /// Updates the hosted SwiftUI view with the current hovered slot state and layout templates.
    public func updateView(hoveredSlotId: String?, templates: [LayoutTemplate] = LayoutTemplate.standardTemplates) {
        let view = SnapLayoutPickerView(
            templates: templates,
            hoveredSlotId: hoveredSlotId
        )
        if let hostingView {
            hostingView.rootView = view
        } else {
            let host = NSHostingView(rootView: view)
            self.hostingView = host
            contentView = host
        }
    }
}
