import SwiftUI

/// The list of saved workspaces with a one-tap Restore (US-WORK-011 spec §2 J2,
/// §4.5; contracts §4).
///
/// Shared by the menu bar popover and the Settings tab so both surfaces show the
/// same rows and drive the same `WorkspaceViewModel`. Rows are intentionally
/// compact for the popover; `showsDelete` adds the destructive affordance only
/// where there is room for it (Settings).
///
/// Traces to: US-WORK-011 spec §2 J2.1, §4.5.
public struct WorkspaceListView: View {

    @ObservedObject var viewModel: WorkspaceViewModel

    /// Whether each row also offers a Delete button (Settings only).
    var showsDelete: Bool = false

    /// Called when the user asks to edit a workspace's windows (Settings only).
    var onEdit: ((Workspace) -> Void)?

    public init(
        viewModel: WorkspaceViewModel,
        showsDelete: Bool = false,
        onEdit: ((Workspace) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.showsDelete = showsDelete
        self.onEdit = onEdit
    }

    public var body: some View {
        if viewModel.workspaces.isEmpty {
            emptyState
        } else {
            VStack(spacing: 4) {
                ForEach(viewModel.workspaces) { workspace in
                    row(workspace)
                }
            }
        }
    }

    // MARK: - Empty state (spec §4.5)

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No saved workspaces")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Save your current window layout to restore it later.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
    }

    // MARK: - Row

    private func row(_ workspace: Workspace) -> some View {
        HStack(spacing: 8) {
            Image(systemName: workspace.icon)
                .font(.system(size: 13))
                .frame(width: 18)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 1) {
                Text(workspace.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                Text(subtitle(for: workspace))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            restoreButton(workspace)

            if showsDelete, let onEdit {
                Button {
                    onEdit(workspace)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Edit windows")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        )
    }

    private func subtitle(for workspace: Workspace) -> String {
        let apps = workspace.appCount
        let noun = apps == 1 ? "app" : "apps"
        return "\(apps) \(noun)"
    }

    private func restoreButton(_ workspace: Workspace) -> some View {
        // The manager runs one restore pass at a time, so a single global flag
        // disables every row while any restore is in flight (prevents a second
        // click piling up another pass that awaits app launches for seconds).
        let anyRestoring = viewModel.isRestoring
        return Button {
            Task { await viewModel.restore(workspace) }
        } label: {
            if anyRestoring {
                ProgressView().controlSize(.small)
            } else {
                Text("Restore")
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(anyRestoring || workspace.isEmpty)
        .help(workspace.isEmpty ? "Nothing to restore" : "Restore this layout")
    }
}
