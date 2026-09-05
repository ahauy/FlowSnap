import SwiftUI

/// Menu bar dropdown UI for FlowSnap.
///
/// Provides instant access to snap actions, accessibility permission alerts,
/// and application preferences. Designed with native macOS ergonomics.
public struct MenuBarView: View {

    @Bindable var viewModel: MenuBarViewModel

    public init(viewModel: MenuBarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            headerSection

            // Permission Warning Banner (if untrusted)
            if !viewModel.isAccessibilityTrusted {
                permissionWarningBanner
            }

            // Quick Snap Actions Grid (Visual Screen Canvas)
            VisualSnapGridView(isEnabled: viewModel.isAccessibilityTrusted) { action in
                viewModel.triggerSnap(action)
            }

            // Presets (US-WORK-012)
            if !viewModel.presets.isEmpty {
                Divider()
                presetsSection
            }

            // Workspaces (hidden when there is no workspace support)
            if let workspaceVM = viewModel.workspaceViewModel {
                Divider()
                workspacesSection(workspaceVM)
            }

            // Pinned Windows (US-SNAP-021)
            Divider()
            pinnedWindowsSection

            // Quick Scratchpad (US-SNAP-022)
            Divider()
            scratchpadSection

            Divider()

            // System Management
            footerSection
        }
        .padding(12)
        .frame(width: 300)
        .onAppear {
            viewModel.refreshState()
        }

        .sheet(isPresented: saveSheetBinding) {
            if let workspaceVM = viewModel.workspaceViewModel {
                WorkspaceSaveSheet(viewModel: workspaceVM) {
                    workspaceVM.cancelSave()
                }
            }
        }
    }

    /// Drives the save sheet from the (optional) workspace view model.
    private var saveSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.workspaceViewModel?.isSavePresented ?? false },
            set: { viewModel.workspaceViewModel?.isSavePresented = $0 }
        )
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PRESETS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Manage…") {
                    viewModel.openSettings(tab: .presets)
                }
                .buttonStyle(.plain)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(viewModel.presets.prefix(4)) { preset in
                    presetButton(preset)
                }
            }

            if let summary = viewModel.lastPresetRestoreSummary {
                RestoreSummaryBanner(summary: summary, isCompact: true) {
                    viewModel.clearPresetRestoreSummary()
                }
            }
        }
    }

    private func presetButton(_ preset: WorkspacePreset) -> some View {
        Button {
            viewModel.triggerPreset(preset)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: preset.iconSymbolName)
                    .font(.system(size: 11))
                    .frame(width: 14)

                Text(preset.name)
                    .font(.system(size: 11))

                Spacer()

                let badge = viewModel.shortcutBadge(for: preset)
                if !badge.isEmpty {
                    Text(badge)
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
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
        .disabled(!viewModel.isAccessibilityTrusted)
        .opacity(viewModel.isAccessibilityTrusted ? 1.0 : 0.5)
    }

    // MARK: - Workspaces

    private func workspacesSection(_ workspaceVM: WorkspaceViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("WORKSPACES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    workspaceVM.presentSaveSheet()
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                        Text("Save")
                    }
                    .font(.system(size: 9, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Save current layout as a workspace")

                Text("•")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)

                Button("Manage…") {
                    viewModel.openSettings(tab: .workspaces)
                }
                .buttonStyle(.plain)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
            }

            WorkspaceListView(viewModel: workspaceVM)


            Button {
                viewModel.triggerMigrateWorkspace(.next)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "display.and.keyboard")
                        .font(.system(size: 11))
                    Text("Move Workspace to Next Display")
                        .font(.system(size: 11))
                    Spacer()
                    Text("⌃⌥⇧⌘→")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color(nsColor: .controlBackgroundColor).opacity(0.4)))
            }
            .buttonStyle(.plain)

            if let summary = workspaceVM.lastRestoreSummary {
                RestoreSummaryBanner(summary: summary, isCompact: true) {
                    workspaceVM.clearRestoreSummary()
                }
            }
            if let error = workspaceVM.errorMessage {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 10))
                    Text(error)
                        .font(.system(size: 10))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.orange.opacity(0.08)))
            }
        }
    }

    // MARK: - Pinned Windows (US-SNAP-021)

    private var pinnedWindowsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("PINNED WINDOWS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if !viewModel.pinnedWindows.isEmpty {
                    Button("Unpin All") {
                        viewModel.unpinAll()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                }
            }

            Button {
                viewModel.togglePinCurrentWindow()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "pin")
                        .font(.system(size: 11))
                        .frame(width: 14)
                    Text("Pin Focused Window")
                        .font(.system(size: 11))
                    Spacer()
                    Text("⌃⌥P")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
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
            .disabled(!viewModel.isAccessibilityTrusted)
            .opacity(viewModel.isAccessibilityTrusted ? 1.0 : 0.5)

            if !viewModel.pinnedWindows.isEmpty {
                VStack(spacing: 4) {
                    ForEach(viewModel.pinnedWindows) { record in
                        HStack {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                            Text(record.title.isEmpty ? (record.bundleIdentifier ?? "Window") : record.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer()
                            Button {
                                viewModel.unpin(windowID: record.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                        )
                    }
                }
            }
        }
    }

    // MARK: - Quick Scratchpad (US-SNAP-022)

    private var scratchpadSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("QUICK SCRATCHPAD")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.isScratchpadAssigned {
                    Button("Detach") {
                        viewModel.detachScratchpad()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                }
            }

            if let record = viewModel.scratchpadRecord {
                Button {
                    viewModel.toggleScratchpad()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.isScratchpadVisible ? "macwindow.badge.plus" : "macwindow")
                            .font(.system(size: 11))
                            .foregroundStyle(.cyan)
                            .frame(width: 14)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(record.appName)
                                .font(.system(size: 11, weight: .medium))
                            if let title = record.windowTitle, !title.isEmpty && title != record.appName {
                                Text(title)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text("⌥Space")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
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
                .disabled(!viewModel.isAccessibilityTrusted)
                .opacity(viewModel.isAccessibilityTrusted ? 1.0 : 0.5)
            } else {
                Button {
                    viewModel.assignCurrentWindowAsScratchpad()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 11))
                            .frame(width: 14)
                        Text("Assign Focused Window")
                            .font(.system(size: 11))
                        Spacer()
                        Text("⌃⌥Space")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
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
                .disabled(!viewModel.isAccessibilityTrusted)
                .opacity(viewModel.isAccessibilityTrusted ? 1.0 : 0.5)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            Text("FlowSnap")
                .font(.system(size: 13, weight: .semibold))

            Spacer()

            if viewModel.isAccessibilityTrusted {
                Text("Ready")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15), in: Capsule())
            }
        }
    }

    // MARK: - Permission Warning Banner

    private var permissionWarningBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 24, height: 24)

                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Accessibility Access Needed")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Window snapping is currently disabled")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("FlowSnap needs Accessibility permission in macOS Settings to detect and snap application windows.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1.5)

            Button {
                viewModel.requestAccessibilityPermission()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                    Text("Open System Settings")
                        .font(.system(size: 10, weight: .semibold))
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Footer (System Controls)

    private var footerSection: some View {
        VStack(spacing: 4) {
            Button {
                viewModel.openSettings()
            } label: {
                HStack {
                    Label("Settings...", systemImage: "gearshape")
                        .font(.system(size: 11))
                    Spacer()
                    Text("⌘,")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                viewModel.quitApp()
            } label: {
                HStack {
                    Label("Quit FlowSnap", systemImage: "power")
                        .font(.system(size: 11))
                    Spacer()
                    Text("⌘Q")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
