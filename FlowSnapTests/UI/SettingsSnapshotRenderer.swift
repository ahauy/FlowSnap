import AppKit
import Foundation
import SwiftUI
import Testing
@testable import FlowSnap

@MainActor
struct SettingsSnapshotRenderer {

    @Test func renderSettingsScreenshots() async throws {
        let outputDirs = [
            URL(fileURLWithPath: "docs/user-guides/images/settings-shortcut-customization"),
            URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/settings-shortcut-customization"),
            URL(fileURLWithPath: "docs/user-guides/images/custom-ratios-window-gaps"),
            URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/custom-ratios-window-gaps")
        ]

        for dir in outputDirs {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let defaults = UserDefaults(suiteName: "SettingsSnapshot_\(UUID().uuidString)") ?? .standard
        let store = PreferencesStore(defaults: defaults)
        store.setWindowGap(8)
        store.setDefaultRatio(.seventyThirty)

        // 1. Render GeneralSettingsView
        let generalView = GeneralSettingsView(store: store)
            .frame(width: 540, height: 380)
            .background(Color(nsColor: .windowBackgroundColor))

        if let data = renderViewToPNG(view: generalView, size: CGSize(width: 540, height: 380)) {
            for dir in outputDirs {
                try? data.write(to: dir.appendingPathComponent("01_general_settings_view.png"))
            }
        }

        // 2. Render ShortcutSettingsView
        let shortcutView = ShortcutSettingsView(store: store)
            .frame(width: 540, height: 440)
            .background(Color(nsColor: .windowBackgroundColor))

        if let data = renderViewToPNG(view: shortcutView, size: CGSize(width: 540, height: 440)) {
            for dir in outputDirs {
                try? data.write(to: dir.appendingPathComponent("02_shortcuts_tab.png"))
            }
        }

        // 3. Render ApplicationRulesView
        let rulesView = ApplicationRulesView()
            .frame(width: 540, height: 400)
            .background(Color(nsColor: .windowBackgroundColor))

        if let data = renderViewToPNG(view: rulesView, size: CGSize(width: 540, height: 400)) {
            for dir in outputDirs {
                try? data.write(to: dir.appendingPathComponent("03_application_rules_tab.png"))
            }
        }

        // 4. Render AboutSettingsView
        let aboutView = AboutSettingsView()
            .frame(width: 540, height: 400)
            .background(Color(nsColor: .windowBackgroundColor))

        if let data = renderViewToPNG(view: aboutView, size: CGSize(width: 540, height: 400)) {
            for dir in outputDirs {
                try? data.write(to: dir.appendingPathComponent("04_about_settings_tab.png"))
            }
        }

        // 5. Render Full SettingsView
        let fullSettingsView = SettingsView(store: store)
            .background(Color(nsColor: .windowBackgroundColor))

        if let data = renderViewToPNG(view: fullSettingsView, size: CGSize(width: 560, height: 460)) {
            for dir in outputDirs {
                try? data.write(to: dir.appendingPathComponent("05_full_settings_window.png"))
                try? data.write(to: dir.appendingPathComponent("02_settings_window_tabs.png"))
            }
        }
    }

    private func renderViewToPNG<V: View>(view: V, size: CGSize) -> Data? {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: size)
        hostingView.layoutSubtreeIfNeeded()

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        return bitmapRep.representation(using: .png, properties: [:])
    }
}
