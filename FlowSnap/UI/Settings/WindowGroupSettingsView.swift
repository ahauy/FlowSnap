import SwiftUI

/// Window Groups settings tab allowing users to inspect, create, and manage active synchronized window groups.
///
/// Traces to: US-WORK-012 (Phase 6, spec §2, contracts §1, FR-GROUP-001..006).
public struct WindowGroupSettingsView: View {

    @ObservedObject var manager: WindowGroupManager
    @State private var isShowingCreateSheet: Bool = false
    @State private var groupToAddTo: WindowGroup?

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
        .sheet(isPresented: $isShowingCreateSheet) {
            CreateWindowGroupSheet(manager: manager)
        }
        .sheet(item: $groupToAddTo) { targetGroup in
            AddWindowToGroupSheet(manager: manager, targetGroup: targetGroup)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Window Groups")
                    .font(.headline)

                Text("Linked window groups coordinate minimize, focus, and move behaviors across multiple windows.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                isShowingCreateSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                    Text("New Window Group")
                }
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .help("Select specific windows to group together")
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No Active Window Groups")
                .font(.system(size: 13, weight: .semibold))

            Text("Link two or more windows together to coordinate minimize, focus, and move operations seamlessly.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Button {
                isShowingCreateSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "link.badge.plus")
                    Text("Create Window Group...")
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

    // MARK: - Group Card

    private func groupCard(_ group: WindowGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            groupCardHeader(group)

            Divider()

            memberWindowsList(group)

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

            if NSScreen.screens.count > 1 {
                Button {
                    Task { @MainActor in
                        if let firstID = group.windowIDs.first {
                            try? await manager.handleGroupCrossDisplayThrow(triggerWindowID: firstID, isNext: true)
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "display.2")
                        Text("Next Display")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Migrate this window group to the next display")
            }

            Button("Ungroup") {
                manager.dissolveGroup(id: group.id)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Dissolve this window group")
        }
    }

    private func memberWindowsList(_ group: WindowGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Grouped Windows")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    groupToAddTo = group
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "plus")
                        Text("Add Window")
                    }
                    .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 4) {
                ForEach(Array(group.windowIDs), id: \.self) { wid in
                    memberWindowRow(wid: wid, group: group)
                }
            }
        }
    }

    private func memberWindowRow(wid: CGWindowID, group: WindowGroup) -> some View {
        let win = manager.window(for: wid)
        let app = win?.displayAppName ?? "Window"
        let detail = win?.displayDetailTitle ?? "Window ID: \(wid)"

        return HStack(spacing: 8) {
            Image(systemName: iconForWindow(win))
                .font(.system(size: 12))
                .foregroundStyle(Color.accentColor)
                .frame(width: 16)

            Text(app)
                .font(.system(size: 11, weight: .semibold))

            Text("•")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)

            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            if group.windowIDs.count > 2 {
                Button {
                    manager.removeWindow(wid, fromGroup: group.id)
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove window from this group")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(nsColor: .controlColor).opacity(0.4))
        )
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

                syncToggle(
                    title: "Cross-display move",
                    option: .crossDisplayTogether,
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

// MARK: - Create Window Group Sheet

struct CreateWindowGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: WindowGroupManager

    @State private var availableWindows: [ManagedWindow] = []
    @State private var selectedIDs: Set<CGWindowID> = []
    @State private var groupName: String = ""
    @State private var syncOptions: GroupSyncOptions = .all

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Window Group")
                    .font(.headline)
                Text("Select at least 2 windows to coordinate their actions as a unified group.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Group Name Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Group Name")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("e.g. Antigravity + Brave (YouTube)", text: $groupName)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.regular)
            }

            // Window Selection List
            VStack(alignment: .leading, spacing: 6) {
                Text("Select Windows (minimum 2)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                if availableWindows.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary)
                        Text("No other accessible windows found on screen.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(availableWindows) { win in
                                windowSelectionRow(win)
                            }
                        }
                        .padding(2)
                    }
                    .frame(maxHeight: 220)
                }
            }

            Divider()

            // Synchronization Options
            VStack(alignment: .leading, spacing: 6) {
                Text("Synchronization Behavior")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    Toggle("Minimize together", isOn: Binding(
                        get: { syncOptions.contains(.minimizeTogether) },
                        set: { if $0 { syncOptions.insert(.minimizeTogether) } else { syncOptions.remove(.minimizeTogether) } }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))

                    Toggle("Focus together", isOn: Binding(
                        get: { syncOptions.contains(.focusTogether) },
                        set: { if $0 { syncOptions.insert(.focusTogether) } else { syncOptions.remove(.focusTogether) } }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))

                    Toggle("Move together", isOn: Binding(
                        get: { syncOptions.contains(.moveTogether) },
                        set: { if $0 { syncOptions.insert(.moveTogether) } else { syncOptions.remove(.moveTogether) } }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))

                    Toggle("Cross-display move", isOn: Binding(
                        get: { syncOptions.contains(.crossDisplayTogether) },
                        set: { if $0 { syncOptions.insert(.crossDisplayTogether) } else { syncOptions.remove(.crossDisplayTogether) } }
                    ))
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                }
            }

            Divider()

            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create Group (\(selectedIDs.count) selected)") {
                    createGroupAction()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedIDs.count < 2)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            loadAvailableWindows()
        }
    }

    private func windowSelectionRow(_ win: ManagedWindow) -> some View {
        let isSelected = selectedIDs.contains(win.id)

        return HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

            Image(systemName: iconForWindow(win))
                .font(.system(size: 13))
                .foregroundStyle(Color.accentColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(win.displayAppName)
                    .font(.system(size: 12, weight: .semibold))

                Text(win.displayDetailTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Text("\(Int(win.frame.width)) × \(Int(win.frame.height))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlColor).opacity(0.4))
                .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelected {
                selectedIDs.remove(win.id)
            } else {
                selectedIDs.insert(win.id)
            }
            updateSuggestedGroupName()
        }
    }

    private func loadAvailableWindows() {
        let windows = manager.accessibilityService.allVisibleManagedWindows()
            .filter { $0.frame.width > 150 && $0.frame.height > 150 }
        manager.cacheWindows(windows)
        self.availableWindows = windows

        // Auto-select first two windows by default for convenience
        if windows.count >= 2 {
            selectedIDs = Set(windows.prefix(2).map { $0.id })
            updateSuggestedGroupName()
        }
    }

    private func updateSuggestedGroupName() {
        let selectedWindows = availableWindows.filter { selectedIDs.contains($0.id) }
        let names = selectedWindows.map { win -> String in
            let app = win.displayAppName
            let detail = win.displayDetailTitle
            if detail != "(Untitled Window)" && detail.caseInsensitiveCompare(app) != .orderedSame {
                return "\(app) (\(detail.prefix(14)))"
            }
            return app
        }
        if !names.isEmpty {
            groupName = names.joined(separator: " + ")
        }
    }

    private func createGroupAction() {
        let chosenWindows = availableWindows.filter { selectedIDs.contains($0.id) }
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Linked Window Group"
            : groupName
        manager.createGroup(name: name, windows: chosenWindows, syncOptions: syncOptions)
        dismiss()
    }
}

// MARK: - Add Window To Group Sheet

struct AddWindowToGroupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: WindowGroupManager
    let targetGroup: WindowGroup

    @State private var candidateWindows: [ManagedWindow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Add Window to Group")
                    .font(.headline)
                Text("Select an open window to add to '\(targetGroup.name)'.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if candidateWindows.isEmpty {
                VStack(spacing: 8) {
                    Text("No additional windows available to add.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(candidateWindows) { win in
                            candidateRow(win)
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .controlSize(.regular)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onAppear {
            loadCandidates()
        }
    }

    private func candidateRow(_ win: ManagedWindow) -> some View {
        HStack(spacing: 10) {
            Image(systemName: iconForWindow(win))
                .font(.system(size: 13))
                .foregroundStyle(Color.accentColor)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(win.displayAppName)
                    .font(.system(size: 12, weight: .semibold))

                Text(win.displayDetailTitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Add") {
                manager.addWindow(win.id, toGroup: targetGroup.id)
                loadCandidates()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlColor).opacity(0.4))
        )
    }

    private func loadCandidates() {
        let windows = manager.accessibilityService.allVisibleManagedWindows()
            .filter { $0.frame.width > 150 && $0.frame.height > 150 && !targetGroup.windowIDs.contains($0.id) }
        manager.cacheWindows(windows)
        self.candidateWindows = windows
    }
}

// MARK: - Helper Icon Resolver

private func iconForWindow(_ window: ManagedWindow?) -> String {
    guard let bundle = window?.bundleIdentifier?.lowercased() else { return "macwindow" }
    if bundle.contains("brave") || bundle.contains("chrome") || bundle.contains("safari") || bundle.contains("edge") {
        return "globe"
    }
    if bundle.contains("antigravity") || bundle.contains("vscode") || bundle.contains("xcode") {
        return "chevron.left.forwardslash.chevron.right"
    }
    if bundle.contains("terminal") || bundle.contains("iterm") {
        return "terminal"
    }
    if bundle.contains("finder") {
        return "folder"
    }
    if bundle.contains("slack") || bundle.contains("discord") || bundle.contains("telegram") || bundle.contains("zalo") {
        return "message"
    }
    if bundle.contains("music") || bundle.contains("spotify") {
        return "music.note"
    }
    if bundle.contains("notes") {
        return "note.text"
    }
    return "macwindow"
}
