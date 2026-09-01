import SwiftUI

/// Window Groups settings tab allowing users to inspect and manage active synchronized window groups.
///
/// Traces to: US-WORK-012 (Phase 6, spec §2, contracts §1, FR-GROUP-001..006).
public struct WindowGroupSettingsView: View {

    @ObservedObject var manager: WindowGroupManager

    public init(manager: WindowGroupManager) {
        self.manager = manager
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            Divider()

            if manager.activeGroups.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(manager.activeGroups) { group in
                            groupCard(group)
                        }
                    }
                    .padding(1)
                }
            }

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Active Window Groups")
                .font(.headline)

            Text("Linked window groups coordinate minimize, focus, and move behaviors across multiple windows.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No Active Window Groups")
                .font(.system(size: 13, weight: .medium))

            Text("Activate a workflow preset or group windows together to enable synchronized behaviors.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Group Card

    private func groupCard(_ group: WindowGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            groupCardHeader(group)

            Divider()

            groupSyncSection(group)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }

    private func groupCardHeader(_ group: WindowGroup) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.3.group.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.accentColor)

            Text(group.name)
                .font(.system(size: 13, weight: .semibold))

            Text("\(group.memberCount) windows")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                )

            Spacer()

            Button("Ungroup") {
                manager.dissolveGroup(id: group.id)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Dissolve this window group")
        }
    }

    private func groupSyncSection(_ group: WindowGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synchronization Behavior")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                syncToggle(
                    title: "Minimize together",
                    option: .minimizeTogether,
                    group: group
                )

                syncToggle(
                    title: "Focus together",
                    option: .focusTogether,
                    group: group
                )

                syncToggle(
                    title: "Move together",
                    option: .moveTogether,
                    group: group
                )
            }
        }
    }

    private func syncToggle(
        title: String,
        option: GroupSyncOptions,
        group: WindowGroup
    ) -> some View {
        Toggle(
            title,
            isOn: Binding(
                get: { group.syncOptions.contains(option) },
                set: { isEnabled in
                    var updated = group.syncOptions
                    if isEnabled {
                        updated.insert(option)
                    } else {
                        updated.remove(option)
                    }
                    manager.updateSyncOptions(updated, for: group.id)
                }
            )
        )
        .toggleStyle(.checkbox)
        .font(.system(size: 11))
    }
}
