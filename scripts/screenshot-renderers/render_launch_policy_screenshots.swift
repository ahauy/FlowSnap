import AppKit
import Foundation
import SwiftUI

// MARK: - Palette
enum Palette {
    static let windowBg = Color(white: 0.95)
    static let cardBg = Color(white: 0.98)
    static let border = Color(white: 0.85)
    static let textPrimary = Color(white: 0.12)
    static let textSecondary = Color(white: 0.45)
    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let success = Color(red: 0.15, green: 0.68, blue: 0.38)
    static let redHighlight = Color(red: 0.94, green: 0.27, blue: 0.27)
}

// MARK: - View 1: Current Space Anchoring Visualization
struct SpaceAnchoringView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Circle().fill(Color.yellow).frame(width: 10, height: 10)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                }
                Spacer()
                Text("FlowSnap — Space-Aware Launch Preservation (US-WORK-013)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
            }
            .padding(.bottom, 4)

            // Spaces row
            HStack(spacing: 20) {
                // Space 1 (Active)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Space 1 (Current Active Space)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(Palette.success).frame(width: 8, height: 8)
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Palette.success)
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.92))
                            .frame(height: 180)

                        // Existing window
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Palette.border, lineWidth: 1)
                            )
                            .frame(width: 130, height: 120)
                            .offset(x: -60, y: 0)
                            .overlay(
                                VStack {
                                    Text("Safari")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Palette.textSecondary)
                                    Spacer()
                                }
                                .padding(8)
                                .offset(x: -60, y: 0)
                            )

                        // Newly launched window anchored here
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 0.98, green: 0.98, blue: 1.0))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Palette.redHighlight, lineWidth: 3.5)
                                        .shadow(color: Palette.redHighlight.opacity(0.35), radius: 6)
                                )
                                .frame(width: 150, height: 140)
                                .offset(x: 50, y: 10)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundStyle(Palette.accent)
                                    Text("Notes (New App)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Palette.textPrimary)
                                }
                                Text("Anchored to Current Space")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Palette.success)
                            }
                            .padding(8)
                            .offset(x: 50, y: 10)

                            // Badge 1
                            Text("①")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Palette.redHighlight)
                                .clipShape(Circle())
                                .offset(x: 40, y: 0)
                        }
                    }
                }
                .padding(14)
                .background(Palette.cardBg)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.border, lineWidth: 1))
                .frame(width: 320)

                // Space 2 (Background)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Space 2 (Background Space)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Palette.textSecondary)
                        Spacer()
                        Text("INACTIVE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Palette.textSecondary)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(white: 0.92))
                            .frame(height: 180)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(white: 0.2))
                            .frame(width: 260, height: 140)
                            .overlay(
                                VStack {
                                    HStack {
                                        Text("Terminal (Full Screen)")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Color.white.opacity(0.8))
                                        Spacer()
                                    }
                                    Spacer()
                                    Text("🚫 New window NOT misrouted here")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                    Spacer()
                                }
                                .padding(10)
                            )
                    }
                }
                .padding(14)
                .background(Palette.cardBg)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.border, lineWidth: 1))
                .frame(width: 320)
            }

            // Summary bar
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Palette.success)
                Text("Result: Launching an app from Dock or Spotlight always anchors it right where your eyes are.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.textPrimary)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(width: 700, height: 320)
        .background(Palette.windowBg)
    }
}

// MARK: - View 2: Accessibility Permission Setup
struct AccessibilityPermissionGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Circle().fill(Color.yellow).frame(width: 10, height: 10)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                }
                Spacer()
                Text("System Settings → Privacy & Security → Accessibility")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 14) {
                Text("Allow FlowSnap to control window placement across Spaces")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.textSecondary)

                VStack(spacing: 0) {
                    // Item 1: Other app
                    HStack {
                        Image(systemName: "terminal.fill")
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Palette.textSecondary)
                        Text("Terminal")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .labelsHidden()
                            .disabled(true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    Divider()

                    // Item 2: FlowSnap Highlighted
                    ZStack(alignment: .topLeading) {
                        HStack {
                            Image(systemName: "macwindow.on.rectangle")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(Palette.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("FlowSnap")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Palette.textPrimary)
                                Text("Window management & launch observer")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Palette.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .labelsHidden()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Palette.redHighlight, lineWidth: 3.5)
                                .shadow(color: Palette.redHighlight.opacity(0.35), radius: 6)
                        )

                        // Badge 1
                        Text("①")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Palette.redHighlight)
                            .clipShape(Circle())
                            .offset(x: -10, y: -10)
                    }
                }
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.border, lineWidth: 1))
            }
            .padding(16)
            .background(Palette.cardBg)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.border, lineWidth: 1))

            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Palette.accent)
                Text("FlowSnap requires standard macOS Accessibility permissions to adjust window coordinates on launch.")
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .padding(20)
        .frame(width: 640, height: 280)
        .background(Palette.windowBg)
    }
}

