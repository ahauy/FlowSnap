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
    var highlightGreenButton: Bool = false
    var badgeNumber: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            // Traffic lights
            HStack(spacing: 6) {
                Circle().fill(Color(red: 0.98, green: 0.37, blue: 0.34)).frame(width: 11, height: 11)
                Circle().fill(Color(red: 0.98, green: 0.74, blue: 0.22)).frame(width: 11, height: 11)

                ZStack(alignment: .topLeading) {
                    Circle()
                        .fill(Color(red: 0.16, green: 0.77, blue: 0.28))
                        .frame(width: 11, height: 11)

                    if highlightGreenButton {
                        Circle()
                            .stroke(GuidePalette.redHighlight, lineWidth: 3)
                            .frame(width: 19, height: 19)
                            .offset(x: -4, y: -4)
                            .shadow(color: GuidePalette.redHighlight.opacity(0.4), radius: 4)

                        if let badge = badgeNumber {
                            NumberBadge(number: badge)
                                .offset(x: -16, y: -20)
                        }
                    }
                }
            }

            Spacer()

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(GuidePalette.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.96))
    }
}

// MARK: - View 1: Detection & 3-Tier Strategy Selection

struct FullscreenDetectionView: View {
    var body: some View {
        VStack(spacing: 0) {
            // macOS Spaces Top Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow")
                        .font(.system(size: 12))
                        .foregroundStyle(GuidePalette.textSecondary)
                    Text("Desktop 1 (Normal Space)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(GuidePalette.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(white: 0.90))
                .cornerRadius(6)

                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                    Text("Space 2: VS Code (Native Full Screen Space)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(GuidePalette.accent)
                .cornerRadius(6)

                Spacer()

                HStack(spacing: 6) {
                    Circle().fill(GuidePalette.warning).frame(width: 8, height: 8)
                    Text("Isolated Fullscreen Space")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(GuidePalette.warning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(white: 0.92))

            // Main Canvas
            VStack(spacing: 16) {
                // Fullscreen Application Mock
                VStack(spacing: 0) {
                    WindowTitlebar(
                        title: "Visual Studio Code — Universal Fullscreen Space",
                        highlightGreenButton: true,
                        badgeNumber: "①"
                    )

                    // Code Editor Mock Body
                    HStack(spacing: 0) {
                        // Sidebar
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EXPLORER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color(white: 0.5))
                            Text("📁 FlowSnap")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.white)
                            Text("   📄 WindowManager.swift")
                                .font(.system(size: 10))
                                .foregroundStyle(GuidePalette.accent)
                            Spacer()
                        }
                        .padding(10)
                        .frame(width: 140)
                        .background(Color(red: 0.14, green: 0.15, blue: 0.18))

                        // Editor code area
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("WindowManager.swift")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.white)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.18, green: 0.19, blue: 0.22))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("func move(_ window: ManagedWindow, to frame: CGRect) async {")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                                Text("    if window.isFullScreen {")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                                Text("        await fullScreenEscapeCoordinator.exitFullScreen(window)")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                                Text("    }")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color(red: 0.9, green: 0.8, blue: 0.5))
                            }
                            .padding(12)

                            Spacer()
                        }
                        .background(GuidePalette.codeBg)
                    }
                    .frame(height: 180)
                }
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GuidePalette.border, lineWidth: 1))
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)

                // 3-Tier Detection Engine Card (FlowSnap Overlay)
                ZStack(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.system(size: 14))
                                .foregroundStyle(GuidePalette.accent)
                            Text("FlowSnap 3-Tier Fullscreen Escape Coordinator")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle().fill(GuidePalette.success).frame(width: 8, height: 8)
                                Text("AUTO-DETECTED")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(GuidePalette.success)
                            }
                        }

                        Divider()

                        HStack(spacing: 12) {
                            // Tier 0 Block (Skipped/Failed)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Tier 0: Attribute Write")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(GuidePalette.textSecondary)
                                    Spacer()
                                    Text("FAILED")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.red)
                                }
                                Text("AXFullscreen = false rejected with cannotComplete by Electron framework.")
                                    .font(.system(size: 9))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.96))
                            .cornerRadius(6)

                            // Tier 1 Block (Active & Selected)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Tier 1: AX Button Press")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(GuidePalette.success)
                                    Spacer()
                                    Text("ACTIVE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(GuidePalette.success)
                                }
                                Text("Locates kAXFullScreenButtonAttribute and performs kAXPressAction.")
                                    .font(.system(size: 9))
                                    .foregroundStyle(GuidePalette.textPrimary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 0.93, green: 0.98, blue: 0.94))
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(GuidePalette.success, lineWidth: 1.5))

                            // Tier 2 Block (Standby)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Tier 2: CGEvent ⌃⌘F")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(GuidePalette.textSecondary)
                                    Spacer()
                                    Text("STANDBY")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(GuidePalette.textSecondary)
                                }
                                Text("Process activation + synthesized shortcut if button press fails.")
                                    .font(.system(size: 9))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.96))
                            .cornerRadius(6)
                        }
                    }
                    .padding(14)
                    .background(GuidePalette.cardBg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                            .shadow(color: GuidePalette.redHighlight.opacity(0.35), radius: 6)
                    )

                    NumberBadge(number: "②")
                        .offset(x: -10, y: -10)
                }

                // App Target Info Pill
                ZStack(alignment: .topLeading) {
                    HStack {
                        Image(systemName: "app.connected.to.app.below.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(GuidePalette.accent)
                        Text("Target: Visual Studio Code")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GuidePalette.textPrimary)
                        Text("• PID: 8412 • Bundle: com.microsoft.VSCode • Current State: .fullscreen")
                            .font(.system(size: 10))
                            .foregroundStyle(GuidePalette.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                    )

                    NumberBadge(number: "③")
                        .offset(x: -8, y: -8)
                }
            }
            .padding(18)
        }
        .frame(width: 760, height: 470)
        .background(GuidePalette.canvasBg)
    }
}

