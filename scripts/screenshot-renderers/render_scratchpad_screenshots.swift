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
    static let codeBg = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let scratchCyan = Color(red: 0.0, green: 0.72, blue: 0.88)
}

// MARK: - Components

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
            .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
    }
}

struct WindowTitlebar: View {
    let title: String
    var isScratchpad: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Traffic lights
            HStack(spacing: 6) {
                Circle().fill(Color(red: 0.98, green: 0.37, blue: 0.34)).frame(width: 10, height: 10)
                Circle().fill(Color(red: 0.98, green: 0.74, blue: 0.22)).frame(width: 10, height: 10)
                Circle().fill(Color(red: 0.16, green: 0.77, blue: 0.28)).frame(width: 10, height: 10)
            }

            Spacer()

            HStack(spacing: 5) {
                if isScratchpad {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 10))
                        .foregroundStyle(GuidePalette.scratchCyan)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isScratchpad ? Color.white : GuidePalette.textPrimary)
            }

            Spacer()

            // Balance traffic lights width
            Color.clear.frame(width: 42, height: 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isScratchpad ? Color(red: 0.14, green: 0.15, blue: 0.18) : Color(white: 0.96))
    }
}

// MARK: - View 1: Instant Scratchpad Summon Overlay

struct ScratchpadInstantSummonView: View {
    var body: some View {
        ZStack {
            // Desktop background wallpaper
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.18, blue: 0.28), Color(red: 0.07, green: 0.09, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // macOS Menu Bar
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                    Text("Code")
                        .fontWeight(.bold)
                    Text("File")
                    Text("Edit")
                    Text("View")
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "macwindow.badge.plus")
                            .foregroundStyle(GuidePalette.scratchCyan)
                        Text("Scratchpad: iTerm2 (⌥Space)")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(4)
                    Text("Fri Sep 4  09:40")
                }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .frame(height: 24)
                .background(Color.black.opacity(0.35))

