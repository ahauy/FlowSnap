import SwiftUI

/// FlowSnap Lab — Debug & testing application.
///
/// A separate target for validating Accessibility, window control,
/// and display detection before building the production UI.
/// See spec §56.
///
/// Goals:
/// 1. Detect focused window
/// 2. Read window frame
/// 3. Identify monitor
/// 4. Move window
/// 5. Resize window
/// 6. Detect application launch
@main
struct FlowSnapLabApp: App {
    var body: some Scene {
        WindowGroup {
            FlowSnapLabView()
        }
    }
}

/// Lab UI for testing core functionality.
struct FlowSnapLabView: View {

    @State private var statusText = "Ready"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FlowSnap Lab")
                .font(.largeTitle)
                .fontWeight(.bold)

            GroupBox("Status") {
                VStack(alignment: .leading, spacing: 8) {
                    // TODO: Show Accessibility permission status
                    // TODO: Show focused app name
                    // TODO: Show focused window title
                    // TODO: Show window frame
                    // TODO: Show current display
                    Text(statusText)
                        .font(.system(.body, design: .monospaced))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Actions") {
                HStack(spacing: 12) {
                    // TODO: Snap Left / Right buttons
                    // TODO: Maximize / Restore buttons
                    // TODO: Test Launch Detection button
                    Button("Snap Left") { /* TODO */ }
                    Button("Snap Right") { /* TODO */ }
                    Button("Maximize") { /* TODO */ }
                    Button("Restore") { /* TODO */ }
                }
            }
        }
        .padding(24)
        .frame(width: 480, height: 360)
    }
}
