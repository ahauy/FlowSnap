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
    static let pinOrange = Color(red: 0.98, green: 0.45, blue: 0.15)
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
    var isPinned: Bool = false

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
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(GuidePalette.pinOrange)
                }
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(GuidePalette.textPrimary)
            }

            Spacer()

            // Balance traffic lights width
            Color.clear.frame(width: 42, height: 10)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(white: 0.96))
    }
}

// MARK: - View 1: Always-On-Top Floating Stack

struct AlwaysOnTopFloatingStackView: View {
    var body: some View {
        ZStack {
            // Desktop background
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.24, blue: 0.34), Color(red: 0.08, green: 0.12, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Wallpaper subtle grid
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
                        Image(systemName: "pin.fill")
                            .foregroundStyle(GuidePalette.pinOrange)
                        Text("FlowSnap: 2 Pinned")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(4)
                    Text("Fri Sep 4  07:45")
                }
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 16)
                .frame(height: 24)
                .background(Color.black.opacity(0.35))

                // Desktop Space Canvas
                ZStack(alignment: .topLeading) {
                    // 1. Background Unpinned Window (VS Code)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Visual Studio Code — FlowSnap (Unpinned Background)")
                        Divider()
                        HStack(spacing: 0) {
                            // Sidebar
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EXPLORER").font(.system(size: 9, weight: .bold)).foregroundStyle(.white.opacity(0.4))
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.down").font(.system(size: 8))
                                    Text("FLOWSNAP").font(.system(size: 10, weight: .semibold))
                                }
                                Text("  › Domain").font(.system(size: 10))
                                Text("  › Policy").font(.system(size: 10))
                                Text("  › UI").font(.system(size: 10))
                                Spacer()
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(10)
                            .frame(width: 140)
                            .background(Color(red: 0.12, green: 0.13, blue: 0.16))

                            // Editor
                            VStack(alignment: .leading, spacing: 4) {
                                Text("WindowPinningCoordinator.swift").font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.9))
                                Divider().background(Color.white.opacity(0.1))
                                Text("1  import AppKit").foregroundStyle(.purple)
                                Text("2  import ApplicationServices").foregroundStyle(.purple)
                                Text("3  ").foregroundStyle(.secondary)
                                Text("4  public final class WindowPinningCoordinator {").foregroundStyle(.blue)
                                Text("5      public func handleFocusChange() async {").foregroundStyle(.green)
                                Text("6          // Re-assert pinned stack from bottom to top").foregroundStyle(.secondary)
                                Text("7          await reassertPinnedWindows()").foregroundStyle(.orange)
                                Text("8      }").foregroundStyle(.blue)
                                Text("9  }").foregroundStyle(.blue)
                                Spacer()
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(red: 0.15, green: 0.16, blue: 0.20))
                        }
                    }
                    .frame(width: 580, height: 350)
                    .background(Color(white: 0.15))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    .offset(x: 30, y: 20)

                    // 2. Pinned Window 2: Calculator (Lower in LIFO stack)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Calculator", isPinned: true)
                        Divider()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("1,440.00")
                                .font(.system(size: 20, weight: .light, design: .monospaced))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 10)
                                .padding(.top, 12)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
                                ForEach(["C", "±", "%", "÷", "7", "8", "9", "×", "4", "5", "6", "−", "1", "2", "3", "+"], id: \.self) { btn in
                                    Text(btn)
                                        .font(.system(size: 11, weight: .semibold))
                                        .frame(height: 24)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(4)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(8)
                        }
                        .background(Color(red: 0.18, green: 0.19, blue: 0.22))
                    }
                    .frame(width: 170, height: 190)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .offset(x: 540, y: 50)
                    .overlay(
                        // Annotation ③ for lower pinned window
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 5)
                            NumberBadge(number: "③")
                                .offset(x: -12, y: -12)
                        }
                        .offset(x: 540, y: 50)
                    )

                    // 3. Pinned Window 1: Safari Documentation (Frontmost Pinned - LIFO Top)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Safari — macOS Accessibility API Reference", isPinned: true)
                        Divider()
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill").font(.system(size: 9)).foregroundStyle(.secondary)
                                Text("developer.apple.com/documentation/accessibility")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(white: 0.93))
                            .cornerRadius(4)

                            Text("kAXRaiseAction")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(GuidePalette.textPrimary)

                            Text("Raises the specified window to the top of its level without activating the owning process or stealing keyboard focus.")
                                .font(.system(size: 10))
                                .foregroundStyle(GuidePalette.textSecondary)
                                .lineLimit(3)

                            HStack {
                                Label("Always-On-Top Active", systemImage: "pin.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(GuidePalette.pinOrange)
                                Spacer()
                                Text("LIFO Rank: #1 (Topmost)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(GuidePalette.pinOrange.opacity(0.12))
                                    .cornerRadius(4)
                                    .foregroundStyle(GuidePalette.pinOrange)
                            }
                            .padding(.top, 4)
                        }
                        .padding(12)
                        .background(Color.white)
                    }
                    .frame(width: 320, height: 180)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.6), radius: 14, x: 0, y: 8)
                    .offset(x: 370, y: 150)
                    .overlay(
                        // Annotation ① for frontmost pinned window
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.5), radius: 7)
                            NumberBadge(number: "①")
                                .offset(x: -12, y: -12)
                        }
                        .offset(x: 370, y: 150)
                    )

                    // 4. Hotkey Trigger Toast HUD
                    HStack(spacing: 8) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(GuidePalette.pinOrange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pinned Window (Always-On-Top)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Press ⌃⌥P to unpin")
                                .font(.system(size: 9))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                    .offset(x: 50, y: 320)
                    .overlay(
                        // Annotation ② for hotkey indicator HUD
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 5)
                            NumberBadge(number: "②")
                                .offset(x: -10, y: -10)
                        }
                        .offset(x: 50, y: 320)
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 780, height: 440)
    }
}