                // Desktop Space Canvas
                ZStack(alignment: .topLeading) {
                    // 1. Background Unpinned App (VS Code - 100% full frame, Zero-Shrink)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Visual Studio Code — FlowSnap (Background App — Zero Shrink)")
                        Divider()
                        HStack(spacing: 0) {
                            // Sidebar
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EXPLORER").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.4))
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.down").font(.system(size: 8))
                                    Text("FLOWSNAP").font(.system(size: 10, weight: .semibold))
                                }
                                Text("  › Core/Policy").font(.system(size: 10))
                                Text("    ScratchpadCoordinator.swift").font(.system(size: 10)).foregroundStyle(GuidePalette.scratchCyan)
                                Text("  › Domain/Window").font(.system(size: 10))
                                Text("  › UI/MenuBar").font(.system(size: 10))
                                Spacer()
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(10)
                            .frame(width: 170)
                            .background(Color(red: 0.12, green: 0.13, blue: 0.16))

                            // Editor Canvas
                            VStack(alignment: .leading, spacing: 4) {
                                Text("ScratchpadCoordinator.swift").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
                                Divider().background(Color.white.opacity(0.1))
                                Text("1  @MainActor").foregroundStyle(.purple)
                                Text("2  public final class ScratchpadCoordinator: ScratchpadCoordinating {").foregroundStyle(.blue)
                                Text("3      public func toggle() async {").foregroundStyle(.green)
                                Text("4          // Instant summon in < 50ms with zero-shrink on background apps").foregroundStyle(.secondary)
                                Text("5          if state.isVisible { await dismiss() } else { await summon() }").foregroundStyle(.orange)
                                Text("6      }").foregroundStyle(.blue)
                                Text("7  }").foregroundStyle(.blue)
                                Spacer()
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.15, green: 0.16, blue: 0.20))
                        }
                    }
                    .frame(width: 800, height: 440)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    .offset(x: 40, y: 20)
                    .overlay(
                        // Annotation ②: Background App Zero Shrink
                        ZStack(alignment: .topTrailing) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                            NumberBadge(number: "②")
                                .offset(x: 12, y: -12)
                        }
                        .frame(width: 800, height: 440)
                        .offset(x: 40, y: 20)
                    )

                    // 2. Foreground Quake Scratchpad Window (iTerm2 - Instant Summon)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "iTerm2 — Quake Quick Scratchpad (Floating Overlay)", isScratchpad: true)
                        Divider().background(Color.white.opacity(0.15))

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("vutuanhau@MacBook-Pro")
                                    .foregroundStyle(Color.green)
                                Text("in")
                                    .foregroundStyle(Color.white.opacity(0.6))
                                Text("~/Documents/PROJECT/FlowSnap")
                                    .foregroundStyle(GuidePalette.scratchCyan)
                                Text("on")
                                    .foregroundStyle(Color.white.opacity(0.6))
                                Text("feat/quake-scratchpad")
                                    .foregroundStyle(Color.purple)
                            }
                            .font(.system(size: 10, weight: .medium, design: .monospaced))

                            HStack(spacing: 4) {
                                Text("❯")
                                    .foregroundStyle(GuidePalette.scratchCyan)
                                    .font(.system(size: 10, weight: .bold))
                                Text("git status")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 10, design: .monospaced))
                            }

                            Text("On branch feat/quake-scratchpad-instant-toggle\nNothing to commit, working tree clean\nLatency: 18ms (Summon Target < 50ms)")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.75))
                                .lineSpacing(3)

                            Spacer()

                            HStack {
                                Label("Quick Scratchpad Active", systemImage: "bolt.fill")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundStyle(GuidePalette.scratchCyan)
                                Spacer()
                                Text("Press ⌥Space or ESC to dismiss")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .padding(.top, 4)
                        }
                        .padding(12)
                        .background(Color(red: 0.08, green: 0.09, blue: 0.12))
                    }
                    .frame(width: 540, height: 250)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.65), radius: 18, x: 0, y: 10)
                    .offset(x: 170, y: 60)
                    .overlay(
                        // Annotation ①: Floating Scratchpad
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.0)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.5), radius: 8)
                            NumberBadge(number: "①")
                                .offset(x: -12, y: -12)
                        }
                        .frame(width: 540, height: 250)
                        .offset(x: 170, y: 60)
                    )

                    // 3. HUD Callout Indicator: Shortcut & Latency
                    HStack(spacing: 8) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 12))
                            .foregroundStyle(GuidePalette.scratchCyan)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("⌥Space Summon")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Immediate Keyboard Focus • Zero Spatial Shift")
                                .font(.system(size: 9.5))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )
                    .offset(x: 480, y: 350)
                    .overlay(
                        NumberBadge(number: "③")
                            .offset(x: 468, y: 338)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 880, height: 500)
    }
}

// MARK: - View 2: Menu Bar Scratchpad Controls

struct MenuBarScratchpadControlsView: View {
    var body: some View {
        ZStack {
            Color(white: 0.92)

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    Image(systemName: "rectangle.split.2x1")
                        .font(.system(size: 13, weight: .semibold))
                    Text("FlowSnap")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("Ready")
                        .font(.system(size: 9.5, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .foregroundStyle(Color.green)
                        .cornerRadius(4)
                }

                Divider()

                // Quick Scratchpad Section
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("QUICK SCRATCHPAD")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Detach")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(GuidePalette.accent)
                    }

                    // Assigned status item
                    HStack(spacing: 6) {
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 11))
                            .foregroundStyle(GuidePalette.scratchCyan)
                            .frame(width: 14)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("iTerm2")
                                .font(.system(size: 11, weight: .medium))
                            Text("zsh — 120×40")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text("⌥Space")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(white: 0.88))
                    )

                    // Assign focused window action
                    HStack(spacing: 6) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 11))
                            .frame(width: 14)
                        Text("Assign Focused Window")
                            .font(.system(size: 11))
                        Spacer()
                        Text("⌃⌥Space")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(white: 0.88))
                    )
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white)
                )
                .overlay(
                    // Red highlight ① around Quick Scratchpad section
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                        NumberBadge(number: "①")
                            .offset(x: -10, y: -10)
                    }
                )

                // Annotation ② for Assign action
                HStack {
                    Spacer()
                }
                .overlay(
                    NumberBadge(number: "②")
                        .offset(x: 120, y: -28)
                )

                // Annotation ③ for Detach action
                HStack {
                    Spacer()
                }
                .overlay(
                    NumberBadge(number: "③")
                        .offset(x: 128, y: -94)
                )

                // Footer
                Divider()
                HStack {
                    Text("Settings...")
                        .font(.system(size: 11))
                    Spacer()
                    Text("⌘,")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(width: 290)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
        }
        .frame(width: 380, height: 320)
    }
}

