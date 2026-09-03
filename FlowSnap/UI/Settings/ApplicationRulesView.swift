import SwiftUI

/// Per-app behavior rules configuration view.
///
/// See spec §37, US-WORK-014.
public struct ApplicationRulesView: View {

    @ObservedObject var store: PreferencesStore
    @State private var isShowingAddSheet = false
    @State private var newAppName = ""
    @State private var newBundleID = ""
    @State private var newPolicyType: RulePolicyType = .floating
    @State private var newZone: LayoutZone = .leftHalf

    public init(store: PreferencesStore? = nil) {
        self.store = store ?? PreferencesStore()
    }

    public enum RulePolicyType: String, CaseIterable, Identifiable {
        case currentSpace = "Current Space"
        case floating = "Floating"
        case rememberPosition = "Remember Position"
        case assignedLayout = "Assigned Layout"

        public var id: String { rawValue }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if store.appRules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Custom App Rules")
                        .font(.headline)
                    Text("Add applications to define custom floating, layout, or space behaviors.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    Section {
                        ForEach(store.appRules) { rule in
                            ruleRow(for: rule)
                        }
                    } header: {
                        Text("Configured Applications")
                            .font(.headline)
                    }
                }
            }

            Divider()

            HStack {
                Button(action: { isShowingAddSheet = true }, label: {
                    Label("Add Application", systemImage: "plus")
                })
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Text("\(store.appRules.count) active rules")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .sheet(isPresented: $isShowingAddSheet) {
            addRuleSheet
        }
    }

    @ViewBuilder
    private func ruleRow(for rule: AppPolicyRule) -> some View {
        HStack(spacing: 12) {
            Image(systemName: rule.iconName)
                .font(.title3)
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.appName)
                    .font(.body)
                    .fontWeight(.medium)
                Text(rule.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            policyControls(for: rule)

            Button(action: {
                store.removeAppRule(forBundleID: rule.bundleID)
            }, label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            })
            .buttonStyle(.plain)
            .help("Delete Rule")
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func policyControls(for rule: AppPolicyRule) -> some View {
        let currentType = policyType(for: rule.policy)

        Picker("", selection: Binding<RulePolicyType>(
            get: { currentType },
            set: { newType in
                var updated = rule
                switch newType {
                case .currentSpace:
                    updated.policy = .currentSpace
                case .floating:
                    updated.policy = .floating
                case .rememberPosition:
                    updated.policy = .rememberPosition
                case .assignedLayout:
                    updated.policy = .assignedLayout(.leftHalf)
                }
                store.setAppRule(updated)
            }
        )) {
            ForEach(RulePolicyType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .frame(width: 150)

        if case .assignedLayout(let zone) = rule.policy {
            Picker("", selection: Binding<LayoutZone>(
                get: { zone },
                set: { newZone in
                    var updated = rule
                    updated.policy = .assignedLayout(newZone)
                    store.setAppRule(updated)
                }
            )) {
                Text("Left Half").tag(LayoutZone.leftHalf)
                Text("Right Half").tag(LayoutZone.rightHalf)
                Text("Top Half").tag(LayoutZone.topHalf)
                Text("Bottom Half").tag(LayoutZone.bottomHalf)
                Text("Maximize").tag(LayoutZone.maximize)
                Text("Left 70%").tag(LayoutZone.left70_30)
                Text("Right 30%").tag(LayoutZone.rightOneThird)
                Text("Top Left").tag(LayoutZone.topLeft)
                Text("Top Right").tag(LayoutZone.topRight)
            }
            .frame(width: 120)
        }
    }

    private func policyType(for policy: WindowPolicy) -> RulePolicyType {
        switch policy {
        case .currentSpace, .currentDisplay:
            return .currentSpace
        case .floating:
            return .floating
        case .rememberPosition:
            return .rememberPosition
        case .assignedLayout:
            return .assignedLayout
        case .assignedWorkspace:
            return .currentSpace
        }
    }

    private var addRuleSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Application Rule")
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Text("Application Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. Telegram, Slack, VS Code", text: $newAppName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Bundle Identifier")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. ru.keepcoder.Telegram", text: $newBundleID)
                    .textFieldStyle(.roundedBorder)
            }

            // Quick templates
            VStack(alignment: .leading, spacing: 6) {
                Text("Quick Suggestions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    suggestionPill(name: "Slack", bundleID: "com.tinyspeck.slackmacgap")
                    suggestionPill(name: "Telegram", bundleID: "ru.keepcoder.Telegram")
                    suggestionPill(name: "Spotify", bundleID: "com.spotify.client")
                    suggestionPill(name: "VS Code", bundleID: "com.microsoft.VSCode")
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Policy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $newPolicyType) {
                    ForEach(RulePolicyType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            if newPolicyType == .assignedLayout {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Target Layout Zone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $newZone) {
                        Text("Left Half").tag(LayoutZone.leftHalf)
                        Text("Right Half").tag(LayoutZone.rightHalf)
                        Text("Maximize").tag(LayoutZone.maximize)
                        Text("Left 70%").tag(LayoutZone.left70_30)
                        Text("Right 30%").tag(LayoutZone.rightOneThird)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    isShowingAddSheet = false
                    resetAddForm()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save Rule") {
                    saveNewRule()
                    isShowingAddSheet = false
                    resetAddForm()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newAppName.trimmingCharacters(in: .whitespaces).isEmpty ||
                          newBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(width: 420)
    }

    private func suggestionPill(name: String, bundleID: String) -> some View {
        Button(action: {
            newAppName = name
            newBundleID = bundleID
        }, label: {
            Text(name)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(4)
        })
        .buttonStyle(.plain)
    }

    private func saveNewRule() {
        let policy: WindowPolicy
        switch newPolicyType {
        case .currentSpace:
            policy = .currentSpace
        case .floating:
            policy = .floating
        case .rememberPosition:
            policy = .rememberPosition
        case .assignedLayout:
            policy = .assignedLayout(newZone)
        }

        let rule = AppPolicyRule(
            bundleID: newBundleID.trimmingCharacters(in: .whitespaces),
            appName: newAppName.trimmingCharacters(in: .whitespaces),
            policy: policy,
            iconName: "app.dashed"
        )
        store.setAppRule(rule)
    }

    private func resetAddForm() {
        newAppName = ""
        newBundleID = ""
        newPolicyType = .floating
        newZone = .leftHalf
    }
}
