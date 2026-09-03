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
    private let windowGroupManager: WindowGroupManager?
    private let presetResolver: (any PresetResolving)?
    private let commandDispatcher: CommandDispatcher?

    public init(
        store: PreferencesStore? = nil,
        workspaceManager: WorkspaceManager? = nil,
        windowGroupManager: WindowGroupManager? = nil,
        presetResolver: (any PresetResolving)? = nil,
        commandDispatcher: CommandDispatcher? = nil
    ) {
        self.store = store ?? PreferencesStore()
        self.workspaceManager = workspaceManager
        self.windowGroupManager = windowGroupManager
        self.presetResolver = presetResolver
        self.commandDispatcher = commandDispatcher
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

            PresetGalleryView(
                store: store,
                presetResolver: presetResolver,
                commandDispatcher: commandDispatcher
            )
            .tabItem {
                Label("Presets", systemImage: "square.grid.2x2")
            }

            if let windowGroupManager {
                WindowGroupSettingsView(manager: windowGroupManager)
                    .tabItem {
                        Label("Window Groups", systemImage: "rectangle.3.group")
                    }
            }

            ApplicationRulesView(store: store)
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
