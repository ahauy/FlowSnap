import Carbon
import Foundation
import Testing
@testable import FlowSnap

/// Tests for the observable `PreferencesStore` (US-SNAP-008, US-SNAP-010, ASM-CRW-003, ADR-0005).
///
/// Covers: gap clamping (BR-CRW-002), default ratio persistence (BR-CRW-006),
/// custom shortcuts (BR-SET-001..005), conflict detection, and first-launch defaults.
@MainActor
struct PreferencesStoreTests {

    private func makeStore(defaults: UserDefaults) -> PreferencesStore {
        PreferencesStore(defaults: defaults)
    }

    private func freshDefaults() -> UserDefaults {
        let suiteName = "test-prefs-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Failed to create UserDefaults suite")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func firstLaunchDefaults() {
        let store = makeStore(defaults: freshDefaults())

        #expect(store.windowGap == PreferencesStore.defaultGap)
        #expect(store.defaultRatio == .equal)
        #expect(store.isDragToSnapEnabled == true)
        #expect(store.dragPreviewDwellDelay == 0.05)
        #expect(store.launchAtLogin == false)
        #expect(store.customShortcuts.isEmpty)

        // Effective shortcut falls back to default
        let defaultLeft = store.shortcut(for: .leftHalf)
        #expect(defaultLeft?.displayString == "⌃⌥←")
    }

    @Test func clampGap_RoundsDownToAllowedSet() {
        #expect(PreferencesStore.clampGap(0) == 0)
        #expect(PreferencesStore.clampGap(3) == 0)
        #expect(PreferencesStore.clampGap(4) == 4)
        #expect(PreferencesStore.clampGap(6) == 4)
        #expect(PreferencesStore.clampGap(8) == 8)
        #expect(PreferencesStore.clampGap(10) == 8)
        #expect(PreferencesStore.clampGap(12) == 12)
        #expect(PreferencesStore.clampGap(15) == 12)
        #expect(PreferencesStore.clampGap(16) == 16)
        #expect(PreferencesStore.clampGap(999) == 16)
        #expect(PreferencesStore.clampGap(-5) == 0)
    }

    @Test func setWindowGap_PersistsClampedValue() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)

        store.setWindowGap(10) // clamps to 8
        #expect(store.windowGap == 8)
        #expect(defaults.double(forKey: "windowGap") == 8)
    }

    @Test func setDefaultRatio_Persists() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)

        store.setDefaultRatio(.eightyTwenty)
        #expect(store.defaultRatio == .eightyTwenty)
        #expect(defaults.string(forKey: "defaultRatio") == LayoutRatio.eightyTwenty.rawValue)
    }

    @Test func customShortcutsPersistenceAndRetrieval() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)

        let customLeft = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(cmdKey | optionKey)) // ⌥⌘←
        store.setShortcut(customLeft, for: .leftHalf)

        #expect(store.shortcut(for: .leftHalf) == customLeft)
        #expect(store.customShortcuts[.leftHalf] == customLeft)

        // Re-initialize to verify UserDefaults persistence
        let reloaded = makeStore(defaults: defaults)
        #expect(reloaded.shortcut(for: .leftHalf) == customLeft)
        #expect(reloaded.customShortcuts[.leftHalf] == customLeft)
    }

    @Test func shortcutConflictDetection() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)

        // ⌃⌥← is default for leftHalf
        let leftDefault = KeyboardShortcut(keyCode: 123, carbonModifiers: UInt32(controlKey | optionKey))

        // Check conflict when assigning same shortcut to rightHalf
        let conflict = store.hasConflict(leftDefault, excluding: .rightHalf)
        #expect(conflict == .leftHalf)

        // When checking for leftHalf itself, no conflict reported
        let selfConflict = store.hasConflict(leftDefault, excluding: .leftHalf)
        #expect(selfConflict == nil)
    }

    @Test func resetShortcutsToDefault() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)

        let customShortcut = KeyboardShortcut(keyCode: 35, carbonModifiers: UInt32(cmdKey | shiftKey))
        store.setShortcut(customShortcut, for: .maximize)
        #expect(store.shortcut(for: .maximize) == customShortcut)

        store.resetShortcutsToDefault()
        #expect(store.customShortcuts.isEmpty)
        #expect(store.shortcut(for: .maximize) == ShortcutAction.maximize.defaultShortcut)
    }

    @Test func dragToSnapAndLaunchPreferences() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)

        store.setDragToSnapEnabled(false)
        store.setDragPreviewDwellDelay(0.30)
        store.setLaunchAtLogin(true)

        #expect(store.isDragToSnapEnabled == false)
        #expect(store.dragPreviewDwellDelay == 0.30)
        #expect(store.launchAtLogin == true)

        let reloaded = makeStore(defaults: defaults)
        #expect(reloaded.isDragToSnapEnabled == false)
        #expect(reloaded.dragPreviewDwellDelay == 0.30)
        #expect(reloaded.launchAtLogin == true)
    }
}