// MARK: - View 2: Adaptive Space Transition & Polling Loop

struct AdaptiveTransitionView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 13))
                        .foregroundStyle(GuidePalette.accent)
                    Text("FlowSnap • Adaptive Space Transition & State Polling")
                        .font(.system(size: 14, weight: .bold))
                    Text("(US-WORK-018)")
                        .font(.system(size: 12))
                        .foregroundStyle(GuidePalette.textSecondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(GuidePalette.success).frame(width: 8, height: 8)
                    Text("GLIDING TO DESKTOP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(GuidePalette.success)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color(white: 0.92))

            // Canvas Body
            VStack(spacing: 16) {
                // Motion Glide Graphic
                HStack(spacing: 20) {
                    // Fullscreen Space Exiting
                    VStack(spacing: 8) {
                        HStack {
                            Text("Full Screen Space (Exiting)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(GuidePalette.accent)
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(white: 0.88))
                                .frame(height: 160)

                            VStack(spacing: 4) {
                                Image(systemName: "app.dashed")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(white: 0.6))
                                Text("Space Dissolving...")
                                    .font(.system(size: 11))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Transition Arrow & Polling Indicator
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .foregroundStyle(GuidePalette.accent)
                                Text("Adaptive Poller")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(GuidePalette.accent)
                            }

                            VStack(spacing: 2) {
                                Text("100ms Ticker")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                Text("Ceiling: 800ms")
                                    .font(.system(size: 9))
                                    .foregroundStyle(GuidePalette.textSecondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(white: 0.94))
                            .cornerRadius(4)

                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(GuidePalette.success)
                                Text("Exit at 200ms")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(GuidePalette.success)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.93, green: 0.98, blue: 0.94))
                            .cornerRadius(4)

                            Text("⚡ Saved 500ms vs legacy static sleep")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(GuidePalette.success)
                                .multilineTextAlignment(.center)
                        }
                        .padding(12)
                        .frame(width: 170)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.35), radius: 6)
                        )

                        NumberBadge(number: "①")
                            .offset(x: -8, y: -8)
                    }

                    // Desktop Space Waiting
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "display")
                                .foregroundStyle(GuidePalette.accent)
                            Text("Desktop 1 (Destination)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Spacer()
                        }

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GuidePalette.border, lineWidth: 1))
                                .frame(height: 160)

                            // Target Snap Slot Highlight
                            VStack {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Target Snap Slot")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(GuidePalette.accent)
                                        Text("Left 70% • Awaiting Frame Set")
                                            .font(.system(size: 9))
                                            .foregroundStyle(GuidePalette.textSecondary)
                                    }
                                    Spacer()
                                }
                                .padding(8)

                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(red: 0.92, green: 0.96, blue: 1.0))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                            )
                            .padding(8)

                            NumberBadge(number: "②")
                                .offset(x: 2, y: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Comparative Benchmarking Table
                VStack(spacing: 6) {
                    HStack {
                        Text("Performance & Reliability Comparison")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(GuidePalette.textPrimary)
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        HStack {
                            Text("Traditional Approach:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Text("Fixed 700ms sleep or hangs on Electron")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(red: 0.8, green: 0.2, blue: 0.2))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.96))
                        .cornerRadius(6)

                        HStack {
                            Text("FlowSnap Universal Escape:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(GuidePalette.textSecondary)
                            Text("Instant 3-tier cascade + 100ms adaptive check")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(GuidePalette.success)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.93, green: 0.98, blue: 0.94))
                        .cornerRadius(6)
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(GuidePalette.border, lineWidth: 1))
            }
            .padding(18)
        }
        .frame(width: 760, height: 430)
        .background(GuidePalette.canvasBg)
    }
}

