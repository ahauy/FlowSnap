import AppKit
import Combine
import SwiftUI

/// About tab in FlowSnap Settings.
///
/// Displays app metadata, permissions status, and links.
public struct AboutSettingsView: View {

    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()

    /// The About pane is where a user confirms they granted Accessibility, so the
    /// status must move on its own while the pane is open.
    private let trustPoller = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = info?["CFBundleVersion"] as? String ?? "0"
        return "Version \(short) (Build \(build))"
    }

    public init() {}

    private static let githubURL = URL(string: "https://github.com/ahauy/FlowSnap")!
    private static let websiteURL = URL(string: "https://ahauy.github.io/FlowSnap")!
    private static let licenseURL = URL(string: "https://github.com/ahauy/FlowSnap/blob/main/LICENSE")!

    public var body: some View {
        VStack(spacing: 20) {
            // App Icon and Title
            VStack(spacing: 8) {
                Image(systemName: "macwindow.on.rectangle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(Color.accentColor)

                Text("FlowSnap")
                    .font(.title)
                    .fontWeight(.bold)

                Text(versionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Smart, high-performance window snapping and tiling for macOS.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
            }

            Divider()

            // System Permissions Status Card
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: isAccessibilityTrusted ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isAccessibilityTrusted ? .green : .orange)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accessibility Permission")
                            .font(.headline)
                        Text(isAccessibilityTrusted ? "FlowSnap has full access to control windows." : "Permission required to discover and snap windows.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(isAccessibilityTrusted ? "Check Again" : "Grant Access") {
                        if isAccessibilityTrusted {
                            isAccessibilityTrusted = AXIsProcessTrusted()
                        } else {
                            // The system dialog names this app and jumps to its
                            // own row; opening Settings blind makes users tick
                            // the wrong app in a long list.
                            AXAccessibilityService().promptForTrust()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.2))
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            // Footer Links
            HStack(spacing: 16) {
                Link("GitHub", destination: Self.githubURL)
                Text("•").foregroundStyle(.secondary)
                Link("Website", destination: Self.websiteURL)
                Text("•").foregroundStyle(.secondary)
                Link("License (MIT)", destination: Self.licenseURL)
            }
            .font(.caption)

            Text("© 2026 FlowSnap Team. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .onAppear {
            isAccessibilityTrusted = AXIsProcessTrusted()
        }
        .onReceive(trustPoller) { _ in
            isAccessibilityTrusted = AXIsProcessTrusted()
        }
    }
}
