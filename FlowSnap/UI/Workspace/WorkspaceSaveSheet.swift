import SwiftUI

/// The "save current layout" sheet (US-WORK-011 spec §2 J1, contracts §4).
///
/// Collects the three things a workspace needs — a name, an icon, and the set of
/// windows to capture — then hands off to `WorkspaceViewModel.saveDraft()`. All
/// validation (E1 duplicate, E2 empty, E3 nothing eligible, E11 permission) is
/// surfaced inline via `viewModel.errorMessage` so the sheet stays open and the
/// user can fix the problem without losing what they typed.
///
/// Traces to: US-WORK-011 spec §2 J1.1–J1.4, §5.
public struct WorkspaceSaveSheet: View {

    @ObservedObject var viewModel: WorkspaceViewModel
    var onCancel: () -> Void

    public init(viewModel: WorkspaceViewModel, onCancel: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            nameField

            iconGrid

            windowPicker

            if let error = viewModel.errorMessage {
                errorBanner(error)
            }

            actionBar
        }
        .padding(16)
        .frame(width: 380)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 15, weight: .semibold))
            Text("Save Workspace")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
        }
    }

    // MARK: - Name (E1/E2)

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NAME")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            TextField("e.g. Coding", text: $viewModel.draftName)
                .textFieldStyle(.roundedBorder)
                .disableAutocorrection(true)
        }
    }

    // MARK: - Icon grid (curated SF Symbols, spec §2 J1.2)

    private var iconGrid: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("ICON")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(viewModel.iconChoices, id: \.self) { symbol in
                    iconButton(symbol)
                }
            }
        }
    }

    private func iconButton(_ symbol: String) -> some View {
        let isSelected = viewModel.draftIcon == symbol
        return Button {
            viewModel.draftIcon = symbol
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .frame(maxWidth: .infinity, minHeight: 30)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symbol)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Window picker (J1.2)

    private var windowPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("WINDOWS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.selectedWindowIDs.count) selected")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            if viewModel.isPreparingCapture {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Reading your windows…")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if viewModel.availableWindows.isEmpty {
                Text("No eligible windows are on screen.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(viewModel.availableWindows) { window in
                            windowRow(window)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
    }

    private func windowRow(_ window: WindowGroupSnapshot) -> some View {
        let isSelected = viewModel.selectedWindowIDs.contains(window.id)
        return Button {
            viewModel.toggle(window)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.system(size: 13))
                Text(window.displayTitle)
                    .font(.system(size: 11))
                    .lineLimit(1)
                Spacer()
                if window.isAlreadyTracked {
                    Text("added")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error banner (E1/E2/E3/E11)

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 11))
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.08))
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private var actionBar: some View {
        HStack {
            Spacer()
            Button("Cancel") { onCancel() }
                .keyboardShortcut(.cancelAction)

            Button {
                Task { await viewModel.saveDraft() }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isSaving {
                        ProgressView().controlSize(.small)
                    }
                    Text("Save Workspace")
                }
                .frame(minWidth: 110)
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving || viewModel.selectedWindowIDs.isEmpty)
        }
    }
}
