import AppKit
import Foundation
import SwiftUI

/// Protocol governing presentation of the FlowSnap Settings window.
@MainActor
public protocol SettingsWindowPresenting: AnyObject, Sendable {
    /// Presents and focuses the settings window, bringing FlowSnap to the foreground.
    func showSettingsWindow()
}

/// Floating panel subclass ensuring the settings panel can become key and accept user interactions.
final class SettingsFloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Controller responsible for managing the lifecycle and presentation of the Settings window.
///
/// Ensures the window is properly brought to front and FlowSnap is activated via `NSApp.activate(ignoringOtherApps: true)`
/// so that settings presentation works reliably in accessory / menu bar extra mode.
@MainActor
public final class SettingsWindowController: NSObject, NSWindowDelegate, SettingsWindowPresenting {

    // MARK: - Properties

    public private(set) var window: NSWindow?
    public let preferencesStore: PreferencesStore
    public let workspaceManager: WorkspaceManager?

    // MARK: - Initialization

    public init(preferencesStore: PreferencesStore, workspaceManager: WorkspaceManager? = nil) {
        self.preferencesStore = preferencesStore
        self.workspaceManager = workspaceManager
        super.init()
    }

    // MARK: - SettingsWindowPresenting

    /// Presents and focuses the settings window as a floating overlay above other windows.
    public func showSettingsWindow() {
        if let existingWindow = window {
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            existingWindow.level = .floating
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(store: preferencesStore, workspaceManager: workspaceManager)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = SettingsFloatingPanel(contentViewController: hostingController)
        newWindow.title = "FlowSnap Settings"
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .nonactivatingPanel]
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .floating
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.isFloatingPanel = true
        newWindow.becomesKeyOnlyIfNeeded = false
        newWindow.delegate = self
        newWindow.center()

        self.window = newWindow
        newWindow.orderFrontRegardless()
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - NSWindowDelegate

    public func windowWillClose(_ notification: Notification) {
        // Window remains retained with isReleasedWhenClosed = false so it can be re-shown quickly.
    }
}
