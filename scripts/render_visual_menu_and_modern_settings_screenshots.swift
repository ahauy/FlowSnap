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
    static let purpleAccent = Color(red: 0.62, green: 0.35, blue: 0.95)
    static let darkCanvas = Color(red: 0.11, green: 0.12, blue: 0.15)
}

// MARK: - Annotation Badges

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
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// MARK: - View 1: Annotated Menu Bar Visual Snap Grid

struct AnnotatedVisualSnapGridMenuBarView: View {
    var body: some View {
        ZStack {
            GuidePalette.canvasBg

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(GuidePalette.accent)
                        Text("FlowSnap")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(GuidePalette.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Circle().fill(GuidePalette.success).frame(width: 7, height: 7)
                        Text("Ready")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(GuidePalette.success)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(GuidePalette.success.opacity(0.12))
                    .clipShape(Capsule())
                }

                Divider()

                // Section: Visual Snap Grid
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("QUICK SNAP")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Left Half")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(GuidePalette.accent)
                                Text("• ⌃⌥←")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                        }

                        // Halves Row
                        HStack(spacing: 8) {
                            // Left Half (Hover highlighted)
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(GuidePalette.accent.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(GuidePalette.accent, lineWidth: 1.5)
                                    )
                                HStack(spacing: 0) {
                                    Rectangle().fill(GuidePalette.accent).frame(width: 32)
                                    Spacer()
                                }
                                .padding(4)
                                Text("Left")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(GuidePalette.accent)
                            }
                            .frame(height: 38)

                            // Right Half
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                HStack(spacing: 0) {
                                    Spacer()
                                    Rectangle().fill(Color(white: 0.65)).frame(width: 32)
                                }
                                .padding(4)
                                Text("Right")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            .frame(height: 38)
                        }

                        // Top / Bottom Row
                        HStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                VStack(spacing: 0) {
                                    Rectangle().fill(Color(white: 0.65)).frame(height: 14)
                                    Spacer()
                                }
                                .padding(4)
                                Text("Top")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            .frame(height: 38)

                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                VStack(spacing: 0) {
                                    Spacer()
                                    Rectangle().fill(Color(white: 0.65)).frame(height: 14)
                                }
                                .padding(4)
                                Text("Bottom")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            .frame(height: 38)
                        }

                        // Quarters & Maximize Row
                        HStack(spacing: 8) {
                            // 4 Quarters mini-grid
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                VStack(spacing: 2) {
                                    HStack(spacing: 2) {
                                        Rectangle().fill(Color(white: 0.65)).frame(width: 16, height: 12)
                                        Rectangle().fill(Color(white: 0.78)).frame(width: 16, height: 12)
                                    }
                                    HStack(spacing: 2) {
                                        Rectangle().fill(Color(white: 0.78)).frame(width: 16, height: 12)
                                        Rectangle().fill(Color(white: 0.78)).frame(width: 16, height: 12)
                                    }
                                }
                            }
                            .frame(height: 38)

                            // Maximize / Restore
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                Rectangle().fill(Color(white: 0.65)).padding(6)
                                Text("Maximize")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Color.white)
                            }
                            .frame(height: 38)
                        }
                    }
                    .padding(8)
                    .background(GuidePalette.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )

                    NumberBadge(number: "1")
                        .offset(x: -8, y: -8)
                }

                // Presets Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRESETS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(GuidePalette.textSecondary)

                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "curlybraces")
                                .font(.system(size: 10))
                            Text("Coding (60/25/15)")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("⌃⌥C")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(white: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        HStack(spacing: 4) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 10))
                            Text("Research")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("⌃⌥R")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(white: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }

                // Workspaces Section
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("WORKSPACES")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Spacer()
                            Text("+ Save")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(GuidePalette.accent)
                        }

                        HStack {
                            Image(systemName: "display.2")
                                .font(.system(size: 10))
                                .foregroundStyle(GuidePalette.accent)
                            Text("Move Workspace to Next Display")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("⌃⌥⇧⌘→")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(GuidePalette.accent)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(GuidePalette.accent.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .padding(6)
                    .background(GuidePalette.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )

                    NumberBadge(number: "2")
                        .offset(x: -6, y: -6)
                }

                // Tools Section
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOOLS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(GuidePalette.textSecondary)

                        HStack {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text("Pin Focused Window")
                                .font(.system(size: 10))
                            Spacer()
                            Text("⌃⌥P")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }

                        HStack {
                            Image(systemName: "note.text")
                                .font(.system(size: 9))
                                .foregroundStyle(.blue)
                            Text("Quick Scratchpad")
                                .font(.system(size: 10))
                            Spacer()
                            Text("⌥Space")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }
                    }
                    .padding(6)
                    .background(GuidePalette.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )

                    NumberBadge(number: "3")
                        .offset(x: -6, y: -6)
                }

                Divider()

                // Footer
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10))
                        Text("Settings...")
                            .font(.system(size: 10))
                    }
                    Spacer()
                    Text("⌘,")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(GuidePalette.textSecondary)
                }
            }
            .padding(14)
            .frame(width: 320)
            .background(GuidePalette.canvasBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GuidePalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
        }
        .frame(width: 360, height: 560)
    }
}

