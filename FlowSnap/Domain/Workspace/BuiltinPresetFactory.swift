import Carbon
import CoreGraphics
import Foundation

/// Factory providing immutable standard built-in workflow presets (spec §1.3).
public enum BuiltinPresetFactory {
    public static let codingPreset = WorkspacePreset(
        id: "builtin.coding",
        name: "Coding",
        description: "Editor (60%), Browser (25%), Terminal (15%)",
        iconSymbolName: "chevron.left.forwardslash.chevron.right",
        defaultShortcut: KeyboardShortcut(keyCode: 8, carbonModifiers: UInt32(controlKey | optionKey)),
        defaultRatio: .seventyThirty,
        slots: [
            PresetAppSlot(
                category: .editor,
                roleDescription: "Primary Code Editor",
                preferredBundleIDs: ["com.microsoft.VSCode", "com.apple.dt.Xcode", "com.panic.Nova", "com.apple.TextEdit"],
                zone: .left60_40,
                normalizedRect: CGRect(x: 0, y: 0, width: 0.60, height: 1.0)
            ),
            PresetAppSlot(
                category: .browser,
                roleDescription: "Documentation / Web",
                preferredBundleIDs: ["com.google.Chrome", "com.apple.Safari", "company.thebrowser.Browser", "com.brave.Browser"],
                zone: .topRight,
                normalizedRect: CGRect(x: 0.60, y: 0, width: 0.40, height: 0.60)
            ),
            PresetAppSlot(
                category: .terminal,
                roleDescription: "Terminal / Debug Console",
                preferredBundleIDs: ["com.apple.Terminal", "com.googlecode.iterm2", "com.mitchellh.ghostty", "io.alacritty"],
                zone: .bottomRight,
                normalizedRect: CGRect(x: 0.60, y: 0.60, width: 0.40, height: 0.40)
            )
        ],
        autoGroupWindows: true
    )

    public static let researchPreset = WorkspacePreset(
        id: "builtin.research",
        name: "Research",
        description: "Primary Browser (50%), Notes (25%), Reference Browser (25%)",
        iconSymbolName: "books.vertical.fill",
        defaultShortcut: KeyboardShortcut(keyCode: 15, carbonModifiers: UInt32(controlKey | optionKey)),
        defaultRatio: .equal,
        slots: [
            PresetAppSlot(
                category: .browser,
                roleDescription: "Primary Research Browser",
                preferredBundleIDs: ["com.google.Chrome", "com.apple.Safari", "company.thebrowser.Browser"],
                zone: .leftHalf,
                normalizedRect: CGRect(x: 0, y: 0, width: 0.50, height: 1.0)
            ),
            PresetAppSlot(
                category: .notes,
                roleDescription: "Notes & Knowledge Base",
                preferredBundleIDs: ["com.apple.Notes", "notion.id", "md.obsidian"],
                zone: .topRight,
                normalizedRect: CGRect(x: 0.50, y: 0, width: 0.50, height: 0.50)
            ),
            PresetAppSlot(
                category: .browser,
                roleDescription: "Reference & Sources",
                preferredBundleIDs: ["com.apple.Safari", "com.google.Chrome", "com.brave.Browser"],
                zone: .bottomRight,
                normalizedRect: CGRect(x: 0.50, y: 0.50, width: 0.50, height: 0.50)
            )
        ],
        autoGroupWindows: true
    )

    public static let writingPreset = WorkspacePreset(
        id: "builtin.writing",
        name: "Writing",
        description: "Document Editor (70%), Reference / Dictionary (30%)",
        iconSymbolName: "doc.text.fill",
        defaultShortcut: KeyboardShortcut(keyCode: 13, carbonModifiers: UInt32(controlKey | optionKey)),
        defaultRatio: .seventyThirty,
        slots: [
            PresetAppSlot(
                category: .writing,
                roleDescription: "Focused Document Editor",
                preferredBundleIDs: ["com.apple.Pages", "com.microsoft.Word", "md.obsidian", "com.apple.TextEdit"],
                zone: .left70_30,
                normalizedRect: CGRect(x: 0, y: 0, width: 0.70, height: 1.0)
            ),
            PresetAppSlot(
                category: .browser,
                roleDescription: "Reference & Research",
                preferredBundleIDs: ["com.apple.Safari", "com.google.Chrome", "company.thebrowser.Browser"],
                zone: .rightOneThird,
                normalizedRect: CGRect(x: 0.70, y: 0, width: 0.30, height: 1.0)
            )
        ],
        autoGroupWindows: true
    )

    public static let designPreset = WorkspacePreset(
        id: "builtin.design",
        name: "Design",
        description: "Design Canvas (70%), Assets & Preview (30%)",
        iconSymbolName: "paintbrush.fill",
        defaultShortcut: KeyboardShortcut(keyCode: 2, carbonModifiers: UInt32(controlKey | optionKey)),
        defaultRatio: .seventyThirty,
        slots: [
            PresetAppSlot(
                category: .design,
                roleDescription: "UI & Vector Design Tool",
                preferredBundleIDs: ["com.figma.Desktop", "com.bohemiancoding.sketch3", "com.adobe.illustrator"],
                zone: .left70_30,
                normalizedRect: CGRect(x: 0, y: 0, width: 0.70, height: 1.0)
            ),
            PresetAppSlot(
                category: .browser,
                roleDescription: "Assets & Prototype Preview",
                preferredBundleIDs: ["com.apple.Safari", "com.google.Chrome"],
                zone: .rightOneThird,
                normalizedRect: CGRect(x: 0.70, y: 0, width: 0.30, height: 1.0)
            )
        ],
        autoGroupWindows: true
    )

    public static let allBuiltinPresets: [WorkspacePreset] = [
        codingPreset,
        researchPreset,
        writingPreset,
        designPreset
    ]

    public static func preset(for id: String) -> WorkspacePreset? {
        allBuiltinPresets.first { $0.id == id }
    }
}
