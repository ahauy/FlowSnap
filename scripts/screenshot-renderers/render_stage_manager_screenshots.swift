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
    static let redHighlight = Color(red: 0.94, green: 0.27, blue: 0.27)
    static let codeBg = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let stageStripBg = Color(white: 0.88).opacity(0.7)
}

// MARK: - Badge Component

struct NumberBadge: View {
    let number: String

    var body: some View {
        Circle()
            .fill(GuidePalette.redHighlight)
            .frame(width: 24, height: 24)
            .overlay(
                Text(number)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Window Titlebar Component

struct WindowTitlebar: View {
    let title: String
    var badgeNumber: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle().fill(Color(red: 0.98, green: 0.37, blue: 0.34)).frame(width: 11, height: 11)
                Circle().fill(Color(red: 0.98, green: 0.74, blue: 0.22)).frame(width: 11, height: 11)
                Circle().fill(Color(red: 0.15, green: 0.78, blue: 0.25)).frame(width: 11, height: 11)
            }
            Spacer()
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(GuidePalette.textSecondary)
            Spacer()
            if let badge = badgeNumber {
                NumberBadge(number: badge)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Color(white: 0.96))
        .overlay(Divider(), alignment: .bottom)
    }
}

// MARK: - Stage Manager Sidebar Strip Mock

struct StageManagerStripMock: View {
    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 68, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.border, lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: i == 0 ? "safari.fill" : (i == 1 ? "music.note" : "terminal.fill"))
                            .font(.system(size: 18))
                            .foregroundStyle(GuidePalette.textSecondary)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            Spacer()
        }
        .padding(.vertical, 14)
        .frame(width: 84)
        .background(GuidePalette.stageStripBg)
        .overlay(Divider(), alignment: .trailing)
    }
}

// MARK: - Screen 1: Stage Manager Detection & Anchor App

struct StageManagerDetectionView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Step 1: Dynamic Detection & Anchor App Activation")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GuidePalette.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(GuidePalette.success).frame(width: 8, height: 8)
                    Text("Stage Manager Active: GloballyEnabled = 1")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GuidePalette.success)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(GuidePalette.success.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Canvas
            HStack(spacing: 0) {
                // Stage Manager Strip
                StageManagerStripMock()
                    .overlay(
                        NumberBadge(number: "1")
                            .offset(x: 24, y: -100),
                        alignment: .center
                    )

                // Desktop Stage Area
                ZStack(alignment: .leading) {
                    Color(white: 0.92)

                    // VS Code Window (Anchor App)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "VS Code — workspace.swift", badgeNumber: "2")
                        VStack(alignment: .leading, spacing: 10) {
                            Text("// Primary Anchor App (60% Left)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(GuidePalette.accent)
                            Text("func restore(workspace: Workspace) async throws {")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Color.white)
                            Text("    let isStageManager = detector.isStageManagerEnabled")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.85))
                            Text("    launcher.reveal(bundleID: anchorApp) // Step 1")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(GuidePalette.success)
                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(GuidePalette.codeBg)
                    }
                    .frame(width: 520, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GuidePalette.accent, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 4)
                    .padding(.leading, 24)

                    // Empty Right Half Placeholder
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .foregroundStyle(GuidePalette.textSecondary.opacity(0.4))
                        .frame(width: 320, height: 350)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                                    .font(.system(size: 24))
                                    .foregroundStyle(GuidePalette.textSecondary)
                                Text("Secondary App Target Zone (40%)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                        )
                        .offset(x: 560)
                }
            }
            .frame(height: 420)
        }
        .frame(width: 980, height: 490)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GuidePalette.border, lineWidth: 1)
        )
    }
}

// MARK: - Screen 2: Secondary App Staging via kAXRaiseAction

