import AppKit
import Foundation
import SwiftUI

// MARK: - View 1: Global Hotkeys Inspector in FlowSnap Lab

struct HotkeysLabInspectorView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("FlowSnap Lab")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Trusted")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            GroupBox("Global Hotkeys & Dispatcher Daemon (US-SNAP-004)") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("System Shortcuts Registered (8):")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Latency Budget: < 50ms")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }

                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            hotkeyCard(key: "⌃⌥←", name: "Snap Left 50%", status: "Active")
                            hotkeyCard(key: "⌃⌥→", name: "Snap Right 50%", status: "Active")
                        }
                        HStack(spacing: 8) {
                            hotkeyCard(key: "⌃⌥↑", name: "Maximize", status: "Active")
                            hotkeyCard(key: "⌃⌥↓", name: "Restore", status: "Active")
                        }
                        HStack(spacing: 8) {
                            hotkeyCard(key: "⌃⌥1", name: "Top-Left 25%", status: "Active")
                            hotkeyCard(key: "⌃⌥2", name: "Top-Right 25%", status: "Active")
                        }
                        HStack(spacing: 8) {
                            hotkeyCard(key: "⌃⌥3", name: "Bottom-Left 25%", status: "Active")
                            hotkeyCard(key: "⌃⌥4", name: "Bottom-Right 25%", status: "Active")
                        }
                    }

                    Divider()

                    HStack {
                        Text("Last Dispatched:")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(".snap(.zone(.leftHalf))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.blue)
                        Spacer()
                        Text("Response: 12ms")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .frame(width: 560, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func hotkeyCard(key: String, name: String, status: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
            Text(key)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.bold)
            Spacer()
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
}

// MARK: - View 2: Command Dispatcher Latency & Debouncing Visualizer

struct DispatcherFlowVisualizerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CommandDispatcher — Async Pipeline")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Sub-50ms Latency Budget")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 8) {
                flowStep(
                    step: "1",
                    title: "Carbon Event Hotkey Interception",
                    desc: "kEventHotKeyPressed captured without Input Monitoring TCC permission",
                    color: .purple
                )
                flowStep(
                    step: "2",
                    title: "Latest-Wins Debounce (50ms)",
                    desc: "Cancels stale in-flight snap tasks during rapid consecutive typing",
                    color: .orange
                )
                flowStep(
                    step: "3",
                    title: "Target Resolution & AX Calculation",
                    desc: "Resolves frontmost window & target display visible frame with pure math",
                    color: .blue
                )
                flowStep(
                    step: "4",
                    title: "AXUIElement Frame Application",
                    desc: "Applies new bounds and saves pre-snap frame for instant restore",
                    color: .green
                )
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .padding(20)
        .frame(width: 560, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func flowStep(step: String, title: String, desc: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 24, height: 24)
                Text(step)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Screenshot Generator

struct GlobalHotkeysScreenshotGenerator {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/global-hotkeys-dispatcher")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let inspectorURL = outDir.appendingPathComponent("01_global_hotkeys_inspector.png")
        let flowURL = outDir.appendingPathComponent("02_command_dispatcher_flow.png")

        savePNG(view: HotkeysLabInspectorView(), to: inspectorURL)
        savePNG(view: DispatcherFlowVisualizerView(), to: flowURL)
    }

    @MainActor
    static func savePNG<V: View>(view: V, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // Retina 2x
        guard let nsImage = renderer.nsImage else {
            print("Error: Could not render NSImage")
            return
        }
        guard let tiffRepresentation = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Error: Could not convert to PNG data")
            return
        }

        do {
            try pngData.write(to: url)
            print("Successfully saved screenshot to: \(url.path)")
        } catch {
            print("Error saving PNG: \(error)")
        }
    }
}

MainActor.assumeIsolated {
    GlobalHotkeysScreenshotGenerator.main()
}
