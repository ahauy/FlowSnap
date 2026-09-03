import AppKit
import Foundation
import SwiftUI

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

// MARK: - View 1: Hot-Unplug Rebalancer & Frame Clamping Visualizer

struct HotUnplugVisualizerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FlowSnap • Hot-Unplug Rebalancing & Frame Clamping")
                        .font(.system(size: 16, weight: .bold))
                    Text("Safe Proportional Clamping & Auto-Snapshot on Cable Disconnect (US-DISP-016)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.orange).frame(width: 8, height: 8)
                    Text("Display Disconnected")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Unplug Flow Visualization
            HStack(spacing: 20) {
                // Step 1: External Monitor Disconnecting
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "display.trianglebadge.exclamationmark")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                        Text("External 4K Monitor")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                    .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                            )
                            .frame(width: 220, height: 160)

                        VStack(spacing: 8) {
                            Text("Unplugged Cable / Dock")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "EF4444"))
                                .padding(.top, 14)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.purple.opacity(0.15))
                                .overlay(
                                    VStack(spacing: 2) {
                                        Text("VS Code").font(.system(size: 11, weight: .bold)).foregroundStyle(.purple)
                                        Text("Right 50%").font(.system(size: 9)).foregroundStyle(.secondary)
                                    }
                                )
                                .frame(width: 170, height: 80)

                            Text("Window pushed off-screen by OS")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 220)

                        // Badge 1
                        ZStack {
                            Circle().fill(Color(hex: "EF4444")).frame(width: 22, height: 22)
                            Text("1")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -8, y: -8)
                    }
                }

                // Step 2: 600ms Hardware Debounce & Auto-Snapshot
                VStack(spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 20))
                                .foregroundStyle(.indigo)
                            Text("600ms Debounce")
                                .font(.system(size: 11, weight: .bold))
                            Text("Absorbs Flapping\n& Takes Snapshot")
                                .font(.system(size: 9))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .frame(width: 120, height: 120)
                        .background(Color(NSColor.windowBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                        )

                        // Badge 2
                        ZStack {
                            Circle().fill(Color(hex: "EF4444")).frame(width: 22, height: 22)
                            Text("2")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -8, y: -8)
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                // Step 3: Safe Clamping on MacBook Display
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "laptopcomputer")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                        Text("MacBook Primary Display (1440 × 900)")
                            .font(.system(size: 11, weight: .semibold))
                        Spacer()
                    }

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                    .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                            )
                            .frame(width: 320, height: 160)

                        VStack(spacing: 4) {
                            // Safe Menu Bar
                            HStack {
                                Text(" Menu Bar (Safe Title Bar Clearance ≥ 36pt)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))

                            // Safe Clamped Windows
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text("Safari").font(.system(size: 10, weight: .bold)).foregroundStyle(.blue)
                                            Text("Left 50%").font(.system(size: 8)).foregroundStyle(.secondary)
                                        }
                                    )
                                    .frame(width: 140, height: 100)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.purple.opacity(0.2))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text("VS Code (Clamped)").font(.system(size: 10, weight: .bold)).foregroundStyle(.purple)
                                            Text("100% In Visible Bounds").font(.system(size: 8, weight: .semibold)).foregroundStyle(.green)
                                        }
                                    )
                                    .frame(width: 140, height: 100)
                            }
                            .padding(.top, 4)
                        }

                        // Badge 3
                        ZStack {
                            Circle().fill(Color(hex: "EF4444")).frame(width: 22, height: 22)
                            Text("3")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -8, y: -8)
                    }
                }
            }

            // Highlights Row
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.green)
                    Text("Zero Off-Screen Windows Guaranteed")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.1)).cornerRadius(4)

                HStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 11))
                        .foregroundStyle(.blue)
                    Text("Auto-Saved Departing Fingerprint")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.blue.opacity(0.1)).cornerRadius(4)
            }
        }
        .padding(20)
        .frame(width: 760, height: 320)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - View 2: Hot-Plug Zero-Prompt Auto-Restore Visualizer

struct HotPlugRestoreVisualizerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FlowSnap • Hot-Plug Zero-Prompt Auto-Restoration")
                        .font(.system(size: 16, weight: .bold))
                    Text("Instant Profile Recognition & Window Re-Placement on Cable Reconnect (US-DISP-016)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("Display Connected")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }

            // Fingerprint Match Card with Badge 1 & Badge 2
            HStack(spacing: 16) {
                // Badge 1: Cable Reconnect
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 8) {
                        Image(systemName: "cable.connector.horizontal")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("1. Cable Plugged In")
                                .font(.system(size: 11, weight: .bold))
                            Text("Thunderbolt / 4K Dock")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                            .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                    )

                    // Badge 1
                    ZStack {
                        Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                        Text("1")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -6, y: -6)
                }

                // Badge 2: Fingerprint Match
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles.tv")
                            .font(.system(size: 22))
                            .foregroundStyle(.indigo)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Topology Fingerprint Matched:")
                                    .font(.system(size: 11, weight: .bold))
                                Text("TOPOLOGY-a8f3b20c...")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            Text("Profile: 'Desk Dual Monitor' (MacBook + Acer 4K) • Auto-Restore Initiated")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                            .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                    )

                    // Badge 2
                    ZStack {
                        Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                        Text("2")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -6, y: -6)
                }
                Spacer()
            }

            // Dual Display Restored Screens (Badge 3 & Badge 4)
            HStack(spacing: 20) {
                // Laptop Display (Display 0)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display 0: MacBook Laptop")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            .frame(width: 320, height: 125)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.2))
                            .overlay(Text("Safari (Left Half)").font(.system(size: 10, weight: .bold)).foregroundStyle(.blue))
                            .frame(width: 280, height: 85)
                    }
                }

                // External 4K Display (Display 1) with Badge 3 & Badge 4
                VStack(alignment: .leading, spacing: 4) {
                    Text("Display 1: External 4K Monitor")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.purple)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.windowBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                                    .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                            )
                            .frame(width: 380, height: 125)

                        HStack(spacing: 8) {
                            // Restored Window (Badge 3)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.purple.opacity(0.25))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text("VS Code").font(.system(size: 10, weight: .bold)).foregroundStyle(.purple)
                                            Text("Teleported to Right 50%").font(.system(size: 8, weight: .semibold)).foregroundStyle(.purple)
                                        }
                                    )
                                    .frame(width: 190, height: 95)

                                // Badge 3
                                ZStack {
                                    Circle().fill(Color(hex: "EF4444")).frame(width: 18, height: 18)
                                    Text("3")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: -4, y: -4)
                            }

                            // Closed App Resiliently Skipped (Badge 4)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                                    .overlay(
                                        VStack(spacing: 2) {
                                            Text("Slack (Quit while away)").font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
                                            Text("Skipped Gracefully").font(.system(size: 8, weight: .bold)).foregroundStyle(.green)
                                        }
                                    )
                                    .frame(width: 150, height: 95)

                                // Badge 4
                                ZStack {
                                    Circle().fill(Color(hex: "EF4444")).frame(width: 18, height: 18)
                                    Text("4")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: -4, y: -4)
                            }
                        }
                        .padding([.top, .leading], 10)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 760, height: 320)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - View 3: Settings & Workspace Preferences Visualizer

struct TopologySettingsVisualizerView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FlowSnap Preferences • Multi-Monitor & Topology")
                        .font(.system(size: 16, weight: .bold))
                    Text("Automated Screen Topology Profiles & Title Bar Protection Settings")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }

            // Simulated Settings Form
            VStack(spacing: 12) {
                // Setting 1: Zero-Prompt Auto-Restore Toggle
                ZStack(alignment: .topLeading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Restore on Display Reconnect")
                                .font(.system(size: 12, weight: .bold))
                            Text("Automatically restore saved window arrangements when a known monitor is connected.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    .padding(12)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                            .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                    )

                    // Badge 1
                    ZStack {
                        Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                        Text("1")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -6, y: -6)
                }

                // Setting 2: Saved Profiles Overview
                ZStack(alignment: .topLeading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Display Topology Profile")
                                .font(.system(size: 12, weight: .bold))
                            Text("Dual Screen Workstation: MacBook Pro 16\" + Acer KG270 M5 (3840 × 2160)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Synced")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .padding(12)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                            .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                    )

                    // Badge 2
                    ZStack {
                        Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                        Text("2")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -6, y: -6)
                }

                // Setting 3: Title Bar Safety Guard
                ZStack(alignment: .topLeading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enforce Title Bar Visibility on Unplug")
                                .font(.system(size: 12, weight: .bold))
                            Text("Always clamp windows below Menu Bar (safe margin ≥ 36pt) to prevent unreachable title bars.")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Enforced")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(12)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "EF4444"), lineWidth: 3.5)
                            .shadow(color: Color(hex: "EF4444").opacity(0.4), radius: 6)
                    )

                    // Badge 3
                    ZStack {
                        Circle().fill(Color(hex: "EF4444")).frame(width: 20, height: 20)
                        Text("3")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: -6, y: -6)
                }
            }
        }
        .padding(20)
        .frame(width: 760, height: 320)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Main Runner

@MainActor
func renderAndSaveImages() {
    let baseDir = "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/display-topology-profiles-hotplug"
    try? FileManager.default.createDirectory(atPath: baseDir, withIntermediateDirectories: true)

    // Render View 1: Hot-Unplug Rebalancer
    let view1 = HotUnplugVisualizerView()
    let renderer1 = ImageRenderer(content: view1)
    renderer1.scale = 2.0
    if let nsImage1 = renderer1.nsImage,
       let tiff = nsImage1.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let path1 = "\(baseDir)/01_hot_unplug_rebalancer.png"
        try? pngData.write(to: URL(fileURLWithPath: path1))
        print("Successfully rendered: \(path1)")
    }

    // Render View 2: Hot-Plug Auto-Restore
    let view2 = HotPlugRestoreVisualizerView()
    let renderer2 = ImageRenderer(content: view2)
    renderer2.scale = 2.0
    if let nsImage2 = renderer2.nsImage,
       let tiff = nsImage2.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let path2 = "\(baseDir)/02_hot_plug_auto_restore.png"
        try? pngData.write(to: URL(fileURLWithPath: path2))
        print("Successfully rendered: \(path2)")
    }

    // Render View 3: Settings Visualizer
    let view3 = TopologySettingsVisualizerView()
    let renderer3 = ImageRenderer(content: view3)
    renderer3.scale = 2.0
    if let nsImage3 = renderer3.nsImage,
       let tiff = nsImage3.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let path3 = "\(baseDir)/03_settings_topology_profiles.png"
        try? pngData.write(to: URL(fileURLWithPath: path3))
        print("Successfully rendered: \(path3)")
    }
}

MainActor.assumeIsolated {
    renderAndSaveImages()
}
