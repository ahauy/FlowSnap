import AppKit
import SwiftUI

/// About tab in FlowSnap Settings.
///
/// Displays app metadata, permissions status, and links.
public struct AboutSettingsView: View {

    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()

    public init() {}

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

                Text("Version 1.0.0 (Build 1)")
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
                            SystemSettingsRouter.openAccessibilitySettings()
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
                Link("GitHub", destination: URL(string: "https://github.com/flowsnap/flowsnap")!)
                Text("•").foregroundStyle(.secondary)
                Link("Documentation", destination: URL(string: "https://flowsnap.dev/docs")!)
                Text("•").foregroundStyle(.secondary)
                Link("License (MIT)", destination: URL(string: "https://github.com/flowsnap/flowsnap/blob/main/LICENSE")!)
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
    }
}