// MARK: - View 2: Annotated Modern Settings View (Overview)

struct AnnotatedModernSettingsView: View {
    var body: some View {
        ZStack {
            GuidePalette.canvasBg

            HStack(spacing: 0) {
                // Sidebar
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.split.2x1")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(GuidePalette.accent)
                            Text("FlowSnap")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)

                        // Nav items
                        sidebarItem(icon: "gearshape.fill", title: "General", color: .blue, isSelected: true)
                        sidebarItem(icon: "macwindow.badge.plus", title: "Snap HUD", color: .purple, isSelected: false)
                        sidebarItem(icon: "keyboard.fill", title: "Shortcuts", color: .orange, isSelected: false)
                        sidebarItem(icon: "square.grid.2x2.fill", title: "Presets", color: .green, isSelected: false)
                        sidebarItem(icon: "link", title: "Window Groups", color: .indigo, isSelected: false)
                        sidebarItem(icon: "app.badge.fill", title: "App Rules", color: .teal, isSelected: false)
                        sidebarItem(icon: "display.2", title: "Workspaces", color: .cyan, isSelected: false)
                        sidebarItem(icon: "info.circle.fill", title: "About", color: .gray, isSelected: false)

                        Spacer()
                    }
                    .padding(8)
                    .frame(width: 170)
                    .background(Color(white: 0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )

                    NumberBadge(number: "1")
                        .offset(x: 4, y: 4)
                }

                Divider()

                // Detail Canvas: General Settings
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("General Settings")
                            .font(.system(size: 16, weight: .bold))

                        // Card 1: Window Gaps
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Window Gaps & Padding")
                                        .font(.system(size: 12, weight: .semibold))
                                    Spacer()
                                    Text("8 px")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(GuidePalette.accent)
                                }

