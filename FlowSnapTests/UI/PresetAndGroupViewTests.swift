import SwiftUI
import Testing
@testable import FlowSnap

/// UI view tests for RestoreSummaryBanner, WindowGroupSettingsView, and PresetGalleryView.
///
/// Traces to: US-WORK-012 (Phase 6, T017, T026, T027, T028).
@MainActor
struct PresetAndGroupViewTests {

    @Test func restoreSummaryBannerFullSuccess() {
        let summary = RestoreSummary(placedCount: 3, totalPlacements: 3, skipped: [])
        var dismissed = false

        let banner = RestoreSummaryBanner(
            summary: summary,
            isCompact: false,
            onDismiss: { dismissed = true }
        )

        #expect(banner.summary.isFullSuccess == true)
        #expect(banner.isCompact == false)
        banner.onDismiss?()
        #expect(dismissed == true)
    }

    @Test func restoreSummaryBannerPartialWithSkippedApps() {
        let skipped = [
            SkippedApp(bundleIdentifier: "com.microsoft.VSCode", reason: .notInstalled),
            SkippedApp(bundleIdentifier: "com.apple.Safari", reason: .launchTimeout)
        ]
        let summary = RestoreSummary(placedCount: 1, totalPlacements: 3, skipped: skipped)

        let banner = RestoreSummaryBanner(summary: summary, isCompact: true)
        #expect(banner.summary.isFullSuccess == false)
        #expect(banner.summary.skipped.count == 2)
        #expect(banner.isCompact == true)
    }

    @Test func windowGroupSettingsViewSyncOptionsMutation() {
        let accessibilityService = MockAccessibilityService(isTrusted: true)
        let windowManager = MockWindowManaging()
        let manager = WindowGroupManager(
            accessibilityService: accessibilityService,
            windowManager: windowManager
        )

        let group = manager.createGroup(
            name: "Test Group",
            windowIDs: [101, 102],
            syncOptions: .all
        )
        guard let group = group else {
            Issue.record("Failed to create group")
            return
        }

        #expect(manager.activeGroups.count == 1)
        #expect(group.syncOptions == .all)

        let view = WindowGroupSettingsView(manager: manager)
        #expect(view.manager.activeGroups.count == 1)

        // Mutate sync options
        manager.updateSyncOptions([.focusTogether], for: group.id)
        #expect(manager.activeGroups.first?.syncOptions == [.focusTogether])

        // Dissolve group
        manager.dissolveGroup(id: group.id)
        #expect(manager.activeGroups.isEmpty)
    }

    @Test func presetGalleryViewInitialization() {
        let defaults = UserDefaults(suiteName: "test-gallery-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)

        let view = PresetGalleryView(store: store)
        #expect(view.store === store)
    }

    @Test func settingsViewWithAllTabsConfigured() {
        let defaults = UserDefaults(suiteName: "test-settings-\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        let accessibilityService = MockAccessibilityService(isTrusted: true)
        let windowManager = MockWindowManaging()
        let displayManager = DisplayManager(displayProvider: { [] })
        let groupManager = WindowGroupManager(
            accessibilityService: accessibilityService,
            windowManager: windowManager
        )
        let workspaceManager = WorkspaceManager(
            accessibilityService: accessibilityService,
            windowManager: windowManager,
            displayManager: displayManager,
            layoutEngine: LayoutEngine()
        )

        let settingsView = SettingsView(
            store: store,
            workspaceManager: workspaceManager,
            windowGroupManager: groupManager
        )

        #expect(settingsView.store === store)
    }
}
