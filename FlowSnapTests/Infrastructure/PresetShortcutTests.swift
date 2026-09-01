import Carbon
import Foundation
import Testing
@testable import FlowSnap

/// Tests for preset shortcut persistence, collision checking, and GlobalHotkeyManager registration.
///
/// Traces to: US-WORK-012 (Phase 6, T023, spec §2 US4, FR-PRESET-005, FR-PRESET-006).
@MainActor
struct PresetShortcutTests {

    private func freshDefaults() -> UserDefaults {
        let suiteName = "test-preset-shortcuts-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Failed to create UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func defaultPresetShortcutsResolved() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        for preset in BuiltinPresetFactory.allBuiltinPresets {
            let shortcut = store.shortcut(forPresetID: preset.id)
            #expect(shortcut == preset.defaultShortcut)
        }
    }

    @Test func customPresetShortcutPersistenceAndReload() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        let customShortcut = KeyboardShortcut(keyCode: 15, carbonModifiers: UInt32(cmdKey | shiftKey)) // ⇧⌘R
        store.setShortcut(customShortcut, forPresetID: "builtin.research")

        #expect(store.shortcut(forPresetID: "builtin.research") == customShortcut)
        #expect(store.customPresetShortcuts["builtin.research"] == customShortcut)

        // Reload from same UserDefaults
        let reloaded = PreferencesStore(defaults: defaults)
        #expect(reloaded.shortcut(forPresetID: "builtin.research") == customShortcut)
        #expect(reloaded.customPresetShortcuts["builtin.research"] == customShortcut)
    }

    @Test func presetShortcutConflictWithStandardSnapAction() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        // ⌃⌥← is the default shortcut for leftHalf
        let leftHalfShortcut = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey))

        let conflict = store.hasPresetConflict(leftHalfShortcut, excludingPresetID: "builtin.coding")
        #expect(conflict != nil)
        #expect(conflict?.contains("Left Half") == true)
    }

    @Test func presetShortcutConflictWithOtherPreset() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        // ⌃⌥C is default for codingPreset
        guard let codingShortcut = BuiltinPresetFactory.codingPreset.defaultShortcut else {
            Issue.record("Expected default shortcut for coding preset")
            return
        }

        // Checking conflict against research preset
        let conflict = store.hasPresetConflict(codingShortcut, excludingPresetID: "builtin.research")
        #expect(conflict != nil)
        #expect(conflict?.contains("Coding preset") == true)

        // Excluding coding preset itself should not conflict
        let selfConflict = store.hasPresetConflict(codingShortcut, excludingPresetID: "builtin.coding")
        #expect(selfConflict == nil)
    }

    @Test func resetPresetShortcutsToDefault() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)

        let customShortcut = KeyboardShortcut(keyCode: 13, carbonModifiers: UInt32(cmdKey | controlKey))
        store.setShortcut(customShortcut, forPresetID: "builtin.writing")
        #expect(store.shortcut(forPresetID: "builtin.writing") == customShortcut)

        store.resetPresetShortcutsToDefault()
        #expect(store.customPresetShortcuts.isEmpty)
        #expect(store.shortcut(forPresetID: "builtin.writing") == BuiltinPresetFactory.writingPreset.defaultShortcut)
    }

    @Test func globalHotkeyManagerRegistersPresetBindings() {
        let defaults = freshDefaults()
        let store = PreferencesStore(defaults: defaults)
        let manager = GlobalHotkeyManager()

        let bindings = manager.registerShortcuts(from: store) { _ in }

        // Verify that preset commands are registered
        let presetBindings = bindings.filter { binding in
            if case .restorePreset = binding.command {
                return true
            }
            return false
        }

        #expect(presetBindings.count == BuiltinPresetFactory.allBuiltinPresets.count)

        for preset in BuiltinPresetFactory.allBuiltinPresets {
            let hasBinding = presetBindings.contains { $0.command == .restorePreset(preset.id) }
            #expect(hasBinding)
        }
    }
}