                                // Gap Preview Diagram
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(white: 0.90))
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(GuidePalette.accent.opacity(0.35))
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(GuidePalette.accent, lineWidth: 1))
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(GuidePalette.accent.opacity(0.35))
                                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(GuidePalette.accent, lineWidth: 1))
                                    }
                                    .padding(8)
                                }
                                .frame(height: 54)
                            }
                            .padding(12)
                            .background(GuidePalette.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(GuidePalette.redHighlight, lineWidth: 2)
                            )

                            NumberBadge(number: "2")
                                .offset(x: -6, y: -6)
                        }

                        // Card 2: Split Ratio & Snapping
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Window Snapping & Stage Manager")
                                    .font(.system(size: 12, weight: .semibold))

                                HStack {
                                    Text("Default Split Ratio")
                                        .font(.system(size: 11))
                                    Spacer()
                                    HStack(spacing: 2) {
                                        Text("50/50").font(.system(size: 10, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 3).background(GuidePalette.accent).foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 4))
                                        Text("60/40").font(.system(size: 10)).padding(.horizontal, 6).padding(.vertical, 3)
                                        Text("70/30").font(.system(size: 10)).padding(.horizontal, 6).padding(.vertical, 3)
                                    }
                                    .background(Color(white: 0.92))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                }

                                Divider()

                                HStack {
                                    Text("Stage Manager Co-existence")
                                        .font(.system(size: 11))
                                    Spacer()
                                    Toggle("", isOn: .constant(true)).toggleStyle(.switch).controlSize(.small)
                                }

                                HStack {
                                    Text("Launch FlowSnap at login")
                                        .font(.system(size: 11))
                                    Spacer()
                                    Toggle("", isOn: .constant(true)).toggleStyle(.switch).controlSize(.small)
                                }
                            }
                            .padding(12)
                            .background(GuidePalette.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(GuidePalette.redHighlight, lineWidth: 2)
                            )

                            NumberBadge(number: "3")
                                .offset(x: -6, y: -6)
                        }
                    }
                    .padding(16)
                }
            }
            .frame(width: 580, height: 420)
            .background(GuidePalette.canvasBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GuidePalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 3)
        }
        .frame(width: 620, height: 460)
    }

    private func sidebarItem(icon: String, title: String, color: Color, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? Color.white : color)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : GuidePalette.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected ? GuidePalette.accent : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - View 3: Annotated Window Groups Settings View

struct AnnotatedWindowGroupsSettingsView: View {
    var body: some View {
        ZStack {
            GuidePalette.canvasBg

            HStack(spacing: 0) {
                // Sidebar with Window Groups selected
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(GuidePalette.accent)
                        Text("FlowSnap")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)

                    sidebarItem(icon: "gearshape.fill", title: "General", color: .blue, isSelected: false)
                    sidebarItem(icon: "macwindow.badge.plus", title: "Snap HUD", color: .purple, isSelected: false)
                    sidebarItem(icon: "keyboard.fill", title: "Shortcuts", color: .orange, isSelected: false)
                    sidebarItem(icon: "square.grid.2x2.fill", title: "Presets", color: .green, isSelected: false)
                    sidebarItem(icon: "link", title: "Window Groups", color: .indigo, isSelected: true)
                    sidebarItem(icon: "app.badge.fill", title: "App Rules", color: .teal, isSelected: false)
                    sidebarItem(icon: "display.2", title: "Workspaces", color: .cyan, isSelected: false)
                    sidebarItem(icon: "info.circle.fill", title: "About", color: .gray, isSelected: false)

                    Spacer()
                }
                .padding(8)
                .frame(width: 170)
                .background(Color(white: 0.96))

                Divider()

                // Detail Canvas: Window Groups
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Active Window Groups")
                                    .font(.system(size: 15, weight: .bold))
                                Text("Linked windows coordinate minimize, focus, and cross-display movement.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            Spacer()
                            Button {} label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("New Group")
                                }
                                .font(.system(size: 11, weight: .medium))
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }

