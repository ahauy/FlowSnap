import SwiftUI

/// The "Workspaces" settings tab (US-WORK-011 spec §4.5, contracts §4).
///
/// Full management surface: save the current layout, restore, rename inline, and
/// delete (behind a confirmation). It owns a `WorkspaceViewModel` built from the
/// shared `WorkspaceManager`, so the list here and the menu bar popover always
/// reflect the same persisted workspaces.
///
/// Traces to: US-WORK-011 spec §4.5, §2 J1–J3.
public struct WorkspaceSettingsView: View {

    public init(manager: WorkspaceManager) {
        _viewModel = StateObject(wrappedValue: WorkspaceViewModel(manager: manager))
    }

    @StateObject private var viewModel: WorkspaceViewModel

    /// The workspace whose name is being edited inline, if any.
    @State private var renamingID: UUID?
    /// Draft text for the inline rename field.
    @State private var renameText: String = ""
    /// The workspace pending a delete confirmation.
    @State private var pendingDelete: Workspace?

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Workspaces")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.presentSaveSheet()
                } label: {
                    Label("Save Current Layout", systemImage: "plus")
                }
            }

            Text("Save a set of window positions and restore them in one click. FlowSnap launches any app that isn't running.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            if viewModel.workspaces.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(viewModel.workspaces) { workspace in
                            row(workspace)
                        }
                    }
                    .padding(1)
                }
            }

            if let summary = viewModel.lastRestoreSummary {
                restoreSummaryBanner(summary)
            }
            if let error = viewModel.errorMessage {
                errorBanner(error)
            }
            if let storeError = viewModel.storeError {
                storeErrorBanner(storeError)
            }

            Spacer()
        }
        .padding(20)
        .sheet(isPresented: $viewModel.isSavePresented) {
            WorkspaceSaveSheet(viewModel: viewModel) {
                viewModel.cancelSave()
            }
        }
        .confirmationDialog(
            "Delete “\(pendingDelete?.name ?? "")”?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let target = pendingDelete {
                    Task { await viewModel.delete(target) }
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This removes the workspace. Your windows are not affected.")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No saved workspaces")
                .font(.system(size: 13, weight: .medium))
            Text("Arrange your windows, then click “Save Current Layout”.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Row

    private func row(_ workspace: Workspace) -> some View {
        HStack(spacing: 10) {
            Image(systemName: workspace.icon)
                .font(.system(size: 16))
                .frame(width: 22)

            if renamingID == workspace.id {
                renameField(workspace)
            } else {
                titleBlock(workspace)
                Spacer()
                rowActions(workspace)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    /// The name + app-count label shown when the row is not being renamed.
    private func titleBlock(_ workspace: Workspace) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(workspace.name)
                .font(.system(size: 13, weight: .medium))
            Text("\(workspace.appCount) \(workspace.appCount == 1 ? "app" : "apps")")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    /// The trailing Restore / Rename / Delete controls.
    private func rowActions(_ workspace: Workspace) -> some View {
        HStack(spacing: 6) {
            Button("Restore") {
                Task { await viewModel.restore(workspace) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(viewModel.isRestoring || workspace.isEmpty)

            Button {
                renamingID = workspace.id
                renameText = workspace.name
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Rename")

            Button {
                pendingDelete = workspace
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Delete")
        }
    }

    private func renameField(_ workspace: Workspace) -> some View {
        HStack(spacing: 6) {
            TextField("Name", text: $renameText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 220)
                .onSubmit { commitRename(workspace) }
            Button("Save") { commitRename(workspace) }
                .keyboardShortcut(.defaultAction)
            Button("Cancel") { renamingID = nil }
                .keyboardShortcut(.cancelAction)
        }
    }

    private func commitRename(_ workspace: Workspace) {
        let trimmed = Workspace.trimmed(renameText)
        renamingID = nil
        guard trimmed != workspace.name else { return }
        Task { await viewModel.rename(workspace, to: trimmed) }
    }

    // MARK: - Banners

    private func restoreSummaryBanner(_ summary: RestoreSummary) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: summary.isFullSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(summary.isFullSuccess ? .green : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(summary.headline).font(.system(size: 12, weight: .medium))
                ForEach(summary.details, id: \.self) { detail in
                    Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                viewModel.clearRestoreSummary()
            } label: {
                Image(systemName: "xmark").font(.system(size: 10))
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill((summary.isFullSuccess ? Color.green : Color.orange).opacity(0.08))
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.system(size: 12))
            Spacer()
            Button { viewModel.dismissError() } label: {
                Image(systemName: "xmark").font(.system(size: 10))
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.08)))
    }

    private func storeErrorBanner(_ storeError: WorkspaceStoreError) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "externaldrive.badge.exclamationmark").foregroundStyle(.orange)
            Text(WorkspaceViewModel.message(for: storeError)).font(.system(size: 12))
            Spacer()
            Button { viewModel.dismissStoreError() } label: {
                Image(systemName: "xmark").font(.system(size: 10))
            }
            .buttonStyle(.borderless)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange.opacity(0.08)))
    }
}
