import AppKit
import SwiftUI

/// FlowSnap Lab — Debug & testing application.
///
/// A separate target for validating Accessibility, window control,
/// and display detection before building the production UI.
@main
struct FlowSnapLabApp: App {
    var body: some Scene {
        WindowGroup {
            FlowSnapLabView()
        }
    }
}

/// Lab UI for testing core functionality.
struct FlowSnapLabView: View {

    private let accessibilityService: AccessibilityService = AXAccessibilityService()

    @State private var isTrusted = false
    @State private var focusedWindow: ManagedWindow?
    @State private var lastInspectionTime = Date()

    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("FlowSnap Lab")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                // Permission indicator badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(isTrusted ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isTrusted ? "Trusted" : "Untrusted")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isTrusted ? .green : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            GroupBox("Accessibility & Window Discovery (US-SNAP-001)") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Permission Status:")
                            .fontWeight(.medium)
                        Text(isTrusted ? "Granted" : "Denied / Not Granted")
                            .foregroundStyle(isTrusted ? .green : .red)

                        if !isTrusted {
                            Spacer()
                            Button("Open Settings") {
                                accessibilityService.openSystemSettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }

                    Divider()

                    if let window = focusedWindow {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focused Window Details:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Title: \(window.title)")
                                .font(.system(.body, design: .monospaced))
                            Text("Bundle: \(window.bundleIdentifier ?? "nil") (PID: \(window.pid))")
                                .font(.system(.caption, design: .monospaced))
                            Text("Kind: \(window.kind.rawValue) | Snappable: \(window.kind.isSnappable ? "YES" : "NO")")
                                .font(.system(.caption, design: .monospaced))
                            Text("Frame: x=\(Int(window.frame.origin.x)), y=\(Int(window.frame.origin.y)), w=\(Int(window.frame.width)), h=\(Int(window.frame.height))")
                                .font(.system(.caption, design: .monospaced))
                        }
                    } else {
                        Text(isTrusted ? "No focused window detected (bring another app to front)" : "Grant Accessibility permission to inspect windows.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Actions") {
                HStack(spacing: 12) {
                    Button("Inspect Focused Window") {
                        refreshStatus()
                    }
                    .buttonStyle(.bordered)

                    if !isTrusted {
                        Button("Open Accessibility Settings") {
                            accessibilityService.openSystemSettings()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 520, height: 380)
        .onAppear {
            refreshStatus()
        }
        .onReceive(timer) { _ in
            refreshStatus()
        }
    }

    private func refreshStatus() {
        isTrusted = accessibilityService.isTrusted
        if isTrusted {
            focusedWindow = accessibilityService.focusedManagedWindow()
        } else {
            focusedWindow = nil
        }
        lastInspectionTime = Date()
    }
}