                        // Group Card
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 10) {
                                // Card Header
                                HStack {
                                    HStack(spacing: 6) {
                                        Image(systemName: "link.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(GuidePalette.accent)
                                        Text("Dev Workspace")
                                            .font(.system(size: 12, weight: .bold))
                                        Text("3 windows")
                                            .font(.system(size: 9, weight: .medium))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(GuidePalette.accent.opacity(0.12))
                                            .foregroundStyle(GuidePalette.accent)
                                            .clipShape(Capsule())
                                    }

                                    Spacer()

                                    // Next Display Button with annotation
                                    ZStack(alignment: .topTrailing) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "display.and.arrow.down")
                                                .font(.system(size: 9))
                                            Text("Next Display")
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(GuidePalette.redHighlight, lineWidth: 2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 5))

                                        NumberBadge(number: "2")
                                            .offset(x: 8, y: -8)
                                    }

                                    Button {} label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(GuidePalette.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }

                                Divider()

                                // Member Windows List
                                VStack(spacing: 5) {
                                    memberRow(icon: "curlybraces", app: "Code", title: "WindowGroupManager.swift — FlowSnap", id: "2045")
                                    memberRow(icon: "globe", app: "Brave", title: "React Documentation — State Management", id: "1042")
                                    memberRow(icon: "terminal.fill", app: "Terminal", title: "zsh — 80×24", id: "3012")
                                }

                                Divider()

                                // Synchronization Options with annotation
                                ZStack(alignment: .topLeading) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Synchronization Behavior:")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(GuidePalette.textSecondary)

                                        HStack(spacing: 12) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                                Text("Minimize together").font(.system(size: 10))
                                            }
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                                Text("Focus together").font(.system(size: 10))
                                            }
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                                Text("Move together").font(.system(size: 10))
                                            }
                                        }

                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                            Text("Cross-display move").font(.system(size: 10, weight: .semibold))
                                            Text("• ⌃⌥⌘→").font(.system(size: 9, design: .monospaced)).foregroundStyle(GuidePalette.textSecondary)
                                        }
                                        .padding(.vertical, 2)
                                    }
                                    .padding(6)
                                    .background(GuidePalette.cardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                                    )

                                    NumberBadge(number: "3")
                                        .offset(x: -6, y: -6)
                                }
                            }
                            .padding(12)
                            .background(GuidePalette.cardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(GuidePalette.border, lineWidth: 1)
                            )

                            NumberBadge(number: "1")
                                .offset(x: -6, y: -6)
                        }
                    }
                    .padding(16)
                }
            }
            .frame(width: 600, height: 440)
            .background(GuidePalette.canvasBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GuidePalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 3)
        }
        .frame(width: 640, height: 480)
    }

    private func memberRow(icon: String, app: String, title: String, id: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(GuidePalette.accent)
                .frame(width: 14)

            Text(app)
                .font(.system(size: 10, weight: .bold))

            Text("—")
                .font(.system(size: 10))
                .foregroundStyle(GuidePalette.textSecondary)

            Text(title)
                .font(.system(size: 10))
                .lineLimit(1)

            Spacer()

            Text("ID: \(id)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(GuidePalette.textSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(white: 0.94))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(white: 0.97))
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func sidebarItem(icon: String, title: String, color: Color, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? Color.white : color)
                .frame(width: 16)
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : GuidePalette.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected ? GuidePalette.accent : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - View 4: Annotated Create Window Group Sheet View

struct AnnotatedCreateWindowGroupSheetView: View {
    var body: some View {
        ZStack {
            GuidePalette.canvasBg

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Create Window Group")
                            .font(.system(size: 14, weight: .bold))
                        Text("Select at least 2 windows to coordinate as a unified group.")
                            .font(.system(size: 10))
                            .foregroundStyle(GuidePalette.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(GuidePalette.textSecondary)
                }

                Divider()

                // Group Name
                VStack(alignment: .leading, spacing: 3) {
                    Text("Group Name")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(GuidePalette.textSecondary)
                    HStack {
                        Text("Dev Team • Antigravity + Brave Docs")
                            .font(.system(size: 11))
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(GuidePalette.border, lineWidth: 1)
                    )
                }

                // Window Selection List (Multi-instance differentiation)
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select Windows (Discovered on Screen)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(GuidePalette.textSecondary)

                        VStack(spacing: 5) {
                            // Brave Window 1 (Selected)
                            windowRow(isSelected: true, app: "Brave Browser", title: "React Documentation — Quick Start Guide", id: "1042")
                            // Brave Window 2 (Unselected)
                            windowRow(isSelected: false, app: "Brave Browser", title: "YouTube — WWDC 2026 Keynote Video", id: "1088")
                            // VS Code Window (Selected)
                            windowRow(isSelected: true, app: "VS Code", title: "FlowSnap — WindowGroupManager.swift", id: "2045")
                            // Terminal Window (Selected)
                            windowRow(isSelected: true, app: "Terminal", title: "zsh — 80×24 (Server Daemon)", id: "3012")
                        }
                    }
                    .padding(8)
                    .background(Color(white: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )

                    NumberBadge(number: "1")
                        .offset(x: -6, y: -6)
                }

                // Sync Options
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Synchronization Options:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(GuidePalette.textSecondary)

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                Text("Minimize together").font(.system(size: 10))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                Text("Focus together").font(.system(size: 10))
                            }
                        }

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                Text("Move together").font(.system(size: 10))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.square.fill").foregroundStyle(GuidePalette.accent)
                                Text("Cross-display move").font(.system(size: 10, weight: .bold))
                            }
                        }
                    }
                    .padding(8)
                    .background(Color(white: 0.98))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2)
                    )

                    NumberBadge(number: "2")
                        .offset(x: -6, y: -6)
                }

                // Buttons
                HStack {
                    Spacer()
                    Button("Cancel") {}
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Create Group (3 windows)") {}
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }
            .padding(16)
            .frame(width: 440)
            .background(GuidePalette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GuidePalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 3)
        }
        .frame(width: 480, height: 420)
    }

    private func windowRow(isSelected: Bool, app: String, title: String, id: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? GuidePalette.accent : GuidePalette.textSecondary)
                .font(.system(size: 11))

            Text(app)
                .font(.system(size: 10, weight: .bold))

            Text("—")
                .font(.system(size: 10))
                .foregroundStyle(GuidePalette.textSecondary)

            Text(title)
                .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? GuidePalette.textPrimary : GuidePalette.textSecondary)
                .lineLimit(1)

            Spacer()

            Text("ID: \(id)")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(GuidePalette.textSecondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Color(white: 0.92))
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? GuidePalette.accent.opacity(0.08) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - View 5: Annotated Cross-Display Dual-Mode Visualizer

