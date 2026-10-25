import AppKit
import Foundation
import SwiftUI

// MARK: - Palette Constants

enum GuidePalette {
    static let canvasBg = Color(white: 0.94)
    static let cardBg = Color.white
    static let border = Color(white: 0.86)
    static let textPrimary = Color(white: 0.12)
    static let textSecondary = Color(white: 0.45)
    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let success = Color(red: 0.15, green: 0.68, blue: 0.38)
    static let warning = Color(red: 0.95, green: 0.60, blue: 0.10)
    static let redHighlight = Color(red: 0.94, green: 0.27, blue: 0.27) // #EF4444
}

// MARK: - Annotation Badge Component

struct NumberBadge: View {
    let number: String

    var body: some View {
        Circle()
            .fill(GuidePalette.redHighlight)
            .frame(width: 22, height: 22)
            .overlay(
                Text(number)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Window Shell Wrapper

struct MacWindowShell<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Window Titlebar
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(Color(red: 1.0, green: 0.38, blue: 0.35)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.22)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 0.20, green: 0.78, blue: 0.35)).frame(width: 11, height: 11)
                }

                Spacer()

                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GuidePalette.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(GuidePalette.textSecondary)
                    }
                }

                Spacer()

                Color.clear.frame(width: 45, height: 11)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(white: 0.96))
            .overlay(
                Divider(),
                alignment: .bottom
            )

            // Content Body
            content
        }
        .background(GuidePalette.canvasBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(GuidePalette.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

// MARK: - View 1: Annotated Launch at Login Toggle in Settings

struct AnnotatedLaunchAtLoginSettingsView: View {
    var body: some View {
        MacWindowShell(title: "FlowSnap Settings", subtitle: "General Preferences") {
            VStack(alignment: .leading, spacing: 14) {
                // Tab Bar
                HStack(spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape.fill")
                        Text("General")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)

                    HStack(spacing: 5) {
                        Image(systemName: "command")
                        Text("Shortcuts")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(GuidePalette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)

                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.3.group")
                        Text("Window Groups")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(GuidePalette.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)

                    Spacer()
                }
                .padding(.bottom, 4)

                // Settings Group Card: Launch Policy
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(GuidePalette.accent)
                        Text("Launch Policy")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(GuidePalette.textPrimary)
                    }

                    // Highlighted Toggle Row
                    ZStack(alignment: .topLeading) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Launch FlowSnap at login")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GuidePalette.textPrimary)
                                Text("Automatically start FlowSnap in the menu bar when logging in to macOS.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }

                            Spacer()

                            // Simulated Toggle Switch ON
                            ZStack(alignment: .trailing) {
                                Capsule()
                                    .fill(GuidePalette.accent)
                                    .frame(width: 38, height: 22)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 18, height: 18)
                                    .padding(2)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                        }
                        .padding(10)
                        .background(Color(white: 0.98))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                        )

                        NumberBadge(number: "①")
                            .offset(x: -8, y: -8)
                    }

                    Divider()

                    // Highlighted Settings Link
                    ZStack(alignment: .topLeading) {
                        HStack {
                            HStack(spacing: 5) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(GuidePalette.success)
                                Text("Managed by macOS ServiceManagement")
                                    .font(.system(size: 11))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("Login Items Settings…")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(GuidePalette.accent)
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GuidePalette.accent)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(white: 0.98))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                        )

                        NumberBadge(number: "②")
                            .offset(x: -8, y: -8)
                    }
                }
                .padding(16)
                .background(GuidePalette.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(GuidePalette.border, lineWidth: 1)
                )
            }
            .padding(16)
        }
        .frame(width: 520, height: 320)
        .padding(20)
        .background(Color(white: 0.90))
    }
}

// MARK: - View 2: Annotated Approval Required State

