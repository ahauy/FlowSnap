import SwiftUI

/// Main settings window with tab navigation.
///
/// See spec §41.
struct SettingsView: View {

    var store: PreferencesStore?

    var body: some View {
        TabView {
            GeneralSettingsView(store: store ?? PreferencesStore())
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ShortcutSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            ApplicationRulesView()
                .tabItem {
                    Label("App Rules", systemImage: "app.badge.checkmark")
                }
        }
        .frame(width: 500, height: 400)
    }
}
