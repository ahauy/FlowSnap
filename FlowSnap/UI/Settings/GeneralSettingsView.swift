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
        Form {
            Section("Window Gap") {
                Picker("Window Gap", selection: gapBinding) {
                    ForEach(PreferencesStore.allowedGaps, id: \.self) { gap in
                        Text("\(Int(gap)) px").tag(gap)
                    }
                }
                .pickerStyle(.segmented)

                GapPreview(gap: store.windowGap, frame: CGSize(width: 180, height: 36))
            }

            Section("Default Split Ratio") {
                Picker("Default Ratio", selection: ratioBinding) {
                    ForEach(LayoutRatio.allCases, id: \.self) { ratio in
                        Text(ratio.displayName).tag(ratio)
                    }
                }
            }

            Section("Drag to Snap") {
                Toggle("Enable Drag to Snap", isOn: dragToSnapBinding)

                if store.isDragToSnapEnabled {
                    Picker("Preview Delay", selection: dwellDelayBinding) {
                        Text("Instant (50 ms)").tag(0.05)
                        Text("Normal (150 ms)").tag(0.15)
                        Text("Relaxed (300 ms)").tag(0.30)
                    }
                }
            }

            Section("Stage Manager") {
                Toggle("Auto-group windows on restore", isOn: stageManagerAutoGroupingBinding)
                    .help("When enabled, FlowSnap bundles all restored workspace windows onto a single stage.")

                Toggle("Keep Stage when opening new apps", isOn: stageManagerLaunchCoexistenceBinding)
                    .help("When enabled, opening a new application joins the current Stage instead of pushing active windows into the sidebar.")

                HStack {
                    Text("macOS Stage Manager")
                    Spacer()
                    Button("Desktop & Dock Settings…") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }
            }

            Section("Quick Scratchpad") {
                Toggle("Dismiss on ESC key", isOn: scratchpadDismissOnEscBinding)
                    .help("When enabled, pressing ESC while Scratchpad is focused immediately dismisses it.")

                Toggle("Dismiss when clicking outside", isOn: scratchpadDismissOnBlurBinding)
                    .help("When enabled, clicking anywhere outside the Scratchpad window automatically dismisses it.")
            }

            Section("Launch") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)
            }
        }
        .padding(16)
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
