import AppKit
import Foundation
import SwiftUI
import Testing
@testable import FlowSnap

@MainActor
struct SnapPreviewSnapshotRenderer {

    @Test func renderSnapPreviewScreenshots() async throws {
        let outputDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/drag-to-snap-preview")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        // 1. Render Left Half Preview
        let leftPreviewView = ZStack {
            Color.black.opacity(0.85) // Desktop canvas background mockup
            HStack(spacing: 0) {
                SnapPreviewView()
                    .frame(width: 240, height: 300)
                Spacer()
            }
            .padding(10)
        }
        .frame(width: 500, height: 320)

        if let leftData = renderViewToPNG(view: leftPreviewView, size: CGSize(width: 500, height: 320)) {
            let leftURL = outputDir.appendingPathComponent("01_drag_to_snap_left_half.png")
            try leftData.write(to: leftURL)
        }

        // 2. Render Maximize / Top Edge Preview
        let maxPreviewView = ZStack {
            Color.black.opacity(0.85)
            SnapPreviewView()
                .frame(width: 480, height: 300)
                .padding(10)
        }
        .frame(width: 500, height: 320)

        if let maxData = renderViewToPNG(view: maxPreviewView, size: CGSize(width: 500, height: 320)) {
            let maxURL = outputDir.appendingPathComponent("02_drag_to_snap_maximize.png")
            try maxData.write(to: maxURL)
        }

        // 3. Render Top-Right Corner Preview
        let cornerPreviewView = ZStack {
            Color.black.opacity(0.85)
            VStack {
                HStack {
                    Spacer()
                    SnapPreviewView()
                        .frame(width: 240, height: 150)
                }
                Spacer()
            }
            .padding(10)
        }
        .frame(width: 500, height: 320)

        if let cornerData = renderViewToPNG(view: cornerPreviewView, size: CGSize(width: 500, height: 320)) {
            let cornerURL = outputDir.appendingPathComponent("03_drag_to_snap_top_right.png")
            try cornerData.write(to: cornerURL)
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