struct AnnotatedCrossDisplayDualModeVisualizerView: View {
    var body: some View {
        ZStack {
            GuidePalette.canvasBg

            VStack(spacing: 14) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FlowSnap • Cross-Display Group Migration")
                            .font(.system(size: 14, weight: .bold))
                        Text("Dual-Mode Topology Scaling (Canonical Zones IoU ≥ 0.75 vs Proportional Bounds)")
                            .font(.system(size: 10))
                            .foregroundStyle(GuidePalette.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(GuidePalette.success).frame(width: 6, height: 6)
                        Text("Preserved 50/50 Tiling")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(GuidePalette.success)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(GuidePalette.success.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Dual Displays Comparison
                HStack(spacing: 18) {
                    // Display 1: MacBook Pro 16:10
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "laptopcomputer")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.blue)
                                Text("Display 1 (MacBook Pro 16:10)")
                                    .font(.system(size: 10, weight: .bold))
                                Spacer()
                                Text("1440 × 900")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }

                            // Screen Canvas with 50/50 Group
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                HStack(spacing: 4) {
                                    // Left Half
                                    VStack {
                                        Text("VS Code")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Left 50%")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.blue.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                    // Right Half
                                    VStack {
                                        Text("Brave")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Right 50%")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.indigo.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(6)
                            }
                            .frame(height: 120)

                            HStack(spacing: 4) {
                                Image(systemName: "link")
                                    .font(.system(size: 9))
                                    .foregroundStyle(GuidePalette.accent)
                                Text("Linked Window Group")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(GuidePalette.accent)
                            }
                        }
                        .padding(10)
                        .background(GuidePalette.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2)
                        )

                        NumberBadge(number: "1")
                            .offset(x: -6, y: -6)
                    }
                    .frame(width: 240)

                    // Transition Arrow with Shortcut
                    ZStack(alignment: .top) {
                        VStack(spacing: 4) {
                            Text("⌃⌥⌘→")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(GuidePalette.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(GuidePalette.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 5))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(GuidePalette.accent)

                            Text("Move Group")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }

                        NumberBadge(number: "2")
                            .offset(y: -14)
                    }

                    // Display 2: External 4K 16:9
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "display")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.purple)
                                Text("Display 2 (External 4K 16:9)")
                                    .font(.system(size: 10, weight: .bold))
                                Spacer()
                                Text("3840 × 2160")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }

                            // Screen Canvas with Perfectly Re-scaled 50/50 Group
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(white: 0.90))
                                HStack(spacing: 4) {
                                    // Left Half Re-anchored
                                    VStack {
                                        Text("VS Code")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Left 50% (Re-docked)")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.blue.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))

                                    // Right Half Re-anchored
                                    VStack {
                                        Text("Brave")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                        Text("Right 50% (Re-docked)")
                                            .font(.system(size: 8))
                                            .foregroundStyle(.white.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.indigo.opacity(0.7))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .padding(6)
                            }
                            .frame(height: 120)

                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(GuidePalette.success)
                                Text("Zero Pixel Drift • Auto-Recomputed")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(GuidePalette.success)
                            }
                        }
                        .padding(10)
                        .background(GuidePalette.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 2)
                        )

                        NumberBadge(number: "3")
                            .offset(x: -6, y: -6)
                    }
                    .frame(width: 240)
                }
            }
            .padding(16)
            .frame(width: 660, height: 260)
            .background(GuidePalette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(GuidePalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 3)
        }
        .frame(width: 700, height: 300)
    }
}