// MARK: - View 2: Menu Bar Pinned Controls

struct MenuBarPinnedControlsView: View {
    var body: some View {
        ZStack {
            Color(white: 0.92)

            VStack(spacing: 0) {
                // Mock macOS Menu Bar
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 12))
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(GuidePalette.pinOrange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.12))
                    .cornerRadius(4)
                    Spacer().frame(width: 80)
                }
                .frame(height: 28)
                .background(Color.white.opacity(0.8))

                // Menu Bar Dropdown
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack {
                        Text("FlowSnap")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("v1.0.0")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)

                    Divider().padding(.vertical, 4)

                    // Quick Snap actions
                    Group {
                        Text("QUICK SNAP").font(.system(size: 9, weight: .bold)).foregroundStyle(.secondary)
                            .padding(.horizontal, 14).padding(.vertical, 2)
                        HStack {
                            Text("Left Half")
                            Spacer()
                            Text("⌃⌥←").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 4)
                        HStack {
                            Text("Right Half")
                            Spacer()
                            Text("⌃⌥→").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 4)
                    }

                    Divider().padding(.vertical, 4)

                    // PINNED WINDOWS SECTION (Highlighted)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label("PINNED WINDOWS (2)", systemImage: "pin.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GuidePalette.pinOrange)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 4)

                        // Pinned Item 1
                        HStack {
                            Image(systemName: "globe")
                                .font(.system(size: 11))
                                .foregroundStyle(.blue)
                            Text("Safari — Documentation")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            // Unpin button (Highlighted ②)
                            Text("Unpin")
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(white: 0.92))
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(GuidePalette.redHighlight, lineWidth: 2)
                                )
                                .overlay(
                                    NumberBadge(number: "②")
                                        .offset(x: -12, y: -12),
                                    alignment: .topLeading
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)

                        // Pinned Item 2
                        HStack {
                            Image(systemName: "function")
                                .font(.system(size: 11))
                                .foregroundStyle(.orange)
                            Text("Calculator")
                                .font(.system(size: 11, weight: .medium))
                                .lineLimit(1)
                            Spacer()
                            Text("Unpin")
                                .font(.system(size: 10))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(white: 0.92))
                                .cornerRadius(4)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)

                        // Unpin All Button (Highlighted ③)
                        HStack {
                            Spacer()
                            Text("Unpin All Windows")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(GuidePalette.redHighlight)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .background(GuidePalette.redHighlight.opacity(0.08))
                        .cornerRadius(6)
                        .padding(.horizontal, 14)
                        .padding(.top, 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2)
                                .padding(.horizontal, 14)
                                .padding(.top, 4)
                        )
                        .overlay(
                            NumberBadge(number: "③")
                                .offset(x: 4, y: -4),
                            alignment: .topLeading
                        )
                    }
                    .padding(.vertical, 6)
                    .background(Color(white: 0.97))
                    .cornerRadius(8)
                    .padding(.horizontal, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                            .padding(.horizontal, 8)
                    )
                    .overlay(
                        NumberBadge(number: "①")
                            .offset(x: -2, y: -8),
                        alignment: .topLeading
                    )

                    Divider().padding(.vertical, 4)

                    // Footer
                    Group {
                        HStack {
                            Text("Preferences…")
                            Spacer()
                            Text("⌘,").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 4)
                        HStack {
                            Text("Quit FlowSnap")
                            Spacer()
                            Text("⌘Q").font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 4)
                    }
                    .padding(.bottom, 8)
                }
                .frame(width: 290)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.25), radius: 14, x: 0, y: 8)
                .padding(.top, 10)

                Spacer()
            }
        }
        .frame(width: 780, height: 460)
    }
}

