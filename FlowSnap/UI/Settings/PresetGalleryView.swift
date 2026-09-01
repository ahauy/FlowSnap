import SwiftUI

/// Presets Gallery settings tab allowing visual inspection, shortcut customization, and live application.
///
/// Traces to: US-WORK-012 (Phase 6, spec §2, contracts §3, FR-PRESET-001, FR-PRESET-006, FR-PRESET-007).
public struct PresetGalleryView: View {

    @ObservedObject var store: PreferencesStore
    private let presetResolver: (any PresetResolving)?
    private let commandDispatcher: CommandDispatcher?

    @State private var isRestoring: Bool = false
    @State private var activeRestoringPresetID: String?
    @State private var lastRestoreSummary: RestoreSummary?
    @State private var conflictErrorMessage: String?

    public init(
        store: PreferencesStore,
        presetResolver: (any PresetResolving)? = nil,
        commandDispatcher: CommandDispatcher? = nil
    ) {
        self.store = store
        self.presetResolver = presetResolver
        self.commandDispatcher = commandDispatcher
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection

            Divider()

            if let conflict = conflictErrorMessage {
                conflictBanner(conflict)
            }

            if let summary = lastRestoreSummary {
                RestoreSummaryBanner(summary: summary) {
                    lastRestoreSummary = nil
                }
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(BuiltinPresetFactory.allBuiltinPresets) { preset in
                        presetCard(preset)
                    }
                }
                .padding(1)
            }

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Workflow Presets")
                .font(.headline)

            Text("Multi-window workspaces tailored for coding, research, writing, and design.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Preset Card

    private func presetCard(_ preset: WorkspacePreset) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            cardHeader(preset)

            Divider()

            HStack(alignment: .top, spacing: 14) {
                PresetSchematicPreview(slots: preset.slots)
                    .frame(width: 124, height: 78)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(preset.slots) { slot in
                        slotRow(slot)
                    }
                }
            }

            Divider()