// MARK: - Runner / Main

@main
struct RenderVisualGuideScreenshots {
    @MainActor
    static func main() {
        let visualGuideDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/visual-menu-and-modern-settings")
        let windowGroupsDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/window-groups-presets")
        let menubarDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/menubar-quick-controls")

        for dir in [visualGuideDir, windowGroupsDir, menubarDir] {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        print("Rendering 1: Menu Bar Visual Snap Grid...")
        savePNG(view: AnnotatedVisualSnapGridMenuBarView(), to: visualGuideDir.appendingPathComponent("01_menubar_visual_snap_grid.png"))
        savePNG(view: AnnotatedVisualSnapGridMenuBarView(), to: menubarDir.appendingPathComponent("01_menubar_quick_snap_menu.png"))

        print("Rendering 2: Modern Settings Overview...")
        savePNG(view: AnnotatedModernSettingsView(), to: visualGuideDir.appendingPathComponent("02_modern_settings_overview.png"))

        print("Rendering 3: Window Groups Settings & Throw...")
        savePNG(view: AnnotatedWindowGroupsSettingsView(), to: visualGuideDir.appendingPathComponent("03_window_groups_selection_and_throw.png"))
        savePNG(view: AnnotatedWindowGroupsSettingsView(), to: windowGroupsDir.appendingPathComponent("01_window_groups_settings_and_throw.png"))

        print("Rendering 4: Create Window Group Multi-Instance...")
        savePNG(view: AnnotatedCreateWindowGroupSheetView(), to: visualGuideDir.appendingPathComponent("04_create_window_group_multi_instance.png"))
        savePNG(view: AnnotatedCreateWindowGroupSheetView(), to: windowGroupsDir.appendingPathComponent("02_create_window_group_multi_instance.png"))

        print("Rendering 5: Cross-Display Dual-Mode Scaling...")
        savePNG(view: AnnotatedCrossDisplayDualModeVisualizerView(), to: visualGuideDir.appendingPathComponent("05_cross_display_migration_dual_mode.png"))
        savePNG(view: AnnotatedCrossDisplayDualModeVisualizerView(), to: windowGroupsDir.appendingPathComponent("03_cross_display_migration_dual_mode.png"))

        print("All visual guide screenshots rendered successfully!")
    }

    @MainActor
    static func savePNG<V: View>(view: V, to url: URL) {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0 // Retina 2x
        guard let nsImage = renderer.nsImage else {
            print("Error: Could not render NSImage for \(url.lastPathComponent)")
            return
        }
        guard let tiffRepresentation = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Error: Could not convert to PNG data for \(url.lastPathComponent)")
            return
        }

        do {
            try pngData.write(to: url)
            print("✓ Saved: \(url.path)")
        } catch {
            print("✗ Error saving PNG: \(error)")
        }
    }
}
