import AppKit
import Foundation
import SwiftUI
import Testing
@testable import FlowSnap

@MainActor
struct SnapLayoutPickerSnapshotRenderer {

    @Test func renderLayoutPickerScreenshots() async throws {
        let outputDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/top-edge-layout-picker")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        // 1. Render Top-Edge Picker Normal Flyout
        let pickerNormalView = ZStack(alignment: .top) {
            Color.black.opacity(0.85) // Desktop canvas background mockup
            VStack {
                SnapLayoutPickerView(
                    templates: LayoutTemplate.standardTemplates,
                    hoveredSlotId: nil
                )
                Spacer()
            }
            .padding(.top, 12)
        }
        .frame(width: 540, height: 200)

        if let normalData = renderViewToPNG(view: pickerNormalView, size: CGSize(width: 540, height: 200)) {
            let url = outputDir.appendingPathComponent("01_layout_picker_flyout.png")
            try normalData.write(to: url)
        }

        // 2. Render Slot Hover Highlight (70/30 Left slot hovered)
        let pickerHoveredView = ZStack(alignment: .top) {
            Color.black.opacity(0.85)
            VStack {
                SnapLayoutPickerView(
                    templates: LayoutTemplate.standardTemplates,
                    hoveredSlotId: "twoColAsym-left"
                )
                Spacer()
            }
            .padding(.top, 12)
        }
        .frame(width: 540, height: 200)

        if let hoverData = renderViewToPNG(view: pickerHoveredView, size: CGSize(width: 540, height: 200)) {
            let url = outputDir.appendingPathComponent("02_layout_picker_slot_hover.png")
            try hoverData.write(to: url)
        }

        // 3. Render 3-Column Slot Hover (Center 1/3 slot hovered)
        let pickerThreeColHoveredView = ZStack(alignment: .top) {
            Color.black.opacity(0.85)
            VStack {
                SnapLayoutPickerView(
                    templates: LayoutTemplate.standardTemplates,
                    hoveredSlotId: "threeCol-center"
                )
                Spacer()
            }
            .padding(.top, 12)
        }
        .frame(width: 540, height: 200)

        if let threeColData = renderViewToPNG(view: pickerThreeColHoveredView, size: CGSize(width: 540, height: 200)) {
            let url = outputDir.appendingPathComponent("03_layout_picker_three_col_hover.png")
            try threeColData.write(to: url)
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