            cardFooter(preset)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor))
                .stroke(Color.gray.opacity(0.18), lineWidth: 1)
        )
    }

    private func cardHeader(_ preset: WorkspacePreset) -> some View {
        HStack(spacing: 10) {
            Image(systemName: preset.iconSymbolName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(preset.name)
                    .font(.system(size: 13, weight: .semibold))

                Text(preset.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                Task { await applyPreset(preset) }
            } label: {
                if isRestoring && activeRestoringPresetID == preset.id {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 44)
                } else {
                    Text("Apply")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(isRestoring)
        }
    }

    private func slotRow(_ slot: PresetAppSlot) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconForCategory(slot.category))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 12)

            Text(slot.roleDescription)
                .font(.system(size: 11, weight: .medium))

            Text("(\(displayCandidates(slot.preferredBundleIDs)))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func cardFooter(_ preset: WorkspacePreset) -> some View {
        HStack(spacing: 8) {
            Text("Shortcut:")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            shortcutControl(for: preset)

            Spacer()

            if preset.autoGroupWindows {
                autoGroupBadge
            }
        }
    }

    private func shortcutControl(for preset: WorkspacePreset) -> some View {
        HStack(spacing: 6) {
            ShortcutRecorderField(
                shortcut: store.shortcut(forPresetID: preset.id),
                conflictAction: nil,
                onRecord: { recorded in
                    handleRecordShortcut(recorded, for: preset)
                },
                onClear: {
                    store.setShortcut(nil, forPresetID: preset.id)
                    conflictErrorMessage = nil
                }
            )

            if store.customPresetShortcuts[preset.id] != nil {
                Button("Reset") {
                    store.setShortcut(nil, forPresetID: preset.id)
                    conflictErrorMessage = nil
                }
                .buttonStyle(.borderless)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .help("Reset to default preset shortcut")
            }
        }
    }

    private var autoGroupBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "link")
                .font(.system(size: 9))
            Text("Auto-grouped")
                .font(.system(size: 10))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.12))
        )
    }

    // MARK: - Actions & Collision Handling

    private func handleRecordShortcut(_ shortcut: KeyboardShortcut, for preset: WorkspacePreset) {
        if let conflict = store.hasPresetConflict(shortcut, excludingPresetID: preset.id) {
            conflictErrorMessage = "Cannot assign \(shortcut.displayString): \(conflict)"
            return
        }
        conflictErrorMessage = nil
        store.setShortcut(shortcut, forPresetID: preset.id)
    }

    private func applyPreset(_ preset: WorkspacePreset) async {
        isRestoring = true
        activeRestoringPresetID = preset.id
        defer {
            isRestoring = false
            activeRestoringPresetID = nil
        }

        do {
            if let resolver = presetResolver {
                let summary = try await resolver.restore(preset: preset, on: nil)
                lastRestoreSummary = summary
            } else if let dispatcher = commandDispatcher {
                try await dispatcher.dispatch(.restorePreset(preset.id))
                lastRestoreSummary = dispatcher.lastRestoreSummary
            }
        } catch {
            lastRestoreSummary = RestoreSummary(
                placedCount: 0,
                totalPlacements: preset.slots.count,
                skipped: [SkippedApp(bundleIdentifier: preset.name, reason: .notInstalled)]
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

    private func iconForCategory(_ category: PresetAppCategory) -> String {
        switch category {
        case .editor: return "chevron.left.forwardslash.chevron.right"
        case .browser: return "globe"
        case .terminal: return "terminal"
        case .notes: return "note.text"
        case .writing: return "doc.text"
        case .design: return "paintbrush"
        case .custom: return "app"
        }
    }

    private func displayCandidates(_ bundleIDs: [String]) -> String {
        bundleIDs.prefix(2).map { SkippedApp.appName($0) }.joined(separator: ", ")
    }
}

// MARK: - Schematic Layout Preview

/// Mini layout schematic preview rendering the visual zone proportions of a preset.
struct PresetSchematicPreview: View {

    let slots: [PresetAppSlot]

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)

                ForEach(slots) { slot in
                    let rect = normalizedRect(for: slot)
                    let slotFrame = CGRect(
                        x: rect.origin.x * width,
                        y: rect.origin.y * height,
                        width: rect.size.width * width,
                        height: rect.size.height * height
                    )

                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(slotColor(slot.category).opacity(0.20))
                            .stroke(slotColor(slot.category).opacity(0.60), lineWidth: 1)

                        Text(shortLabel(slot))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(slotColor(slot.category))
                            .lineLimit(1)
                            .padding(1)
                    }
                    .frame(width: max(0, slotFrame.width - 2), height: max(0, slotFrame.height - 2))
                    .offset(x: slotFrame.origin.x + 1, y: slotFrame.origin.y + 1)
                }
            }
        }
    }

    private func normalizedRect(for slot: PresetAppSlot) -> CGRect {
        if let norm = slot.normalizedRect {
            return norm
        }
        switch slot.zone {
        case .leftHalf: return CGRect(x: 0, y: 0, width: 0.5, height: 1.0)
        case .rightHalf: return CGRect(x: 0.5, y: 0, width: 0.5, height: 1.0)
        case .left60_40: return CGRect(x: 0, y: 0, width: 0.6, height: 1.0)
        case .left70_30: return CGRect(x: 0, y: 0, width: 0.7, height: 1.0)
        case .topRight: return CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5)
        case .bottomRight: return CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        case .rightOneThird: return CGRect(x: 0.7, y: 0, width: 0.3, height: 1.0)
        default: return CGRect(x: 0, y: 0, width: 1.0, height: 1.0)
        }
    }

    private func slotColor(_ category: PresetAppCategory) -> Color {
        switch category {
        case .editor: return .blue
        case .browser: return .teal
        case .terminal: return .purple
        case .notes: return .orange
        case .writing: return .indigo
        case .design: return .pink
        case .custom: return .gray
        }
    }

    private func shortLabel(_ slot: PresetAppSlot) -> String {
        switch slot.category {
        case .editor: return "Code"
        case .browser: return "Web"
        case .terminal: return "Term"
        case .notes: return "Notes"
        case .writing: return "Doc"
        case .design: return "Design"
        case .custom: return "App"
        }
    }
}
