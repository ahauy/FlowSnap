import SwiftUI

/// Keyboard shortcut configuration tab in Settings.
///
/// Traces to: US-SNAP-010, BR-SET-001..005.
public struct ShortcutSettingsView: View {

    @ObservedObject var store: PreferencesStore

    public init(store: PreferencesStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(ShortcutCategory.allCases) { category in
                        Section {
                            VStack(spacing: 8) {
                                ForEach(actions(for: category)) { action in
                                    shortcutRow(for: action)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.gray.opacity(0.2))
                            )
                        } header: {
                            Text(category.rawValue)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(16)
            }

            Divider()

            // Footer actions
            HStack {
                Text("Press ⎋ to cancel recording or ⌫ to clear.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Restore Defaults") {
                    store.resetShortcutsToDefault()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func actions(for category: ShortcutCategory) -> [ShortcutAction] {
        ShortcutAction.allCases.filter { $0.category == category }
    }

    @ViewBuilder
    private func shortcutRow(for action: ShortcutAction) -> some View {
        let currentShortcut = store.shortcut(for: action)
        let conflict = currentShortcut.flatMap { store.hasConflict($0, excluding: action) }

        HStack {
            Text(action.displayName)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            ShortcutRecorderField(
                shortcut: currentShortcut,
                conflictAction: conflict,
                onRecordingChange: { isRecording in
                    store.setRecordingShortcut(isRecording)
                },
                onRecord: { newShortcut in
                    store.setShortcut(newShortcut, for: action)
                },
                onClear: {
                    store.setShortcut(nil, for: action)
                }
            )
        }
    }
}