struct AnnotatedApprovalRequiredSettingsView: View {
    var body: some View {
        MacWindowShell(title: "FlowSnap Settings", subtitle: "General Preferences — Approval State") {
            VStack(alignment: .leading, spacing: 14) {
                // Settings Group Card: Launch Policy
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(GuidePalette.accent)
                        Text("Launch Policy")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(GuidePalette.textPrimary)
                        Spacer()
                        Text("Requires Approval")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(GuidePalette.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(GuidePalette.warning.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    // Toggle Row (Disabled / Blocked)
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Launch FlowSnap at login")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Text("Approval is currently needed from macOS System Settings.")
                                .font(.system(size: 11))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }

                        Spacer()

                        // Toggle OFF
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(white: 0.80))
                                .frame(width: 38, height: 22)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                                .padding(2)
                                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                        }
                    }
                    .padding(10)
                    .background(Color(white: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Highlighted Warning Card
                    ZStack(alignment: .topLeading) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Approval required in macOS System Settings")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GuidePalette.textPrimary)
                                Text("Login items are restricted by system policy. Click to approve.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }

                            Spacer()

                            // Highlighted Action Button
                            HStack(spacing: 4) {
                                Text("Open Login Items…")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                    .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                            )
                            .overlay(
                                NumberBadge(number: "②")
                                    .offset(x: -8, y: -8),
                                alignment: .topLeading
                            )
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                        )

                        NumberBadge(number: "①")
                            .offset(x: -8, y: -8)
                    }

                    Divider()

                    HStack {
                        Text("Managed by macOS ServiceManagement")
                            .font(.system(size: 11))
                            .foregroundStyle(GuidePalette.textSecondary)
                        Spacer()
                        Text("Login Items Settings…")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(GuidePalette.accent)
                    }
                }
                .padding(16)
                .background(GuidePalette.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(GuidePalette.border, lineWidth: 1)
                )
            }
            .padding(16)
        }
        .frame(width: 520, height: 320)
        .padding(20)
        .background(Color(white: 0.90))
    }
}

// MARK: - View 3: Annotated macOS System Settings Sync

struct AnnotatedSystemSettingsSyncView: View {
    var body: some View {
        MacWindowShell(title: "System Settings", subtitle: "General > Login Items & Extensions") {
            VStack(alignment: .leading, spacing: 14) {
                // Section Title
                VStack(alignment: .leading, spacing: 2) {
                    Text("Open at Login")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(GuidePalette.textPrimary)
                    Text("Items that open automatically when you log in to your Mac.")
                        .font(.system(size: 11))
                        .foregroundStyle(GuidePalette.textSecondary)
                }

                // Login items table
                VStack(spacing: 0) {
                    // Highlighted FlowSnap row
                    ZStack(alignment: .topLeading) {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(GuidePalette.accent)
                                    .frame(width: 28, height: 28)
                                Image(systemName: "rectangle.split.2x1")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("FlowSnap")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(GuidePalette.textPrimary)
                                    Text("SMAppService.mainApp")
                                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(GuidePalette.accent)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(GuidePalette.accent.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                                Text("com.flowsnap.app — Window Management Daemon")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }

                            Spacer()

                            // Active Toggle Switch
                            ZStack(alignment: .trailing) {
                                Capsule()
                                    .fill(GuidePalette.accent)
                                    .frame(width: 36, height: 20)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 16, height: 16)
                                    .padding(2)
                                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            }
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                        )

                        NumberBadge(number: "①")
                            .offset(x: -8, y: -8)
                    }

                    Divider().padding(.vertical, 4)

                    // Other sample row
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 28, height: 28)
                            Image(systemName: "music.note")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Music Helper")
                                .font(.system(size: 12))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Text("Background extension")
                                .font(.system(size: 10))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }

                        Spacer()

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(white: 0.82))
                                .frame(width: 36, height: 20)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                                .padding(2)
                        }
                    }
                    .padding(8)
                }
                .padding(12)
                .background(GuidePalette.cardBg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(GuidePalette.border, lineWidth: 1)
                )

                // Sync callout
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(GuidePalette.success)
                        .font(.system(size: 11, weight: .bold))
                    Text("Two-Way Sync Active: FlowSnap settings update instantly when toggled here.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(GuidePalette.textSecondary)
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
        }
        .frame(width: 520, height: 320)
        .padding(20)
        .background(Color(white: 0.90))
    }
}

// MARK: - Main Generator Executable

struct LaunchAtLoginScreenshotGenerator {
    @MainActor
    static func main() {
        let outDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/launch-at-login")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        let step1URL = outDir.appendingPathComponent("01_launch_at_login_toggle.png")
        let step2URL = outDir.appendingPathComponent("02_approval_required_state.png")
        let step3URL = outDir.appendingPathComponent("03_macos_login_items_sync.png")

        savePNG(view: AnnotatedLaunchAtLoginSettingsView(), to: step1URL)
        savePNG(view: AnnotatedApprovalRequiredSettingsView(), to: step2URL)
        savePNG(view: AnnotatedSystemSettingsSyncView(), to: step3URL)
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
    LaunchAtLoginScreenshotGenerator.main()
}
