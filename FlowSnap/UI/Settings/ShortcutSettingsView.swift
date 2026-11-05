import SwiftUI

/// Keyboard shortcut configuration tab in Settings.
///
/// Traces to: US-SNAP-010, BR-SET-001..005.
public struct ShortcutSettingsView: View {

    @ObservedObject var store: PreferencesStore

    @State private var conflictErrorMessage: String?

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

            if let conflict = conflictErrorMessage {
                conflictBanner(conflict)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
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
                    conflictErrorMessage = nil
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
        let isUnregistered = currentShortcut.map { store.unregisteredShortcuts.contains($0) } ?? false

        HStack {
            Text(action.displayName)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            if isUnregistered, let shortcut = currentShortcut {
                Text("Not registered")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .help("macOS refused to bind \(shortcut.displayString); it will not trigger until another combination is chosen.")
            }

            ShortcutRecorderField(
                shortcut: currentShortcut,
                conflictAction: conflict,
                onRecordingChange: { isRecording in
                    store.setRecordingShortcut(isRecording)
                },
                onRecord: { newShortcut in
                    if let message = store.hasActionShortcutConflict(newShortcut, excluding: action) {
                        conflictErrorMessage = "Cannot assign \(newShortcut.displayString): \(message)"
                        return
                    }
                    conflictErrorMessage = nil
                    store.setShortcut(newShortcut, for: action)
                },
                onClear: {
                    store.setShortcut(nil, for: action)
                    conflictErrorMessage = nil
                }
            )
        }
    }

    private func conflictBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 12))

            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                conflictErrorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9))
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.10))
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }
}