// MARK: - View 3: Completed Multi-Window Workspace Restoration

struct WorkspaceRestorationView: View {
    var body: some View {
        VStack(spacing: 0) {
            // macOS Menu Bar
            HStack(spacing: 14) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 12))
                Text("FlowSnap")
                    .font(.system(size: 12, weight: .bold))
                Text("File")
                    .font(.system(size: 12))
                Text("Edit")
                    .font(.system(size: 12))
                Text("Window")
                    .font(.system(size: 12))
                Spacer()

                HStack(spacing: 8) {
                    Image(systemName: "flowchart.fill")
                        .foregroundStyle(GuidePalette.accent)
                    Text("Workspace: 'Dev & Review'")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.8))
                .cornerRadius(4)

                Text("9:41 AM")
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color(white: 0.90))

            // Main Screen with 2 Placed Windows
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Left Window: VS Code (Escaped from Fullscreen & Positioned at 70%)
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            WindowTitlebar(title: "VS Code — WindowManager.swift")

                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("// Escaped Fullscreen safely")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color.gray)
                                    Text("let result = coordinator.exitFullScreen(window)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color(red: 0.3, green: 0.8, blue: 0.5))
                                    Text("setFrame(rect: targetFrame)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                                    Spacer()
                                }
                                .padding(12)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(GuidePalette.codeBg)
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.35), radius: 6)
                        )

                        NumberBadge(number: "①")
                            .offset(x: -8, y: -8)
                    }
                    .frame(maxWidth: .infinity)

                    // Right Window: Browser / Slack (Right 30%)
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            WindowTitlebar(title: "Safari — FlowSnap Documentation")

                            VStack(alignment: .leading, spacing: 6) {
                                Text("PR #21: Universal Fullscreen Escape")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(GuidePalette.textPrimary)
                                Text("All 392 tests passing. Adaptive polling verified.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(GuidePalette.textSecondary)

                                Spacer()

                                HStack {
                                    Circle().fill(GuidePalette.success).frame(width: 8, height: 8)
                                    Text("Layout Ratio: 70% / 30%")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(GuidePalette.success)
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.98))
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(GuidePalette.redHighlight, lineWidth: 3.5)
                                .shadow(color: GuidePalette.redHighlight.opacity(0.35), radius: 6)
                        )

                        NumberBadge(number: "②")
                            .offset(x: -8, y: -8)
                    }
                    .frame(width: 220)
                }
                .frame(height: 250)

                // Notification Toast / Indicator Pill
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(GuidePalette.success)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Workspace 'Dev & Review' Restored Seamlessly")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(GuidePalette.textPrimary)
                            Text("VS Code safely escaped Full Screen via Tier 1 in 240ms • 0 UI Glitch • Positioned at Left 70%")
                                .font(.system(size: 10))
                                .foregroundStyle(GuidePalette.textSecondary)
                        }

                        Spacer()

                        Text("Instant Restore")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(GuidePalette.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.92, green: 0.96, blue: 1.0))
                            .cornerRadius(4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(GuidePalette.redHighlight, lineWidth: 2.5)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                    NumberBadge(number: "③")
                        .offset(x: -6, y: -6)
                }
            }
            .padding(18)
        }
        .frame(width: 760, height: 430)
        .background(GuidePalette.canvasBg)
    }
}

// MARK: - Renderer Execution

@MainActor
func renderAndSaveGuideImages() {
    let outputDir = "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/universal-fullscreen-escape"
    try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    // Image 1: Detection & Strategy
    let view1 = FullscreenDetectionView()
    let renderer1 = ImageRenderer(content: view1)
    renderer1.scale = 2.0
    if let nsImage = renderer1.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/01_fullscreen_window_detection.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 2: Adaptive Transition
    let view2 = AdaptiveTransitionView()
    let renderer2 = ImageRenderer(content: view2)
    renderer2.scale = 2.0
    if let nsImage = renderer2.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/02_adaptive_space_transition.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }

    // Image 3: Workspace Restoration
    let view3 = WorkspaceRestorationView()
    let renderer3 = ImageRenderer(content: view3)
    renderer3.scale = 2.0
    if let nsImage = renderer3.nsImage,
       let tiff = nsImage.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/03_workspace_restoration_seamless.png"
        try? png.write(to: URL(fileURLWithPath: path))
        print("Rendered: \(path)")
    }
}

MainActor.assumeIsolated {
    renderAndSaveGuideImages()
}
