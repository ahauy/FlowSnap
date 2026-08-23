import SwiftUI

/// Keyboard shortcut configuration.
///
/// See spec §8.
struct ShortcutSettingsView: View {

    var body: some View {
        Form {
            // TODO: List of configurable shortcuts
            // TODO: Default shortcuts (⌃⌥← → ↑ ↓, ⌃⌥1234)
            // TODO: Custom shortcut recorder
            Text("Shortcut Settings")
                .font(.title2)
        }
        .padding()
    }
}
