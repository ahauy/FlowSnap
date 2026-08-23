import SwiftUI

/// SwiftUI view rendered inside SnapPreviewPanel.
///
/// Shows a translucent rectangle indicating where the
/// window will snap to. See spec §32.
struct SnapPreviewView: View {

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.blue.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.blue.opacity(0.4), lineWidth: 2)
            )
    }
}
