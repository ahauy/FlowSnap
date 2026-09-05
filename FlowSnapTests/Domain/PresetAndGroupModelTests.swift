import CoreGraphics
import Foundation
import Testing
@testable import FlowSnap

@Suite("Preset & WindowGroup Domain Model Tests")
struct PresetAndGroupModelTests {

    @Test("PresetAppCategory has expected raw values and cases")
    func testPresetAppCategory() {
        #expect(PresetAppCategory.allCases.count == 7)
        #expect(PresetAppCategory.editor.rawValue == "Code & Text Editor")
        #expect(PresetAppCategory.browser.rawValue == "Web Browser")
        #expect(PresetAppCategory.terminal.rawValue == "Terminal & Shell")
        #expect(PresetAppCategory.notes.rawValue == "Notes & Knowledge")
        #expect(PresetAppCategory.writing.rawValue == "Writing & Documents")
        #expect(PresetAppCategory.design.rawValue == "Design & UI Tools")
        #expect(PresetAppCategory.custom.rawValue == "Custom Application")
    }

    @Test("PresetAppSlot id, equality, and Codable roundtrip")
    func testPresetAppSlot() throws {
        let slot = PresetAppSlot(
            category: .editor,
            roleDescription: "Primary Editor",
            preferredBundleIDs: ["com.microsoft.VSCode", "com.apple.dt.Xcode"],
            zone: .left60_40,
            ratio: .sixtyForty,
            normalizedRect: CGRect(x: 0, y: 0, width: 0.6, height: 1.0)
        )

        #expect(slot.id == "Primary Editor-left60_40")
        #expect(slot.category == .editor)
        #expect(slot.roleDescription == "Primary Editor")
        #expect(slot.preferredBundleIDs == ["com.microsoft.VSCode", "com.apple.dt.Xcode"])
        #expect(slot.zone == .left60_40)
        #expect(slot.ratio == .sixtyForty)
        #expect(slot.normalizedRect == CGRect(x: 0, y: 0, width: 0.6, height: 1.0))

        let encoder = JSONEncoder()
        let data = try encoder.encode(slot)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PresetAppSlot.self, from: data)

        #expect(decoded == slot)
        #expect(decoded.id == slot.id)
    }

    @Test("WorkspacePreset properties and Codable roundtrip")
    func testWorkspacePreset() throws {
        let slot = PresetAppSlot(
            category: .browser,
            roleDescription: "Browser",
            preferredBundleIDs: ["com.google.Chrome"],
            zone: .rightHalf
        )
        let preset = WorkspacePreset(
            id: "custom.test",
            name: "Test Preset",
            description: "A test preset",
            iconSymbolName: "star.fill",
            defaultShortcut: KeyboardShortcut(keyCode: 8, carbonModifiers: 6144),
            defaultRatio: .equal,
            slots: [slot],
            autoGroupWindows: true
        )

        #expect(preset.id == "custom.test")
        #expect(preset.name == "Test Preset")
        #expect(preset.description == "A test preset")
        #expect(preset.iconSymbolName == "star.fill")
        #expect(preset.slots.count == 1)
        #expect(preset.autoGroupWindows == true)

        let encoder = JSONEncoder()
        let data = try encoder.encode(preset)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkspacePreset.self, from: data)

        #expect(decoded == preset)
        #expect(decoded.id == preset.id)
    }

    @Test("BuiltinPresetFactory contains all 4 standard immutable presets")
    func testBuiltinPresetFactory() {
        #expect(BuiltinPresetFactory.allBuiltinPresets.count == 4)

        // 1. Coding preset
        let coding = BuiltinPresetFactory.codingPreset
        #expect(coding.id == "builtin.coding")
        #expect(coding.name == "Coding")
        #expect(coding.slots.count == 3)
        #expect(coding.autoGroupWindows == true)
        #expect(coding.defaultRatio == .seventyThirty)
        #expect(coding.defaultShortcut != nil)

        // 2. Research preset
        let research = BuiltinPresetFactory.researchPreset
        #expect(research.id == "builtin.research")
        #expect(research.name == "Research")
        #expect(research.slots.count == 3)
        #expect(research.autoGroupWindows == true)
        #expect(research.defaultRatio == .equal)

        // 3. Writing preset
        let writing = BuiltinPresetFactory.writingPreset
        #expect(writing.id == "builtin.writing")
        #expect(writing.name == "Writing")
        #expect(writing.slots.count == 2)
        #expect(writing.autoGroupWindows == true)
        #expect(writing.defaultRatio == .seventyThirty)

        // 4. Design preset
        let design = BuiltinPresetFactory.designPreset
        #expect(design.id == "builtin.design")
        #expect(design.name == "Design")
        #expect(design.slots.count == 2)
        #expect(design.autoGroupWindows == true)
        #expect(design.defaultRatio == .seventyThirty)

        // Lookup
        #expect(BuiltinPresetFactory.preset(for: "builtin.coding")?.id == "builtin.coding")
        #expect(BuiltinPresetFactory.preset(for: "builtin.research")?.id == "builtin.research")
        #expect(BuiltinPresetFactory.preset(for: "builtin.writing")?.id == "builtin.writing")
        #expect(BuiltinPresetFactory.preset(for: "builtin.design")?.id == "builtin.design")
        #expect(BuiltinPresetFactory.preset(for: "unknown.preset") == nil)
    }

    @Test("GroupSyncOptions OptionSet and Codable")
    func testGroupSyncOptions() throws {
        let all = GroupSyncOptions.all
        #expect(all.contains(.minimizeTogether))
        #expect(all.contains(.focusTogether))
        #expect(all.contains(.moveTogether))
        #expect(all.contains(.crossDisplayTogether))

        let custom: GroupSyncOptions = [.minimizeTogether, .crossDisplayTogether]
        #expect(custom.contains(.minimizeTogether))
        #expect(!custom.contains(.focusTogether))
        #expect(!custom.contains(.moveTogether))
        #expect(custom.contains(.crossDisplayTogether))

        let encoder = JSONEncoder()
        let data = try encoder.encode(custom)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GroupSyncOptions.self, from: data)
        #expect(decoded == custom)
    }

    @Test("WindowGroup cardinality, anchor, and isValid")
    func testWindowGroup() throws {
        let id = UUID()
        let singleGroup = WindowGroup(
            id: id,
            name: "Single",
            windowIDs: [100],
            syncOptions: .all
        )
        #expect(singleGroup.memberCount == 1)
        #expect(singleGroup.isValid == false)
        #expect(singleGroup.anchorWindowID == 100)

        let multiGroup = WindowGroup(
            id: id,
            name: "Pair",
            windowIDs: [100, 200],
            anchorWindowID: 200,
            syncOptions: .all
        )
        #expect(multiGroup.memberCount == 2)
        #expect(multiGroup.isValid == true)
        #expect(multiGroup.anchorWindowID == 200)

        let encoder = JSONEncoder()
        let data = try encoder.encode(multiGroup)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WindowGroup.self, from: data)
        #expect(decoded == multiGroup)
    }
}
