import SwiftUI

/// General preferences: gaps, launch at login, etc.
struct GeneralSettingsView: View {

    var body: some View {
        Form {
            // TODO: Window gap slider (spec §18)
            // TODO: Launch at login toggle
            // TODO: Show in menu bar toggle
            Text("General Settings")
                .font(.title2)
        }
        .padding()
    }
}
