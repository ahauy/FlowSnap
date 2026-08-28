import AppKit
import QuartzCore

/// GPU-accelerated frosted glass ghost overlay.
///
/// Smoothly morphs from a window's current frame to the target snap frame
/// using Core Animation at native display refresh rate (60Hz / 120Hz ProMotion).
@MainActor
public final class GhostMorphPanel: NSPanel {

    public static let shared = GhostMorphPanel()

    private let visualEffectView: NSVisualEffectView

    public init() {
        self.visualEffectView = NSVisualEffectView()

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
        hasShadow = true
        isReleasedWhenClosed = false

        // Configure frosted glass backdrop
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1.5
        visualEffectView.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.6).cgColor

        contentView = visualEffectView
    }

    /// Perform a smooth GPU-accelerated morph from startFrame to targetFrame.
    public func morph(
        from startFrame: CGRect,
        to targetFrame: CGRect,
        glideDuration: TimeInterval = 0.15,
        fadeDuration: TimeInterval = 0.10
    ) async {
        // Position immediately at the starting window frame
        setFrame(startFrame, display: true)
        alphaValue = 0.85
        orderFrontRegardless()

        await withCheckedContinuation { continuation in
            NSAnimationContext.runAnimationGroup { context in
                context.duration = glideDuration
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                context.allowsImplicitAnimation = true
                self.animator().setFrame(targetFrame, display: true)
            } completionHandler: {
                NSAnimationContext.runAnimationGroup { fadeContext in
                    fadeContext.duration = fadeDuration
                    fadeContext.timingFunction = CAMediaTimingFunction(name: .easeOut)
                    self.animator().alphaValue = 0.0
                } completionHandler: { [weak self] in
                    self?.orderOut(nil)
                    continuation.resume()
                }
            }
        }
    }
}
