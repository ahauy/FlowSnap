import SwiftUI

/// General preferences: gaps, launch at login, etc.
///
/// Binds to the actor-based `PreferencesStore` for the window gap (BR-CRW-002)
/// and default layout ratio (BR-CRW-006). US-SNAP-008.
struct GeneralSettingsView: View {

    @ObservedObject var store: PreferencesStore

    init(store: PreferencesStore = PreferencesStore()) {
        self.store = store
    }

    var body: some View {
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

            Section("Default Ratio") {
                Picker("Default Ratio", selection: ratioBinding) {
                    ForEach(LayoutRatio.allCases, id: \.self) { ratio in
                        Text(ratio.displayName).tag(ratio)
                    }
                }
            }

            Section("Launch") {
                Toggle("Launch at login", isOn: .constant(false))
            }
        }
        .padding()
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
