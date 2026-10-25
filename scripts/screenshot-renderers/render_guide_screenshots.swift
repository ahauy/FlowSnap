import SwiftUI
import AppKit

struct AnnotatedUntrustedLabView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("FlowSnap Lab")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Untrusted")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            GroupBox("Accessibility & Window Discovery (US-SNAP-001)") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Permission Status:")
                            .fontWeight(.medium)
                        Text("Denied / Not Granted")
                            .foregroundStyle(.red)

                        Spacer()

                        ZStack(alignment: .topLeading) {
                            Button("Open Settings") {}
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red, lineWidth: 3)
                                )

                            Text("①")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: -10, y: -10)
                        }
                    }

                    Divider()

                    Text("Grant Accessibility permission to inspect windows.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Actions") {
                HStack(spacing: 12) {
                    Button("Inspect Focused Window") {}
                        .buttonStyle(.bordered)
                    Button("Open Accessibility Settings") {}
                        .buttonStyle(.borderedProminent)
                }
                .padding(4)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 540, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct AnnotatedTrustedLabView: View {
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

            GroupBox("Accessibility & Window Discovery (US-SNAP-001)") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Permission Status:")
                            .fontWeight(.medium)
                        Text("Granted")
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }

                    Divider()

                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focused Window Details:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Title: Safari — FlowSnap Documentation")
                                .font(.system(.body, design: .monospaced))
                            Text("Bundle: com.apple.Safari (PID: 1420)")
                                .font(.system(.caption, design: .monospaced))
                            Text("Kind: normal | Snappable: YES")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                            Text("Frame: x=120, y=80, w=1280, h=820")
                                .font(.system(.caption, design: .monospaced))
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red, lineWidth: 3)
                        )

                        Text("②")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: -8, y: -8)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Actions") {
                HStack(spacing: 12) {
                    Button("Inspect Focused Window") {}
                        .buttonStyle(.borderedProminent)
                }
                .padding(4)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 540, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

@main
struct ScreenshotGenerator {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/accessibility-window-discovery")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let untrustedURL = outDir.appendingPathComponent("01_untrusted_permission_prompt.png")
        let trustedURL = outDir.appendingPathComponent("02_trusted_window_inspector.png")

        savePNG(view: AnnotatedUntrustedLabView(), to: untrustedURL)
        savePNG(view: AnnotatedTrustedLabView(), to: trustedURL)
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