struct SecondaryAppStagingView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Step 2: Secondary App Placement & kAXRaiseAction Coordination")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GuidePalette.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(GuidePalette.success)
                    Text("No app.activate() Call • Stage Swapping Prevented")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GuidePalette.success)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(GuidePalette.success.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Canvas
            HStack(spacing: 0) {
                // Stage Manager Strip
                StageManagerStripMock()

                // Desktop Stage Area
                ZStack(alignment: .leading) {
                    Color(white: 0.92)

                    // VS Code (Anchor App)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "VS Code — workspace.swift")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("// Anchor App (Remains on Stage!)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(GuidePalette.success)
                            Text("func restore(workspace: Workspace) { ... }")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.8))
                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(GuidePalette.codeBg)
                    }
                    .frame(width: 500, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GuidePalette.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                    .padding(.leading, 20)

                    // Chrome Window (Secondary App) being raised
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Google Chrome — GitHub FlowSnap", badgeNumber: "3")
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "arrow.up.forward.app.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(GuidePalette.accent)
                                Text("Raised to current Stage via kAXRaiseAction")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(GuidePalette.textPrimary)
                            }
                            .padding(10)
                            .background(GuidePalette.accent.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text("Window element received kAXRaiseAction.\nApp remains un-swapped.")
                                .font(.system(size: 11))
                                .foregroundStyle(GuidePalette.textSecondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white)
                    }
                    .frame(width: 330, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 4)
                    .offset(x: 536)

                    // Callout Badge 4
                    NumberBadge(number: "4")
                        .offset(x: 35, y: -130)
                }
            }
            .frame(height: 420)
        }
        .frame(width: 980, height: 490)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GuidePalette.border, lineWidth: 1)
        )
    }
}

// MARK: - Screen 3: Unified Single-Stage Workspace & Focus Lock

struct SingleStageUnifiedView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Step 3: Unified Single-Stage Workspace & Final Focus Lock")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(GuidePalette.textPrimary)
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(GuidePalette.accent)
                    Text("Workspace Restored (100% Side-by-Side)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(GuidePalette.accent)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(GuidePalette.accent.opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(16)
            .background(Color.white)
            .overlay(Divider(), alignment: .bottom)

            // Canvas
            HStack(spacing: 0) {
                // Stage Manager Strip
                StageManagerStripMock()

                // Desktop Stage Area
                ZStack(alignment: .leading) {
                    Color(white: 0.92)

                    // VS Code (Anchor App, Focused)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "VS Code — Focused [Ready to Type]", badgeNumber: "5")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("// Primary Keyboard Focus Locked (BR-SMA-004)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(GuidePalette.success)
                            Text("struct CodingWorkspace {")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white)
                            Text("    let anchor = \"VS Code\" // 60%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.9))
                            Text("    let secondary = \"Chrome\" // 40%")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.9))
                            Text("}")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.white)
                            Spacer()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(GuidePalette.codeBg)
                    }
                    .frame(width: 500, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GuidePalette.accent, lineWidth: 2.5)
                    )
                    .shadow(color: Color.black.opacity(0.20), radius: 12, x: 0, y: 5)
                    .padding(.leading, 20)

                    // Chrome (Secondary App, on the same Stage!)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Google Chrome — Documentation", badgeNumber: "6")
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(GuidePalette.success)
                            Text("Both Apps on Same Stage!")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Text("No windows pushed into Stage strip.\nSeamless multi-window workflow maintained.")
                                .font(.system(size: 11))
                                .foregroundStyle(GuidePalette.textSecondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(white: 0.98))
                    }
                    .frame(width: 330, height: 350)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(GuidePalette.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
                    .offset(x: 536)
                }
            }
            .frame(height: 420)
        }
        .frame(width: 980, height: 490)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GuidePalette.border, lineWidth: 1)
        )
    }
}

// MARK: - Renderer Function

@MainActor
func renderAndSaveGuideImages() {
    let outputDir = "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/stage-manager-auto-grouping"
    try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Image 1: Detection & Anchor
    let view1 = StageManagerDetectionView()
    let renderer1 = ImageRenderer(content: view1)
    renderer1.scale = 2.0
    if let nsImage = renderer1.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/01_stage_manager_detection_and_anchor.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 2: Secondary App kAXRaiseAction
    let view2 = SecondaryAppStagingView()
    let renderer2 = ImageRenderer(content: view2)
    renderer2.scale = 2.0
    if let nsImage = renderer2.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/02_secondary_app_kaxraise_coordination.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 3: Single-Stage Unified Workspace
    let view3 = SingleStageUnifiedView()
    let renderer3 = ImageRenderer(content: view3)
    renderer3.scale = 2.0
    if let nsImage = renderer3.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/03_single_stage_multi_window_workspace.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }
}

@main
struct ScriptRunner {
    @MainActor
    static func main() {
        renderAndSaveGuideImages()
    }
}
