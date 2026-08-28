import AppKit
import SwiftUI

/// Transparent overlay window for showing snap preview and highlight flash.
///
/// Uses NSPanel (non-activating, always on top) so it doesn't
/// steal focus from the window being dragged or snapped. See spec §32.
@MainActor
public final class SnapPreviewPanel: NSPanel {

    public static let shared = SnapPreviewPanel()

    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        level = .floating
        ignoresMouseEvents = true
        hasShadow = false
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: SnapPreviewView())
    }

    /// Flash an accent outline over the snapped region and fade out smoothly.
    public func flash(frame: CGRect, duration: TimeInterval = 0.25) {
        setFrame(frame, display: true)
        alphaValue = 0.85
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
        }
    }
}
