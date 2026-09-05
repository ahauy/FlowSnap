import SwiftUI

/// Canonical tabs available in the FlowSnap Settings window.
public enum SettingsTab: String, CaseIterable, Identifiable, Sendable {
    case general = "General"
    case shortcuts = "Shortcuts"
    case presets = "Presets"
    case windowGroups = "Window Groups"
    case appRules = "App Rules"
    case workspaces = "Workspaces"
    case about = "About"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .shortcuts: return "keyboard.fill"
        case .presets: return "square.grid.2x2.fill"
        case .windowGroups: return "rectangle.3.group.fill"
        case .appRules: return "app.badge.checkmark.fill"
        case .workspaces: return "square.stack.3d.up.fill"
        case .about: return "info.circle.fill"
        }
    }

    public var iconColor: Color {
        switch self {
        case .general: return .gray
        case .shortcuts: return .blue
        case .presets: return .purple
        case .windowGroups: return .indigo
        case .appRules: return .orange
        case .workspaces: return .teal
        case .about: return .secondary
        }
    }
}

/// Main settings window with macOS modern sidebar navigation.
///
/// Traces to: US-SNAP-010, REQ-MENU-009, spec §41.
public struct SettingsView: View {

    @ObservedObject var store: PreferencesStore

    /// Optional so existing callers (and snapshot tests) that build
    /// `SettingsView(store:)` keep working; dynamic tabs hide themselves
    /// when the respective manager is `nil`.
    private let workspaceManager: WorkspaceManager?
    private let windowGroupManager: WindowGroupManager?
    private let presetResolver: (any PresetResolving)?
    private let commandDispatcher: CommandDispatcher?

    @State private var selectedTab: SettingsTab?

    public init(
        store: PreferencesStore? = nil,
        workspaceManager: WorkspaceManager? = nil,
        windowGroupManager: WindowGroupManager? = nil,
        presetResolver: (any PresetResolving)? = nil,
        commandDispatcher: CommandDispatcher? = nil,
        initialTab: SettingsTab = .general
    ) {
        self.store = store ?? PreferencesStore()
        self.workspaceManager = workspaceManager
        self.windowGroupManager = windowGroupManager
        self.presetResolver = presetResolver
        self.commandDispatcher = commandDispatcher
        self._selectedTab = State(initialValue: initialTab)
    }

    private var availableTabs: [SettingsTab] {
        var tabs: [SettingsTab] = [.general, .shortcuts, .presets]
        if windowGroupManager != nil {
            tabs.append(.windowGroups)
        }
        tabs.append(.appRules)
        if workspaceManager != nil {
            tabs.append(.workspaces)
        }
        tabs.append(.about)
        return tabs
    }

    public var body: some View {
        NavigationSplitView {
            List(availableTabs, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 13))
                            .foregroundStyle(tab.iconColor)
                            .frame(width: 18)

                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 195, max: 220)
            .listStyle(.sidebar)
        } detail: {
            detailView(for: selectedTab ?? .general)
                .frame(minWidth: 460)
        }
        .frame(minWidth: 680, idealWidth: 720, maxWidth: 840, minHeight: 480, idealHeight: 520, maxHeight: 720)
    }

    @ViewBuilder
    private func detailView(for tab: SettingsTab) -> some View {
        switch tab {
        case .general:
            GeneralSettingsView(store: store)
        case .shortcuts:
            ShortcutSettingsView(store: store)
        case .presets:
            PresetGalleryView(
                store: store,
                presetResolver: presetResolver,
                commandDispatcher: commandDispatcher
            )
        case .windowGroups:
            if let windowGroupManager {
                WindowGroupSettingsView(manager: windowGroupManager)
            }
        case .appRules:
            ApplicationRulesView(store: store)
        case .workspaces:
            if let workspaceManager {
                WorkspaceSettingsView(manager: workspaceManager)
            }
        case .about:
            AboutSettingsView()
        }
    }
}

