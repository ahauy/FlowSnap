import AppKit
import Foundation
import SwiftUI

// MARK: - View 1: Multi-Display Lab Inspector View

struct MultiDisplayLabInspectorView: View {
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

            GroupBox("Multi-Monitor & Displays (US-SNAP-003)") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Connected Displays (2):")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("Primary Height: 900pt")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.blue)
                    }

                    VStack(spacing: 6) {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("Display 1 (Primary — MacBook Pro)")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.medium)
                            Spacer()
                            Text("1440x900 @ 2x")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)

                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("Display 2 (External — Studio Display)")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.medium)
                            Spacer()
                            Text("1920x1080 @ 1x")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                    }

                    HStack {
                        Button("Move Window to Next Display (Left Half)") {}
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                        Spacer()

                        Text("Target resolution: argmax(area(Intersection))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Snap Controls") {
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
            }
        }
        .padding(20)
        .frame(width: 560, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - View 2: Coordinate Inversion Visualizer

struct CoordinateInversionVisualizerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Coordinate Inversion: AppKit vs Accessibility API")
                .font(.headline)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                // AppKit Diagram
                VStack(alignment: .leading, spacing: 6) {
                    Text("AppKit Global System (NSScreen)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 220, height: 140)
                            .background(Color.blue.opacity(0.05))

                        // Window
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.4))
                            .frame(width: 90, height: 60)
                            .offset(x: 20, y: -60)

                        Text("(0,0) Bottom-Left")
                            .font(.system(size: 9, design: .monospaced))
                            .padding(4)
                            .foregroundColor(.blue)

                        Text("Y ↑")
                            .font(.system(size: 10, weight: .bold))
                            .offset(x: 6, y: -110)
                            .foregroundColor(.blue)
                    }
                }

                // AX Diagram
                VStack(alignment: .leading, spacing: 6) {
                    Text("Accessibility API (AXUIElement)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 220, height: 140)
                            .background(Color.green.opacity(0.05))

                        // Window inverted
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.4))
                            .frame(width: 90, height: 60)
                            .offset(x: 20, y: 20)

                        Text("(0,0) Top-Left")
                            .font(.system(size: 9, design: .monospaced))
                            .padding(4)
                            .foregroundColor(.green)

                        Text("Y ↓")
                            .font(.system(size: 10, weight: .bold))
                            .offset(x: 6, y: 110)
                            .foregroundColor(.green)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Mathematical Involution Formula:")
                    .font(.caption)
                    .fontWeight(.bold)
                Text("Y_AX = H_Primary - (Y_AppKit + Height)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.purple)
                Text("Invariant: toAppKit(toAX(R, H), H) == R (100% precision, zero drift)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding(20)
        .frame(width: 560, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct DisplayAwareScreenshotGenerator {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/display-aware-manipulation")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let inspectorURL = outDir.appendingPathComponent("01_multi_display_inspector.png")
        let mathURL = outDir.appendingPathComponent("02_coordinate_inversion_visualizer.png")

        savePNG(view: MultiDisplayLabInspectorView(), to: inspectorURL)
        savePNG(view: CoordinateInversionVisualizerView(), to: mathURL)
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
    DisplayAwareScreenshotGenerator.main()
}
