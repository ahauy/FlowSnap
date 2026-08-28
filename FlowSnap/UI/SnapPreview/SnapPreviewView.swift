import SwiftUI

/// SwiftUI view rendered inside SnapPreviewPanel.
///
/// Shows a translucent rectangle indicating where the
/// window will snap to, with subtle macOS accent highlight. See spec §32.
public struct SnapPreviewView: View {

    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.accentColor.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.accentColor.opacity(0.45), lineWidth: 1.5)
            )
            .padding(2)
    }
}
