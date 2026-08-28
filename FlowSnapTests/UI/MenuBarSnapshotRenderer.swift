import AppKit
import Foundation
import SwiftUI
import Testing
@testable import FlowSnap

@MainActor
struct MenuBarSnapshotRenderer {

    @Test func renderMenuBarGuideScreenshots() async throws {
        let outputDir = URL(fileURLWithPath: "/Users/vutuanhau/Documents/PROJECT/FlowSnap/docs/user-guides/images/menubar-quick-controls")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let primary = Display(
            id: 1,
            frame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
            scaleFactor: 2.0,
            isPrimary: true
        )
        let displayManager = DisplayManager(displayProvider: { [primary] })
        let windowRegistry = WindowRegistry()
        let snapEngine = SnapEngine(windowRegistry: windowRegistry, displayManager: displayManager)

        // 1. Render Trusted Menu (Ready State)
        let trustedService = MockAccessibilityService(isTrusted: true)
        let windowManagerTrusted = MockWindowManaging()
        let dispatcherTrusted = CommandDispatcher(
            windowManager: windowManagerTrusted,
            snapEngine: snapEngine,
            displayManager: displayManager
        )
        let trustedVM = MenuBarViewModel(
            accessibilityService: trustedService,
            commandDispatcher: dispatcherTrusted,
            windowManager: windowManagerTrusted
        )
        let trustedView = MenuBarView(viewModel: trustedVM)
            .background(Color(nsColor: .windowBackgroundColor))
            .padding(4)

        if let trustedData = renderViewToPNG(view: trustedView, size: CGSize(width: 290, height: 420)) {
            let trustedURL = outputDir.appendingPathComponent("01_menubar_quick_snap_menu.png")
            try trustedData.write(to: trustedURL)
        }

        // 2. Render Untrusted Menu (Permission Warning State)
        let untrustedService = MockAccessibilityService(isTrusted: false)
        let windowManagerUntrusted = MockWindowManaging()
        let dispatcherUntrusted = CommandDispatcher(
            windowManager: windowManagerUntrusted,
            snapEngine: snapEngine,
            displayManager: displayManager
        )
        let untrustedVM = MenuBarViewModel(
            accessibilityService: untrustedService,
            commandDispatcher: dispatcherUntrusted,
            windowManager: windowManagerUntrusted
        )
        let untrustedView = MenuBarView(viewModel: untrustedVM)
            .background(Color(nsColor: .windowBackgroundColor))
            .padding(4)

        if let untrustedData = renderViewToPNG(view: untrustedView, size: CGSize(width: 290, height: 490)) {
            let untrustedURL = outputDir.appendingPathComponent("02_menubar_permission_warning.png")
            try untrustedData.write(to: untrustedURL)
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