// MARK: - View 3: App Rules & Default Space Policy in Settings
struct WindowPolicySettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Window titlebar
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Circle().fill(Color.yellow).frame(width: 10, height: 10)
                    Circle().fill(Color.green).frame(width: 10, height: 10)
                }
                Spacer()
                Text("FlowSnap Settings — App Rules & Launch Behavior")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
            }
            .padding(.bottom, 2)

            // Settings Box
            VStack(alignment: .leading, spacing: 12) {
                // Section: Default Policy
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Default Launch Policy:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Palette.textPrimary)
                            Spacer()
                            Text("Current Space & Active Display")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Palette.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Palette.accent.opacity(0.12))
                                .cornerRadius(6)
                        }
                        Text("Newly created windows will automatically appear on the active desktop rather than inactive Spaces.")
                            .font(.system(size: 11))
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Palette.redHighlight, lineWidth: 3.5)
                            .shadow(color: Palette.redHighlight.opacity(0.3), radius: 5)
                    )

                    // Badge 1
                    Text("①")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Palette.redHighlight)
                        .clipShape(Circle())
                        .offset(x: -8, y: -8)
                }

                // Section: Configured App Overrides
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Per-App Exceptions (US-WORK-014):")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text("4 Active Rules")
                            .font(.system(size: 10))
                            .foregroundStyle(Palette.textSecondary)
                    }

                    VStack(spacing: 6) {
                        appRuleRow(icon: "bubble.left.and.bubble.right.fill", name: "Slack", policy: "Floating (Overlay)")
                        appRuleRow(icon: "play.circle.fill", name: "Spotify", policy: "Remember Position")
                        appRuleRow(icon: "chevron.left.forwardslash.chevron.right", name: "VS Code", policy: "Assigned: Left 70%")
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Palette.border, lineWidth: 1))
            }
            .padding(14)
            .background(Palette.cardBg)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Palette.border, lineWidth: 1))
        }
        .padding(20)
        .frame(width: 640, height: 320)
        .background(Palette.windowBg)
    }

    private func appRuleRow(icon: String, name: String, policy: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 18, height: 18)
                .foregroundStyle(Palette.accent)
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            Text(policy)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(white: 0.96))
        .cornerRadius(6)
    }
}

// MARK: - Execution

@MainActor
func savePNG<V: View>(view: V, to url: URL) {
    let renderer = ImageRenderer(content: view.environment(\.colorScheme, .light))
    renderer.scale = 2.0 // Retina 2x
    guard let nsImage = renderer.nsImage else {
        print("Error: Could not render NSImage for \(url.lastPathComponent)")
        return
    }
    guard let tiff = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Error: Could not encode PNG for \(url.lastPathComponent)")
        return
    }
    do {
        try png.write(to: url)
        print("Saved: \(url.path)")
    } catch {
        print("Error writing \(url.path): \(error)")
    }
}

@MainActor
func generateAll() {
    let repoRoot = URL(fileURLWithPath: #file)
        .deletingLastPathComponent() // scripts/
        .deletingLastPathComponent() // repo root
    let outDir = repoRoot
        .appendingPathComponent("docs/user-guides/images/app-launch-current-space-policy")
    try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

    savePNG(view: SpaceAnchoringView(), to: outDir.appendingPathComponent("01_current_space_anchoring.png"))
    savePNG(view: AccessibilityPermissionGuideView(), to: outDir.appendingPathComponent("02_accessibility_permission_status.png"))
    savePNG(view: WindowPolicySettingsView(), to: outDir.appendingPathComponent("03_window_policy_settings.png"))
}

Task { @MainActor in
    generateAll()
    exit(0)
}

dispatchMain()
