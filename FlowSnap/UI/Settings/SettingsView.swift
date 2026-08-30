import SwiftUI

/// Main settings window with 4 tab navigation.
///
/// Traces to: US-SNAP-010, spec §41.
public struct SettingsView: View {

    @ObservedObject var store: PreferencesStore

    public init(store: PreferencesStore? = nil) {
        self.store = store ?? PreferencesStore()
    }

    public var body: some View {
        TabView {
            GeneralSettingsView(store: store)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ShortcutSettingsView(store: store)
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            ApplicationRulesView()
                .tabItem {
                    Label("App Rules", systemImage: "app.badge.checkmark")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 540, idealWidth: 580, maxWidth: 650, minHeight: 440, idealHeight: 480, maxHeight: 560)
    }
}
