import AppKit
import Foundation
import SwiftUI
import Testing
@testable import FlowSnap

@MainActor
struct SettingsSnapshotRenderer {

    @Test func renderSettingsScreenshots() async throws {
        let outputDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/custom-ratios-window-gaps")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        // 1. Render GeneralSettingsView with 8px Gap and 70/30 Ratio
        let suiteName1 = "SettingsSnapshot_General_\(UUID().uuidString)"
        let defaults1 = UserDefaults(suiteName: suiteName1) ?? .standard
        let store1 = PreferencesStore(defaults: defaults1)
        store1.setWindowGap(8)
        store1.setDefaultRatio(.seventyThirty)

        let generalSettingsView = GeneralSettingsView(store: store1)
            .frame(width: 480, height: 280)
            .background(Color(nsColor: .windowBackgroundColor))

        if let generalData = renderViewToPNG(view: generalSettingsView, size: CGSize(width: 480, height: 280)) {
            let url = outputDir.appendingPathComponent("01_general_settings_view.png")
            try generalData.write(to: url)
        }

        // 2. Render Full SettingsView with Tab Navigation (General tab selected)
        let suiteName2 = "SettingsSnapshot_Tabs_\(UUID().uuidString)"
        let defaults2 = UserDefaults(suiteName: suiteName2) ?? .standard
        let store2 = PreferencesStore(defaults: defaults2)
        store2.setWindowGap(4)
        store2.setDefaultRatio(.equal)

        let fullSettingsView = SettingsView(store: store2)
            .background(Color(nsColor: .windowBackgroundColor))

        if let fullData = renderViewToPNG(view: fullSettingsView, size: CGSize(width: 500, height: 400)) {
            let url = outputDir.appendingPathComponent("02_settings_window_tabs.png")
            try fullData.write(to: url)
        }

        // 3. Render GeneralSettingsView with 16px Tiling Gap Preset
        let suiteName3 = "SettingsSnapshot_16px_\(UUID().uuidString)"
        let defaults3 = UserDefaults(suiteName: suiteName3) ?? .standard
        let store3 = PreferencesStore(defaults: defaults3)
        store3.setWindowGap(16)
        store3.setDefaultRatio(.threeColumn25_50_25)

        let tilingSettingsView = GeneralSettingsView(store: store3)
            .frame(width: 480, height: 280)
            .background(Color(nsColor: .windowBackgroundColor))

        if let tilingData = renderViewToPNG(view: tilingSettingsView, size: CGSize(width: 480, height: 280)) {
            let url = outputDir.appendingPathComponent("03_general_settings_16px_tiling.png")
            try tilingData.write(to: url)
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
