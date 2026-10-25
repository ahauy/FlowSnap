import AppKit
import Foundation
import SwiftUI

struct AnnotatedLabSnapControlsView: View {
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

            GroupBox("Focused Window Details") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title: Safari — FlowSnap Documentation")
                        .font(.system(.body, design: .monospaced))
                    Text("Kind: normal | Snappable: YES")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                    Text("Frame: x=120, y=80, w=1280, h=820")
                        .font(.system(.caption, design: .monospaced))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Snap Controls (US-SNAP-002)") {
                VStack(alignment: .leading, spacing: 10) {
                    ZStack(alignment: .topLeading) {
                        HStack(spacing: 8) {
                            Button("Snap Left") {}
                                .buttonStyle(.borderedProminent)
                            Button("Snap Right") {}
                                .buttonStyle(.borderedProminent)
                            Button("Maximize") {}
                                .buttonStyle(.borderedProminent)
                            Button("Restore") {}
                                .buttonStyle(.bordered)
                        }
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 3)
                        )

                        Text("①")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: -10, y: -10)
                    }

                    Text("Applies deterministic geometric calculation and preserves pre-snap frame.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 540, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct AnnotatedSnapAppliedView: View {
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

            GroupBox("Active Window & Snap Outcome") {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Applied Snap Target: Left Half (50%)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)

                            Text("Calculated Frame: x=0, y=25, w=720, h=875")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.semibold)

                            Text("Pre-Snap Stored: x=120, y=80, w=1280, h=820 (Ready for Restore)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 3)
                        )

                        Text("②")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: -8, y: -8)
                    }

                    HStack(spacing: 8) {
                        Button("Snap Left") {}
                            .buttonStyle(.borderedProminent)
                        Button("Snap Right") {}
                            .buttonStyle(.borderedProminent)
                        Button("Maximize") {}
                            .buttonStyle(.borderedProminent)
                        Button("Restore") {}
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 540, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

@main
struct ScreenshotGenerator {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/core-layout-snap-engine")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let controlsURL = outDir.appendingPathComponent("01_snap_controls_lab.png")
        let appliedURL = outDir.appendingPathComponent("02_snap_left_outcome.png")

        savePNG(view: AnnotatedLabSnapControlsView(), to: controlsURL)
        savePNG(view: AnnotatedSnapAppliedView(), to: appliedURL)
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

