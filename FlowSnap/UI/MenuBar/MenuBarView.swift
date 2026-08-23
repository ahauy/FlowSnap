import SwiftUI

/// Menu bar dropdown UI for FlowSnap.
///
/// Shows quick access to snap actions, layouts, workspaces,
/// and settings. See spec §22.
struct MenuBarView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // TODO: Snap actions section
            // TODO: Layouts section
            // TODO: Workspaces section

            Divider()

            // TODO: Settings link
            // TODO: Quit button
            Text("FlowSnap")
                .font(.headline)
        }
        .padding()
    }
}
