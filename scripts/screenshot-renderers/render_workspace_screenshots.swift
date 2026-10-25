import AppKit
import Foundation
import SwiftUI

// Renders annotated mockups of the US-WORK-011 workspace UI into
// docs/user-guides/images/workspace-snapshot-restoration/.
//
// These are faithful re-creations of WorkspaceSaveSheet, the Menu Bar
// "Workspaces" section, and the Settings "Workspaces" tab — same fonts,
// spacing, and colors as the real views — so the user guide can show the
// flows without a live Accessibility-authorized session.
//
// Run:  swift scripts/render_workspace_screenshots.swift

// MARK: - Palette
//
// Explicit light-mode values instead of `Color(nsColor:)`: a headless render
// process has no effective appearance, so semantic colors resolve to plain
// white and the mockups lose all contrast. Hard-coding the Aqua light values
// keeps the output deterministic and readable.

enum Palette {
    static let window = Color(white: 0.93)
    static let control = Color(white: 0.972)
    static let text = Color.white
    static let separator = Color(white: 0.84)
    static let label = Color(white: 0.12)
    static let secondary = Color(white: 0.45)
    static let accent = Color(red: 0.0, green: 0.48, blue: 1.0)
}

// MARK: - Shared mock data

/// Curated SF Symbols from `Workspace.curatedIcons`.
let kIcons = [
    "square.grid.2x2", "hammer", "briefcase", "gamecontroller",
    "camera", "music.note", "paintbrush", "chart.bar",
    "doc.text", "envelope", "map", "airplane"
]

struct MockWindow: Identifiable {
    let id: String
    let title: String
    let selected: Bool
    let added: Bool
}

let kPickerWindows: [MockWindow] = [
    MockWindow(id: "code", title: "WorkspaceManager.swift — FlowSnap", selected: true, added: false),
    MockWindow(id: "term", title: "Terminal — zsh", selected: true, added: false),
    MockWindow(id: "browser", title: "Safari — Apple Developer", selected: true, added: false),
    MockWindow(id: "notes", title: "Notes", selected: false, added: false)
]

struct MockWorkspace: Identifiable {
    let id: String
    let icon: String
    let name: String
    let apps: Int
}

let kWorkspaces: [MockWorkspace] = [
    MockWorkspace(id: "coding", icon: "hammer", name: "Coding", apps: 3),
    MockWorkspace(id: "research", icon: "doc.text", name: "Research", apps: 2),
    MockWorkspace(id: "meeting", icon: "briefcase", name: "Meeting", apps: 1)
]

// MARK: - View 1: Save Workspace sheet

struct SaveWorkspaceSheetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 15, weight: .semibold))
                Text("Save Workspace")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("NAME")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Palette.secondary)
                HStack {
                    Text("Coding")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.label)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 5).fill(Palette.text))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Palette.separator, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("ICON")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Palette.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                    ForEach(kIcons, id: \.self) { symbol in
                        let isSelected = symbol == "hammer"
                        Image(systemName: symbol)
                            .font(.system(size: 15))
                            .frame(maxWidth: .infinity, minHeight: 30)
                            .foregroundStyle(isSelected ? Color.white : Palette.label)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isSelected ? Palette.accent : Palette.control)
                            )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("WINDOWS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Palette.secondary)
                    Spacer()
                    Text("3 selected")
                        .font(.system(size: 9))
                        .foregroundStyle(Palette.secondary)
                }
                VStack(spacing: 2) {
                    ForEach(kPickerWindows) { window in
                        HStack(spacing: 8) {
                            Image(systemName: window.selected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(window.selected ? Palette.accent : Palette.secondary)
                                .font(.system(size: 13))
                            Text(window.title)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Palette.control.opacity(0.6))
                        )
                    }
                }
            }

            HStack {
                Spacer()
                Text("Cancel")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).stroke(Palette.separator, lineWidth: 1))
                HStack(spacing: 6) {
                    Text("Save Workspace")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(minWidth: 110)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Palette.accent))
            }
        }
        .padding(16)
        .frame(width: 380)
        .background(Palette.window)
    }
}

