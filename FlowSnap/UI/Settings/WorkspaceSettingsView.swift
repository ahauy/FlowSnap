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
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            Divider()

            if viewModel.workspaces.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.workspaces) { workspace in
                            workspaceCard(workspace)
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

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Saved Workspaces")
                    .font(.headline)

                Text("Save sets of window positions and restore them in one click. FlowSnap launches any app that isn't running.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                viewModel.presentSaveSheet()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("Save Current Layout")
                }
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .help("Save the current window layout as a workspace")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No Saved Workspaces")
                .font(.system(size: 13, weight: .semibold))

            Text("Arrange your windows on screen, then click below to save your current layout as a workspace.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Button {
                viewModel.presentSaveSheet()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                    Text("Save Current Layout...")
                }
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Workspace Card

    private func workspaceCard(_ workspace: Workspace) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            workspaceCardHeader(workspace)

            if !workspace.orderedPlacements.isEmpty && renamingID != workspace.id {
                Divider()
                placementsList(workspace)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }

    private func workspaceCardHeader(_ workspace: Workspace) -> some View {
        HStack(spacing: 8) {
            Image(systemName: workspace.icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.accentColor)

            if renamingID == workspace.id {
                renameField(workspace)
            } else {
                Text(workspace.name)
                    .font(.system(size: 13, weight: .semibold))

                Text("\(workspace.appCount) apps • \(workspace.expectedWindowTotal) windows")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                    )

                Spacer()

                rowActions(workspace)
            }
        }
    }

    private func placementsList(_ workspace: Workspace) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Configured Placements")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(workspace.orderedPlacements, id: \.self) { placement in
                    placementRow(placement)
                }
            }
        }
    }

    private func placementRow(_ placement: WindowPlacement) -> some View {
        let appName = formatBundleName(placement.bundleIdentifier)
        let zoneTitle = displayName(for: placement.zone)

        return HStack(spacing: 8) {
            Image(systemName: iconForBundle(placement.bundleIdentifier))
                .font(.system(size: 12))
                .foregroundStyle(Color.accentColor)
                .frame(width: 16)

            Text(appName)
                .font(.system(size: 11, weight: .semibold))

            Spacer()

            Text(zoneTitle)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor.opacity(0.12))
                )
                .foregroundStyle(Color.accentColor)

            if placement.expectedWindowCount > 1 {
                Text("\(placement.expectedWindowCount) windows")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(nsColor: .controlColor).opacity(0.4))
        )
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

// MARK: - Workspace Placement Helpers

private func formatBundleName(_ bundleID: String) -> String {
    let lower = bundleID.lowercased()
    if lower.contains("brave") { return "Brave" }
    if lower.contains("chrome") { return "Chrome" }
    if lower.contains("safari") { return "Safari" }
    if lower.contains("antigravity") { return "Antigravity IDE" }
    if lower.contains("vscode") || lower.contains("visualstudio") { return "VS Code" }
    if lower.contains("cursor") { return "Cursor" }
    if lower.contains("xcode") { return "Xcode" }
    if lower.contains("finder") { return "Finder" }
    if lower.contains("terminal") || lower.contains("iterm") { return "Terminal" }
    if lower.contains("slack") { return "Slack" }
    if lower.contains("notes") { return "Notes" }
    return bundleID.components(separatedBy: ".").last?.capitalized ?? bundleID
}

private func iconForBundle(_ bundleID: String) -> String {
    let lower = bundleID.lowercased()
    if lower.contains("brave") || lower.contains("chrome") || lower.contains("safari") || lower.contains("edge") {
        return "globe"
    }
    if lower.contains("antigravity") || lower.contains("vscode") || lower.contains("xcode") || lower.contains("cursor") {
        return "chevron.left.forwardslash.chevron.right"
    }
    if lower.contains("terminal") || lower.contains("iterm") {
        return "terminal"
    }
    if lower.contains("finder") {
        return "folder"
    }
    if lower.contains("slack") || lower.contains("discord") || lower.contains("telegram") || lower.contains("zalo") {
        return "message"
    }
    if lower.contains("notes") {
        return "note.text"
    }
    return "macwindow"
}

private func displayName(for zone: LayoutZone) -> String {
    switch zone {
    case .leftHalf, .left50_50: return "Left Half"
    case .rightHalf, .right50_50: return "Right Half"
    case .topHalf: return "Top Half"
    case .bottomHalf: return "Bottom Half"
    case .maximize: return "Full Screen"
    case .topLeft: return "Top Left"
    case .topRight: return "Top Right"
    case .bottomLeft: return "Bottom Left"
    case .bottomRight: return "Bottom Right"
    case .left70_30: return "Left 70%"
    case .rightOneThird, .right20_80: return "Right 30%"
    case .leftThird, .left25: return "Left 1/3"
    case .centerThird, .center50: return "Center"
    case .rightThird, .right25: return "Right 1/3"
    case .left60_40: return "Left 60%"
    case .right40_60: return "Right 40%"
    case .left80_20: return "Left 80%"
    default: return zone.rawValue.capitalized
    }
}
