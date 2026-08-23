import AppKit

/// Transparent overlay window for showing snap preview.
///
/// Uses NSPanel (non-activating, always on top) so it doesn't
/// steal focus from the window being dragged. See spec §32.
final class SnapPreviewPanel: NSPanel {

    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // TODO: Configure panel properties
        // - isOpaque = false
        // - backgroundColor = .clear
        // - level = .floating
        // - ignoresMouseEvents = true
        // - hasShadow = false
    }

    /// Show the preview at a given frame on screen.
    func showPreview(frame: CGRect) {
        // TODO: Position panel, animate in
    }

    /// Hide the preview with animation.
    func hidePreview() {
        // TODO: Animate out, orderOut
    }
}