// MARK: - View 2: Menu Bar "Workspaces" section

struct MenuBarWorkspacesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                Text("FlowSnap")
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("WORKSPACES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Palette.secondary)
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.accent)
                }

                VStack(spacing: 4) {
                    ForEach(kWorkspaces) { workspace in
                        HStack(spacing: 8) {
                            Image(systemName: workspace.icon)
                                .font(.system(size: 13))
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(workspace.name)
                                    .font(.system(size: 11, weight: .medium))
                                Text("\(workspace.apps) apps")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Palette.secondary)
                            }
                            Spacer()
                            Text("Restore")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 5).fill(Palette.accent))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Palette.control.opacity(0.6))
                        )
                    }
                }

                // Partial restore summary banner.
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.system(size: 10))
                    Text("Restored 2/3 — Safari not running")
                        .font(.system(size: 10))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundStyle(Palette.secondary)
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.orange.opacity(0.08)))
            }
        }
        .padding(12)
        .frame(width: 280)
        .background(Palette.window)
    }
}

// MARK: - View 3: Settings "Workspaces" tab

struct SettingsWorkspacesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Workspaces")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                    Text("Save Current Layout").font(.system(size: 12))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Palette.accent))
            }

            Text("Save a set of window positions and restore them in one click. FlowSnap launches any app that isn't running.")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(spacing: 6) {
                ForEach(Array(kWorkspaces.enumerated()), id: \.element.id) { index, workspace in
                    row(workspace, renaming: index == 1)
                }
            }

            // Restore summary banner (full success).
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Restored 3/3")
                        .font(.system(size: 12, weight: .medium))
                }
                Spacer()
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(Palette.secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.green.opacity(0.08)))

            Spacer()
        }
        .padding(20)
        .frame(width: 560, height: 360, alignment: .topLeading)
        .background(Palette.window)
    }

    @ViewBuilder
    private func row(_ workspace: MockWorkspace, renaming: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: workspace.icon)
                .font(.system(size: 16))
                .frame(width: 22)

            if renaming {
                renameControls(name: workspace.name)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(workspace.name)
                        .font(.system(size: 13, weight: .medium))
                    Text("\(workspace.apps) apps")
                        .font(.system(size: 10))
                        .foregroundStyle(Palette.secondary)
                }
                Spacer()
                Text("Restore")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Palette.accent))
                Image(systemName: "pencil").font(.system(size: 12)).foregroundStyle(Palette.secondary)
                Image(systemName: "trash").font(.system(size: 12)).foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Palette.control)
        )
    }

    /// Inline rename field with Save / Cancel, mirroring `WorkspaceSettingsView`.
    private func renameControls(name: String) -> some View {
        HStack(spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 12))
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 5).fill(Palette.text))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Palette.accent, lineWidth: 2))
            .frame(maxWidth: 220)

            Text("Save")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).fill(Palette.accent))

            Text("Cancel")
                .font(.system(size: 11))
                .foregroundStyle(Palette.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 5).stroke(Palette.separator))
        }
    }
}

// MARK: - Renderer

@main
struct WorkspaceScreenshotGenerator {
    @MainActor
    static func main() {
        let repoRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()  // scripts/
            .deletingLastPathComponent()  // repo root
        let outDir = repoRoot
            .appendingPathComponent("docs/user-guides/images/workspace-snapshot-restoration")
        try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

        savePNG(view: SaveWorkspaceSheetView(), to: outDir.appendingPathComponent("01_save_workspace_sheet.png"))
        savePNG(view: MenuBarWorkspacesView(), to: outDir.appendingPathComponent("02_menubar_workspaces_section.png"))
        savePNG(view: SettingsWorkspacesView(), to: outDir.appendingPathComponent("03_settings_workspaces_tab.png"))
    }

    @MainActor
    static func savePNG<V: View>(view: V, to url: URL) {
        // Force light appearance: a headless process has no effective appearance,
        // so unstyled `Text` would otherwise resolve to white-on-white.
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
}
