import SwiftUI

/// General preferences: gaps, ratios, drag-to-snap, launch at login.
///
/// Binds to `PreferencesStore` (BR-CRW-002, BR-CRW-006, US-SNAP-010).
public struct GeneralSettingsView: View {

    @ObservedObject var store: PreferencesStore

    public init(store: PreferencesStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Window Gap Card
                SettingsGroupCard(title: "Window Gap", iconName: "arrow.left.and.right") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Spacing between adjacent snapped windows and screen edges.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Picker("Window Gap", selection: gapBinding) {
                            ForEach(PreferencesStore.allowedGaps, id: \.self) { gap in
                                Text("\(Int(gap)) px").tag(gap)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        HStack {
                            GapPreview(gap: store.windowGap, frame: CGSize(width: 160, height: 32))
                            Spacer()
                            Text("Current: \(Int(store.windowGap)) px")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Default Split Ratio Card
                SettingsGroupCard(title: "Default Split Ratio", iconName: "rectangle.split.2x1") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Initial column proportion when snapping two windows side-by-side.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Picker("Ratio", selection: ratioBinding) {
                            ForEach(LayoutRatio.allCases, id: \.self) { ratio in
                                Text(ratio.displayName).tag(ratio)
                            }
                        }
                        .labelsHidden()
                    }
                }

                // Drag to Snap Card
                SettingsGroupCard(title: "Drag to Snap", iconName: "hand.draw") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Enable Drag to Snap", isOn: dragToSnapBinding)
                            .font(.system(size: 12))

                        if store.isDragToSnapEnabled {
                            Divider()
                            HStack {
                                Text("Preview Dwell Delay")
                                    .font(.system(size: 12))
                                Spacer()
                                Picker("Preview Delay", selection: dwellDelayBinding) {
                                    Text("Instant (50 ms)").tag(0.05)
                                    Text("Normal (150 ms)").tag(0.15)
                                    Text("Relaxed (300 ms)").tag(0.30)
                                }
                                .labelsHidden()
                            }
                        }
                    }
                }

                // Stage Manager Card
                SettingsGroupCard(title: "Stage Manager Integration", iconName: "rectangle.on.rectangle") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Auto-group windows on restore", isOn: stageManagerAutoGroupingBinding)
                            .font(.system(size: 12))
                            .help("When enabled, FlowSnap bundles all restored workspace windows onto a single stage.")

                        Toggle("Keep Stage when opening new apps", isOn: stageManagerLaunchCoexistenceBinding)
                            .font(.system(size: 12))
                            .help("When enabled, opening a new application joins the current Stage instead of pushing active windows into the sidebar.")

                        Divider()

                        HStack {
                            Text("Configure macOS Stage Manager")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Desktop & Dock Settings…") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.link)
                            .font(.system(size: 11))
                        }
                    }
                }

                // Quick Scratchpad Card
                SettingsGroupCard(title: "Quick Scratchpad", iconName: "note.text") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Dismiss on ESC key", isOn: scratchpadDismissOnEscBinding)
                            .font(.system(size: 12))
                            .help("When enabled, pressing ESC while Scratchpad is focused immediately dismisses it.")

                        Toggle("Dismiss when clicking outside", isOn: scratchpadDismissOnBlurBinding)
                            .font(.system(size: 12))
                            .help("When enabled, clicking anywhere outside the Scratchpad window automatically dismisses it.")
                    }
                }

                // Launch Card
                SettingsGroupCard(title: "Launch Policy", iconName: "bolt.fill") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Launch FlowSnap at login", isOn: launchAtLoginBinding)
                            .font(.system(size: 12))
                            .help("When enabled, FlowSnap automatically starts in the menu bar when you log in to macOS.")

                        if store.launchAtLoginStatus.requiresUserApproval {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 12))
                                Text("Approval required in macOS System Settings")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Open Login Items…") {
                                    store.openSystemLoginItemsSettings()
                                }
                                .buttonStyle(.link)
                                .font(.system(size: 11))
                            }
                            .padding(8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                        } else if case .error(let message) = store.launchAtLoginStatus {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 11))
                                Text(message)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Divider()

                        HStack {
                            Text("Managed by macOS ServiceManagement")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Login Items Settings…") {
                                store.openSystemLoginItemsSettings()
                            }
                            .buttonStyle(.link)
                            .font(.system(size: 11))
                        }
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            store.refreshLaunchAtLoginStatus()
        }
    }


    // MARK: - Bindings

    private var gapBinding: Binding<CGFloat> {
        Binding(
            get: { store.windowGap },
            set: { store.setWindowGap($0) }
        )
    }

    private var ratioBinding: Binding<LayoutRatio> {
        Binding(
            get: { store.defaultRatio },
            set: { store.setDefaultRatio($0) }
        )
    }

    private var dragToSnapBinding: Binding<Bool> {
        Binding(
            get: { store.isDragToSnapEnabled },
            set: { store.setDragToSnapEnabled($0) }
        )
    }

    private var dwellDelayBinding: Binding<Double> {
        Binding(
            get: { store.dragPreviewDwellDelay },
            set: { store.setDragPreviewDwellDelay($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { store.launchAtLogin },
            set: { store.setLaunchAtLogin($0) }
        )
    }

    private var stageManagerAutoGroupingBinding: Binding<Bool> {
        Binding(
            get: { store.isStageManagerAutoGroupingEnabled },
            set: { store.setStageManagerAutoGroupingEnabled($0) }
        )
    }

    private var stageManagerLaunchCoexistenceBinding: Binding<Bool> {
        Binding(
            get: { store.isStageManagerLaunchCoexistenceEnabled },
            set: { store.setStageManagerLaunchCoexistenceEnabled($0) }
        )
    }

    private var scratchpadDismissOnBlurBinding: Binding<Bool> {
        Binding(
            get: { store.isScratchpadDismissOnBlurEnabled },
            set: { store.setScratchpadDismissOnBlurEnabled($0) }
        )
    }

    private var scratchpadDismissOnEscBinding: Binding<Bool> {
        Binding(
            get: { store.isScratchpadDismissOnEscEnabled },
            set: { store.setScratchpadDismissOnEscEnabled($0) }
        )
    }
}

/// Reusable card container matching macOS System Settings aesthetic.
struct SettingsGroupCard<Content: View>: View {
    let title: String
    let iconName: String
    let content: Content

    init(title: String, iconName: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

/// Small visual preview showing how the gap insets two columns.
private struct GapPreview: View {

    let gap: CGFloat
    let frame: CGSize

    var body: some View {
        HStack(spacing: gap) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.accentColor.opacity(0.7))
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.7))
        }
        .frame(width: frame.width, height: frame.height)
        .padding(gap)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.gray.opacity(0.4))
        )
        .overlay(alignment: .topLeading) {
            Text("\(Int(gap)) px")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .offset(x: 2, y: 2)
        }
    }
}

extension LayoutRatio {
    /// Human-readable label for the ratio picker.
    var displayName: String {
        switch self {
        case .equal: return "50/50"
        case .sixtyForty: return "60/40"
        case .seventyThirty: return "70/30"
        case .eightyTwenty: return "80/20"
        case .threeColumn25_50_25: return "25/50/25"
        }
    }
}
