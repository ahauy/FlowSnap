import Foundation
import Testing
@testable import FlowSnap

/// Tests for the observable `PreferencesStore` (US-SNAP-008, ASM-CRW-003).
///
/// Covers: gap clamping (BR-CRW-002), default ratio persistence (BR-CRW-006),
/// and first-launch defaults.
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

    @Test func restoresPersistedValuesOnReinit() {
        let defaults = freshDefaults()
        let store = makeStore(defaults: defaults)
        store.setWindowGap(12)
        store.setDefaultRatio(.threeColumn25_50_25)

        // Re-instantiate to simulate app relaunch
        let reloaded = makeStore(defaults: defaults)
        #expect(reloaded.windowGap == 12)
        #expect(reloaded.defaultRatio == .threeColumn25_50_25)
    }
}