// MARK: - View 3: General Settings Scratchpad Toggles

struct GeneralSettingsScratchpadView: View {
    var body: some View {
        ZStack {
            Color(white: 0.94)

            VStack(spacing: 0) {
                // Settings Toolbar
                HStack(spacing: 16) {
                    VStack(spacing: 3) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                        Text("General")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(GuidePalette.accent)
                    .padding(.bottom, 2)
                    .overlay(Rectangle().fill(GuidePalette.accent).frame(height: 2), alignment: .bottom)

                    VStack(spacing: 3) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 14))
                        Text("Shortcuts")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.secondary)

                    VStack(spacing: 3) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                        Text("About")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(white: 0.96))
                Divider()

                // Settings Content
                VStack(alignment: .leading, spacing: 14) {
                    // Quick Scratchpad Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Quick Scratchpad")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GuidePalette.textPrimary)

                        // Toggle 1: Dismiss on ESC
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(GuidePalette.accent)
                                    .frame(width: 32, height: 18)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .offset(x: 7)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dismiss on ESC key")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GuidePalette.textPrimary)
                                Text("Pressing Escape while Scratchpad is focused immediately tucks it away.")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2)
                        )
                        .overlay(
                            NumberBadge(number: "①")
                                .offset(x: -8, y: -8),
                            alignment: .topLeading
                        )

                        // Toggle 2: Dismiss on blur / click outside
                        HStack(alignment: .top, spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(white: 0.78))
                                    .frame(width: 32, height: 18)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 14, height: 14)
                                    .offset(x: -7)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dismiss when clicking outside")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(GuidePalette.textPrimary)
                                Text("Clicking anywhere on a background application automatically dismisses the Scratchpad.")
                                    .font(.system(size: 9.5))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2)
                        )
                        .overlay(
                            NumberBadge(number: "②")
                                .offset(x: -8, y: -8),
                            alignment: .topLeading
                        )
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.border, lineWidth: 1)
                    )
                }
                .padding(16)
                Spacer()
            }
            .frame(width: 440, height: 280)
            .background(Color(white: 0.98))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .frame(width: 500, height: 340)
    }
}

// MARK: - Main Execution

@MainActor
func renderAndSaveAllScreenshots() {
    let outputDir = "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/quake-scratchpad-instant-toggle"
    try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Image 1: Instant Scratchpad Summon Overlay
    let view1 = ScratchpadInstantSummonView()
    let renderer1 = ImageRenderer(content: view1)
    renderer1.scale = 2.0
    if let nsImage = renderer1.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/01_scratchpad_instant_summon.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 2: Menu Bar Controls
    let view2 = MenuBarScratchpadControlsView()
    let renderer2 = ImageRenderer(content: view2)
    renderer2.scale = 2.0
    if let nsImage = renderer2.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/02_menubar_scratchpad_controls.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 3: General Settings Toggles
    let view3 = GeneralSettingsScratchpadView()
    let renderer3 = ImageRenderer(content: view3)
    renderer3.scale = 2.0
    if let nsImage = renderer3.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/03_settings_scratchpad_toggles.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }
}

MainActor.assumeIsolated {
    renderAndSaveAllScreenshots()
}