// MARK: - View 3: Stage Manager Launch Co-existence

struct StageManagerCoexistenceView: View {
    var body: some View {
        ZStack {
            // Stage Manager Desktop Background
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.18, blue: 0.28), Color(red: 0.05, green: 0.10, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 20) {
                // 1. Stage Manager Left Strip (Inactive Stages)
                VStack(spacing: 12) {
                    Text("STAGE STRIP").font(.system(size: 8, weight: .bold)).foregroundStyle(.white.opacity(0.4))

                    // Thumbnail Group 1
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 68, height: 42)
                        Text("Notes").font(.system(size: 8)).foregroundStyle(.white.opacity(0.7))
                    }

                    // Thumbnail Group 2
                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 68, height: 42)
                        Text("Mail").font(.system(size: 8)).foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()
                }
                .padding(.top, 40)
                .padding(.leading, 14)
                .frame(width: 90)
                .overlay(
                    // Annotation ③ for untouched sidebar
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                            .shadow(color: GuidePalette.redHighlight.opacity(0.3), radius: 4)
                        NumberBadge(number: "③")
                            .offset(x: -8, y: 16)
                    }
                )

                // 2. Center Active Stage (Both Windows Co-existing)
                HStack(spacing: 14) {
                    // Window A: Existing Active App (Code Editor)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Xcode — Existing Stage Window")
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Already Active in Current Stage")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GuidePalette.accent)
                            Text("Not ejected into side strip! Retains position seamlessly.")
                                .font(.system(size: 9))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Spacer()
                            HStack {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("Co-existence Active").font(.system(size: 9, weight: .bold)).foregroundStyle(.green)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                    }
                    .frame(width: 290, height: 280)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.4), radius: 10)
                    .overlay(
                        // Annotation ② for existing window retained
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                            NumberBadge(number: "②")
                                .offset(x: -12, y: -12)
                        }
                    )

                    // Window B: Newly Launched App (Terminal)
                    VStack(spacing: 0) {
                        WindowTitlebar(title: "Terminal — Newly Launched App")
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Just Opened from Spotlight / Finder")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Text("Automatically joins the active Stage without creating an isolated separate stage.")
                                .font(.system(size: 9))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Spacer()
                            Text("$ git status\nOn branch feat/always-on-top-window-pinning\nAll 423 tests passed.")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(4)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                    }
                    .frame(width: 290, height: 280)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.4), radius: 10)
                    .overlay(
                        // Annotation ① for newly launched window joined
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.5), radius: 7)
                            NumberBadge(number: "①")
                                .offset(x: -12, y: -12)
                        }
                    )
                }
                .padding(.trailing, 20)
            }
        }
        .frame(width: 780, height: 440)
    }
}

// MARK: - View 4: General Settings View

