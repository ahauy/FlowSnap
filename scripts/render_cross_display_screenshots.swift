import AppKit
import Foundation
import SwiftUI

// MARK: - View 1: Cross-Display Topology & Window Throw Visualizer

struct CrossDisplayTopologyVisualizerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FlowSnap • Cross-Display Window Throw")
                        .font(.system(size: 16, weight: .bold))
                    Text("Target-Aware Semantic Snapping & Automatic Cursor Warping (US-DISP-015)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("Latency < 25ms")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Dual Display Canvas
            HStack(spacing: 24) {
                // Display 1 (MacBook Pro)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                        Text("Display 1 (MacBook Pro)")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Text("1440 × 900")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    ZStack(alignment: .topLeading) {
                        // Monitor Frame
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                            )

                        // Menu bar & Dock guides
                        VStack {
                            Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 8)
                            Spacer()
                        }

                        // Snapped Window (Left Half)
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red.opacity(0.7)).frame(width: 5, height: 5)
                                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 5, height: 5)
                                Circle().fill(Color.green.opacity(0.7)).frame(width: 5, height: 5)
                                Text("VS Code — Left Half")
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))

                            Spacer()

                            Text("50% Width\n900pt Height")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(6)
                        }
                        .frame(width: 110, height: 160)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                        )
                        .overlay(alignment: .topLeading) {
                            // Badge 1
                            ZStack {
                                Circle().fill(Color(hex: "EF4444")).frame(width: 22, height: 22)
                                Text("1")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -8, y: -8)
                        }
                        .padding([.top, .leading], 12)
                    }
                    .frame(width: 250, height: 190)
                }

                // Center Action Trajectory Arrow
                VStack(spacing: 8) {
                    // Badge 2
                    ZStack {
                        Circle().fill(Color(hex: "EF4444")).frame(width: 22, height: 22)
                        Text("2")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                        Text("⌃⌥⇧→")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(6)
                    }

                    Text("Instant Throw\n& Re-snap")
                        .font(.system(size: 10, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 110)

                // Display 2 (External 4K Display)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "display")
                            .font(.system(size: 12))
                            .foregroundStyle(.purple)
                        Text("Display 2 (External 4K)")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                        Text("3840 × 2160")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    ZStack(alignment: .topLeading) {
                        // Monitor Frame
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                            )

                        // Menu bar & Dock guides
                        VStack {
                            Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 8)
                            Spacer()
                        }

                        // Snapped Window (Re-snapped to Left Half on 4K)
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.red.opacity(0.7)).frame(width: 5, height: 5)
                                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 5, height: 5)
                                Circle().fill(Color.green.opacity(0.7)).frame(width: 5, height: 5)
                                Text("VS Code — Left Half")
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))

                            Spacer()

                            // Warped Cursor in Center
                            ZStack {
                                Circle()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "cursorarrow.rays")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)

                            Spacer()

                            Text("50% 4K Width\nTarget Gaps Applied")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.blue)
                                .padding(6)
                        }
                        .frame(width: 140, height: 160)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                        )
                        .overlay(alignment: .topLeading) {
                            // Badge 3
                            ZStack {
                                Circle().fill(Color(hex: "EF4444")).frame(width: 22, height: 22)
                                Text("3")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -8, y: -8)
                        }
                        .padding([.top, .leading], 12)
                    }
                    .frame(width: 300, height: 190)
                }
            }

            // Explanatory Footer Cards
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Text("1")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color(hex: "EF4444")))
                    Text("Focus source window")
                        .font(.system(size: 11, weight: .medium))
                }
                HStack(spacing: 8) {
                    Text("2")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color(hex: "EF4444")))
                    Text("Press ⌃⌥⇧→ shortcut")
                        .font(.system(size: 11, weight: .medium))
                }
                HStack(spacing: 8) {
                    Text("3")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color(hex: "EF4444")))
                    Text("Window re-snaps & cursor warps to center")
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(8)
        }
        .padding(20)
        .frame(width: 780, height: 380)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - View 2: Shortcuts Settings View with Display Navigation Highlight

struct DisplayNavigationShortcutsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Settings Window Titlebar
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red.opacity(0.8)).frame(width: 11, height: 11)
                    Circle().fill(Color.yellow.opacity(0.8)).frame(width: 11, height: 11)
                    Circle().fill(Color.green.opacity(0.8)).frame(width: 11, height: 11)
                }
                Spacer()
                Text("FlowSnap Settings — Shortcuts")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                // Balance spacer
                Color.clear.frame(width: 40, height: 11)
            }
            .padding(.bottom, 4)

            // Settings Content
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Display Navigation")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("2 Actions")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 10) {
                    // Row 1: Next Display
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Move to Next Display")
                                .font(.system(size: 12, weight: .medium))
                            Text("Throws active window to screen on the right (cyclic wrap)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("⌃⌥⇧→")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                        )
                        .overlay(alignment: .topLeading) {
                            ZStack {
                                Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                                Text("1")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -8, y: -8)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)

                    // Row 2: Previous Display
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Move to Previous Display")
                                .font(.system(size: 12, weight: .medium))
                            Text("Throws active window to screen on the left (cyclic wrap)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Text("⌃⌥⇧←")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                )
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                        )
                        .overlay(alignment: .topLeading) {
                            ZStack {
                                Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                                Text("2")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -8, y: -8)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
                }

                // Info Footer
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text("Click any shortcut pill to record custom keys. Press ⎋ to cancel or ⌫ to clear.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(20)
        .frame(width: 640, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - View 3: Proportional Relative Scaling Visualizer

struct ProportionalScalingVisualizerView: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Proportional Relative Scaling for Free-Floating Windows")
                        .font(.system(size: 15, weight: .bold))
                    Text("Relative percentage preservation & automatic screen border clamping")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Min: 200×200 pt")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(.orange)
                    .cornerRadius(4)
            }

            HStack(spacing: 24) {
                // Source Screen: Laptop (1440x900)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Source: Laptop (1440 × 900)")
                        .font(.system(size: 11, weight: .semibold))

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))

                        // Floating Window: 40% Width, 50% Height, 15% Offset
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Notes (Floating)")
                                .font(.system(size: 9, weight: .bold))
                                .padding(4)
                            Spacer()
                            Text("X: 15%  Y: 20%\nW: 40%  H: 50%")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(4)
                        }
                        .frame(width: 96, height: 85)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                        )
                        .overlay(alignment: .topLeading) {
                            ZStack {
                                Circle().fill(Color(hex: "EF4444")).frame(width: 18, height: 18)
                                Text("1")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -6, y: -6)
                        }
                        .offset(x: 36, y: 34)
                    }
                    .frame(width: 240, height: 170)
                }

                // Arrow
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)
                    Text("RelativeFrameScaler")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                // Target Screen: 4K (3840x2160)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Destination: 4K Display (3840 × 2160)")
                        .font(.system(size: 11, weight: .semibold))

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.4), lineWidth: 1))

                        // Scaled Window: Exactly 40% Width, 50% Height on 4K!
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Notes (Scaled)")
                                    .font(.system(size: 9, weight: .bold))
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.green)
                            }
                            .padding(4)
                            Spacer()
                            Text("X: 15%  Y: 20%\nW: 40%  H: 50%\n(Clamped)")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundStyle(.blue)
                                .padding(4)
                        }
                        .frame(width: 128, height: 110)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                        )
                        .overlay(alignment: .topLeading) {
                            ZStack {
                                Circle().fill(Color(hex: "EF4444")).frame(width: 18, height: 18)
                                Text("2")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: -6, y: -6)
                        }
                        .offset(x: 48, y: 44)
                    }
                    .frame(width: 320, height: 170)
                }
            }

            // Explanatory note
            HStack(spacing: 8) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                Text("Windows are mathematically guaranteed to stay 100% visible on screen with no off-screen clipping.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 740, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Color Hex Helper

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Main Runner

struct CrossDisplayScreenshotGenerator {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/cross-display-window-throw")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let step1URL = outDir.appendingPathComponent("01_cross_display_topology_throw.png")
        let step2URL = outDir.appendingPathComponent("02_shortcuts_settings_navigation.png")
        let step3URL = outDir.appendingPathComponent("03_proportional_relative_scaling.png")

        savePNG(view: CrossDisplayTopologyVisualizerView(), to: step1URL)
        savePNG(view: DisplayNavigationShortcutsSettingsView(), to: step2URL)
        savePNG(view: ProportionalScalingVisualizerView(), to: step3URL)
    }

    @MainActor
    static func savePNG<V: View>(view: V, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // High-DPI Retina 2x
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
    CrossDisplayScreenshotGenerator.main()
}
