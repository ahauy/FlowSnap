import AppKit
import Foundation
import SwiftUI

/// Protocol governing presentation of the FlowSnap Settings window.
@MainActor
public protocol SettingsWindowPresenting: AnyObject, Sendable {
    /// Presents and focuses the settings window, bringing FlowSnap to the foreground.
    func showSettingsWindow()
}

/// Controller responsible for managing the lifecycle and presentation of the Settings window.
///
/// Ensures the window is properly brought to front and FlowSnap is activated via `NSApp.activate(ignoringOtherApps: true)`
/// so that settings presentation works reliably in accessory / menu bar extra mode.
@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate, SettingsWindowPresenting {

    // MARK: - Properties

    public private(set) var window: NSWindow?
    private let preferencesStore: PreferencesStore

    // MARK: - Initialization

    public init(preferencesStore: PreferencesStore) {
        self.preferencesStore = preferencesStore
        super.init()
    }

    // MARK: - SettingsWindowPresenting

    /// Presents and focuses the settings window, activating the application.
    public func showSettingsWindow() {
        if let existingWindow = window {
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(store: preferencesStore)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "FlowSnap Settings"
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        newWindow.center()

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    public func windowWillClose(_ notification: Notification) {
        // Window remains retained with isReleasedWhenClosed = false so it can be re-shown quickly.
    }
}