struct GeneralSettingsToggleGuideView: View {
    var body: some View {
        ZStack {
            Color(white: 0.90)

            VStack(spacing: 0) {
                // Settings Window Frame
                VStack(spacing: 0) {
                    // Window Titlebar
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(Color(red: 0.98, green: 0.37, blue: 0.34)).frame(width: 10, height: 10)
                            Circle().fill(Color(red: 0.98, green: 0.74, blue: 0.22)).frame(width: 10, height: 10)
                            Circle().fill(Color(red: 0.16, green: 0.77, blue: 0.28)).frame(width: 10, height: 10)
                        }
                        Spacer()
                        Text("FlowSnap Settings")
                            .font(.system(size: 12, weight: .bold))
                        Spacer()
                        Color.clear.frame(width: 42, height: 10)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(white: 0.95))

                    // Tab bar
                    HStack(spacing: 24) {
                        Label("General", systemImage: "gearshape")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GuidePalette.accent)
                        Label("Shortcuts", systemImage: "command")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Label("Rules", systemImage: "slider.horizontal.3")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Label("About", systemImage: "info.circle")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.92))

                    Divider()

                    // General Settings Content
                    VStack(alignment: .leading, spacing: 18) {
                        // Section: Window Gaps
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Window Margins & Gaps").font(.system(size: 12, weight: .bold))
                            HStack {
                                Text("Window Gap (Outer & Inner): 8 px").font(.system(size: 11))
                                Spacer()
                                Slider(value: .constant(8), in: 0...32).frame(width: 140)
                            }
                        }

                        Divider()

                        // Section: Stage Manager Co-existence (Highlighted ①)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stage Manager Integration").font(.system(size: 12, weight: .bold))

                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark.square.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(GuidePalette.accent)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Stage Manager: Keep existing stage windows when launching applications")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(GuidePalette.textPrimary)
                                    Text("When Stage Manager is active, newly opened apps join the current stage instead of pushing existing windows into the sidebar strip.")
                                        .font(.system(size: 10))
                                        .foregroundStyle(GuidePalette.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(white: 0.98))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(GuidePalette.redHighlight, lineWidth: 3)
                                    .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 6)
                            )
                            .overlay(
                                NumberBadge(number: "①")
                                    .offset(x: -12, y: -12),
                                alignment: .topLeading
                            )
                        }

                        Divider()

                        // Section: Shortcuts Reminder (Highlighted ②)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Pinning Shortcut").font(.system(size: 12, weight: .bold))
                            HStack {
                                Text("Toggle Pin Focused Window")
                                    .font(.system(size: 11))
                                Spacer()
                                Text("⌃ ⌥ P")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(white: 0.92))
                                    .cornerRadius(4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                                    )
                                    .overlay(
                                        NumberBadge(number: "②")
                                            .offset(x: -10, y: -10),
                                        alignment: .topLeading
                                    )
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                }
                .frame(width: 540)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
                .padding(20)
            }
        }
        .frame(width: 780, height: 460)
    }
}

// MARK: - Main Execution

@MainActor
func renderAndSaveAllScreenshots() {
    let outputDir = "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/always-on-top-window-pinning"
    try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Image 1: Floating Stack
    let view1 = AlwaysOnTopFloatingStackView()
    let renderer1 = ImageRenderer(content: view1)
    renderer1.scale = 2.0
    if let nsImage = renderer1.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/01_always_on_top_floating_stack.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 2: Menu Bar Controls
    let view2 = MenuBarPinnedControlsView()
    let renderer2 = ImageRenderer(content: view2)
    renderer2.scale = 2.0
    if let nsImage = renderer2.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/02_menubar_pinned_controls.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 3: Stage Manager Co-existence
    let view3 = StageManagerCoexistenceView()
    let renderer3 = ImageRenderer(content: view3)
    renderer3.scale = 2.0
    if let nsImage = renderer3.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/03_stage_manager_launch_coexistence.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 4: Settings Toggle
    let view4 = GeneralSettingsToggleGuideView()
    let renderer4 = ImageRenderer(content: view4)
    renderer4.scale = 2.0
    if let nsImage = renderer4.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/04_settings_launch_coexistence_toggle.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }
}

MainActor.assumeIsolated {
    renderAndSaveAllScreenshots()
}
