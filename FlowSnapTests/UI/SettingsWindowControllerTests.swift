import AppKit
import Foundation
import Testing
@testable import FlowSnap

@MainActor
struct SettingsWindowControllerTests {

    @Test func initialWindowIsNil() {
        let store = PreferencesStore(defaults: UserDefaults(suiteName: "SettingsTest_\(UUID().uuidString)") ?? .standard)
        let controller = SettingsWindowController(preferencesStore: store)

        #expect(controller.window == nil)
    }

    @Test func showSettingsWindowCreatesAndPresentsWindow() {
        let store = PreferencesStore(defaults: UserDefaults(suiteName: "SettingsTest_\(UUID().uuidString)") ?? .standard)
        let controller = SettingsWindowController(preferencesStore: store)

        controller.showSettingsWindow()

        #expect(controller.window != nil)
        guard let window = controller.window else { return }

        #expect(window.title == "FlowSnap Settings")
        #expect(window.styleMask.contains(.titled))
        #expect(window.styleMask.contains(.closable))
        #expect(window.styleMask.contains(.miniaturizable))
        #expect(window.isReleasedWhenClosed == false)
        #expect(window.level == .floating)
        #expect(window.isVisible == true)

        // Close after test
        window.close()
    }

    @Test func multipleShowCallsReuseSameWindowInstance() {
        let store = PreferencesStore(defaults: UserDefaults(suiteName: "SettingsTest_\(UUID().uuidString)") ?? .standard)
        let controller = SettingsWindowController(preferencesStore: store)

        controller.showSettingsWindow()
        let firstWindow = controller.window

        controller.showSettingsWindow()
        let secondWindow = controller.window

        #expect(firstWindow != nil)
        #expect(firstWindow === secondWindow)

        firstWindow?.close()
    }

    @Test func showSettingsWindowWithSpecificTabPresentsSuccessfully() {
        let store = PreferencesStore(defaults: UserDefaults(suiteName: "SettingsTest_\(UUID().uuidString)") ?? .standard)
        let controller = SettingsWindowController(preferencesStore: store)

        controller.showSettingsWindow(tab: .workspaces)

        #expect(controller.window != nil)
        #expect(controller.window?.isVisible == true)

        controller.window?.close()
    }

    @Test func settingsTabMetadataMatchesExpectations() {
        let allTabs = SettingsTab.allCases
        #expect(allTabs.count == 7)
        #expect(allTabs.contains(.general))
        #expect(allTabs.contains(.shortcuts))
        #expect(allTabs.contains(.presets))
        #expect(allTabs.contains(.windowGroups))
        #expect(allTabs.contains(.appRules))
        #expect(allTabs.contains(.workspaces))
        #expect(allTabs.contains(.about))

        for tab in allTabs {
            #expect(!tab.iconName.isEmpty)
            #expect(!tab.id.isEmpty)
        }
    }
}

