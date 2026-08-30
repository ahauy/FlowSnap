import SwiftUI

/// Preset application rule data model for UI display.
public struct AppRuleItem: Identifiable, Hashable {
    public let id = UUID()
    public let bundleID: String
    public let appName: String
    public var policyName: String
    public var iconName: String

    public init(bundleID: String, appName: String, policyName: String, iconName: String) {
        self.bundleID = bundleID
        self.appName = appName
        self.policyName = policyName
        self.iconName = iconName
    }
}

/// Per-app behavior rules configuration view.
///
/// See spec §10, §12.
public struct ApplicationRulesView: View {

    @State private var rules: [AppRuleItem] = [
        AppRuleItem(bundleID: "com.apple.calculator", appName: "Calculator", policyName: "Ignored (Floating)", iconName: "number.circle"),
        AppRuleItem(bundleID: "com.apple.systempreferences", appName: "System Settings", policyName: "Ignored (Fixed Size)", iconName: "gearshape"),
        AppRuleItem(bundleID: "com.apple.QuickTimePlayerX", appName: "QuickTime Player", policyName: "Aspect Ratio Lock", iconName: "play.tv"),
        AppRuleItem(bundleID: "com.apple.finder", appName: "Finder", policyName: "Normal Snapping", iconName: "folder")
    ]

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach($rules) { $rule in
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

                            Picker("", selection: $rule.policyName) {
                                Text("Normal Snapping").tag("Normal Snapping")
                                Text("Ignored (Floating)").tag("Ignored (Floating)")
                                Text("Ignored (Fixed Size)").tag("Ignored (Fixed Size)")
                                Text("Aspect Ratio Lock").tag("Aspect Ratio Lock")
                            }
                            .frame(width: 170)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Configured Applications")
                        .font(.headline)
                } footer: {
                    Text("Custom rules determine how FlowSnap handles specific window categories.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Button(action: addCustomRule) {
                    Label("Add Application", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Text("\(rules.count) active rules")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private func addCustomRule() {
        let newRule = AppRuleItem(
            bundleID: "com.example.custom\(rules.count + 1)",
            appName: "Custom App \(rules.count + 1)",
            policyName: "Normal Snapping",
            iconName: "app.dashed"
        )
        rules.append(newRule)
    }
}
