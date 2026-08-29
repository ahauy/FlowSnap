import AppKit
import CoreGraphics
import SwiftUI

/// Transparent overlay window for displaying real-time snap zone preview and highlight flash.
///
/// Uses `NSPanel` (.borderless, .nonactivatingPanel, level: .floating, ignoresMouseEvents: true)
/// so it never steals focus from the active window being dragged or snapped. Conforms to `SnapPreviewManaging`.
@MainActor
public final class SnapPreviewPanel: NSPanel, SnapPreviewManaging {

    public static let shared = SnapPreviewPanel()

    public var isPreviewVisible: Bool {
        isVisible && alphaValue > 0.01
    }

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

    /// Displays the preview overlay at the target frame with smooth animation.
    public func showPreview(frame: CGRect, displayID: CGDirectDisplayID) {
        if isPreviewVisible {
            // Smoothly morph frame to the new zone
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().setFrame(frame, display: true)
                animator().alphaValue = 1.0
            }
        } else {
            // Fresh presentation: set initial frame, start transparent, and fade in
            setFrame(frame, display: true)
            alphaValue = 0.0
            orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().alphaValue = 1.0
            }
        }
    }

    /// Hides the preview overlay, optionally with a smooth fade-out animation.
    public func hidePreview(animated: Bool = true) {
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

    /// Flash an accent outline over the snapped region and fade out smoothly.
    public func flashSnapSuccess(frame: CGRect) {
        setFrame(frame, display: true)
        alphaValue = 0.85
        orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
        }
    }
}
