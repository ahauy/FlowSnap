import SwiftUI

/// Main settings window with 4 tab navigation.
///
/// Traces to: US-SNAP-010, spec §41.
public struct SettingsView: View {

    @ObservedObject var store: PreferencesStore

    /// Optional so existing callers (and snapshot tests) that build
    /// `SettingsView(store:)` keep working; the "Workspaces" tab hides itself
    /// when this is `nil`.
    private let workspaceManager: WorkspaceManager?

    public init(store: PreferencesStore? = nil, workspaceManager: WorkspaceManager? = nil) {
        self.store = store ?? PreferencesStore()
        self.workspaceManager = workspaceManager
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

            if let workspaceManager {
                WorkspaceSettingsView(manager: workspaceManager)
                    .tabItem {
                        Label("Workspaces", systemImage: "square.stack.3d.up")
                    }
            }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 540, idealWidth: 580, maxWidth: 650, minHeight: 440, idealHeight: 480, maxHeight: 560)
    }
}
